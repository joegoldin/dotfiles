{ pkgs }:
{
  name = "watchyt";
  desc = "Download a video, extract frames, pull a timestamped transcript";
  runtimeInputs = [
    pkgs.yt-dlp
    pkgs.ffmpeg
    pkgs.audiomemo
  ];
  params = [
    {
      name = "source";
      desc = "Video URL (yt-dlp-supported) or local file path";
    }
  ];
  flags = [
    {
      name = "--start";
      arg = "T";
      desc = "Window start (SS, MM:SS, or HH:MM:SS)";
    }
    {
      name = "--end";
      arg = "T";
      desc = "Window end (SS, MM:SS, or HH:MM:SS)";
    }
    {
      name = "--max-frames";
      arg = "N";
      desc = "Hard cap on extracted frames";
      default = "100";
    }
    {
      name = "--resolution";
      arg = "W";
      desc = "Frame width in pixels (height auto)";
      default = "512";
    }
    {
      name = "--fps";
      arg = "F";
      desc = "Override auto-fps (still capped at 2 fps)";
    }
    {
      name = "--out-dir";
      arg = "DIR";
      desc = "Working directory (default: auto-generated tmp dir)";
    }
    {
      name = "--no-transcript";
      desc = "Skip transcript pipeline; emit frames only";
      bool = true;
    }
    {
      name = "--backend";
      arg = "B";
      desc = "Forwarded to audiomemo transcribe -b (e.g. whisper-cpp, deepgram, openai)";
    }
  ];
  examples = [
    {
      cmd = "watchyt https://youtu.be/abc";
      desc = "Default scan of a YouTube video";
    }
    {
      cmd = "watchyt video.mp4 --start 50 --end 60";
      desc = "Focused scan of seconds 50–60 of a local file";
    }
    {
      cmd = "watchyt \"$URL\" --start 2:15 --end 2:45 --resolution 1024";
      desc = "Window 2:15–2:45 with high-res frames for on-screen text";
    }
    {
      cmd = "watchyt clip.mov --backend whisper-cpp";
      desc = "Force fully-local transcription via whisper-cpp";
    }
  ];
  python = ''
    import re
    import shutil
    import subprocess
    import sys
    import tempfile
    from pathlib import Path
    from urllib.parse import urlparse


    def is_url(s):
        p = urlparse(s)
        return p.scheme in ("http", "https") and bool(p.netloc)


    def parse_time(s):
        if s is None or s == "":
            return None
        parts = s.split(":")
        try:
            parts = [float(p) for p in parts]
        except ValueError:
            die(f"invalid time spec: {s!r}")
        if len(parts) == 1:
            return parts[0]
        if len(parts) == 2:
            return parts[0] * 60 + parts[1]
        if len(parts) == 3:
            return parts[0] * 3600 + parts[1] * 60 + parts[2]
        die(f"invalid time spec: {s!r}")


    def fmt_time(secs):
        secs = max(0, int(secs))
        h = secs // 3600
        m = (secs % 3600) // 60
        s = secs % 60
        if h:
            return f"{h:02d}:{m:02d}:{s:02d}"
        return f"{m:02d}:{s:02d}"


    def run(cmd, **kwargs):
        debug("$ " + " ".join(str(c) for c in cmd))
        return subprocess.run(cmd, **kwargs)


    def ffprobe_duration(path):
        r = run(
            [
                "ffprobe", "-v", "error",
                "-show_entries", "format=duration",
                "-of", "default=nw=1:nk=1",
                str(path),
            ],
            capture_output=True, text=True, check=False,
        )
        if r.returncode != 0 or not r.stdout.strip():
            die(f"ffprobe failed for {path}: {r.stderr.strip() or 'no output'}")
        try:
            return float(r.stdout.strip())
        except ValueError:
            die(f"ffprobe returned non-numeric duration: {r.stdout!r}")


    def compute_fps(duration, max_frames, focused):
        if focused:
            if duration <= 5:
                target = max(1, min(10, int(duration * 2)))
            elif duration <= 15:
                target = min(30, int(duration * 2))
            elif duration <= 30:
                target = min(60, int(duration * 2))
            elif duration <= 60:
                target = min(80, max(1, int(duration * 1.3)))
            else:
                target = min(100, max(1, int(duration * 0.6)))
        else:
            if duration <= 30:
                target = max(1, min(30, int(duration * 1.5)))
            elif duration <= 60:
                target = 40
            elif duration <= 180:
                target = 60
            elif duration <= 600:
                target = 80
            else:
                target = 100
        target = max(1, min(target, max_frames))
        fps = min(2.0, target / duration)
        # If the cap clamped fps, recompute target to stay consistent
        target = max(1, min(target, int(round(fps * duration))))
        return fps, target


    def download(url, out_dir):
        r = run(
            [
                "yt-dlp", "--no-playlist",
                "--print", "after_move:filepath",
                "-o", f"{out_dir}/%(id)s.%(ext)s",
                url,
            ],
            capture_output=True, text=True, check=False,
        )
        if r.returncode != 0:
            die(f"yt-dlp download failed: {r.stderr.strip()}")
        paths = [p for p in r.stdout.strip().splitlines() if p]
        if not paths:
            die("yt-dlp produced no output filename")
        path = Path(paths[-1])
        if not path.exists():
            die(f"yt-dlp reported {path} but it does not exist")
        return path


    def fetch_vtt(url, out_dir):
        for arg in ("--write-sub", "--write-auto-sub"):
            r = run(
                [
                    "yt-dlp", "--skip-download", arg,
                    "--sub-lang", "en", "--sub-format", "vtt",
                    "-o", f"{out_dir}/%(id)s.%(ext)s",
                    url,
                ],
                capture_output=True, text=True, check=False,
            )
            if r.returncode != 0:
                continue
            for vtt in sorted(Path(out_dir).glob("*.vtt")):
                content = vtt.read_text(encoding="utf-8", errors="replace")
                if content.strip():
                    return content
        return None


    def whisper_vtt(media_path, backend):
        ffmpeg_proc = subprocess.Popen(
            [
                "ffmpeg", "-loglevel", "error",
                "-i", str(media_path),
                "-vn", "-ac", "1", "-ar", "16000",
                "-f", "wav", "-",
            ],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        cmd = ["audiomemo", "transcribe", "-f", "vtt"]
        if backend:
            cmd += ["-b", backend]
        cmd += ["-"]
        debug("$ " + " ".join(cmd) + " (audio piped from ffmpeg)")
        am = subprocess.run(
            cmd, stdin=ffmpeg_proc.stdout,
            capture_output=True, text=True, check=False,
        )
        ffmpeg_proc.stdout.close()
        ff_err = ffmpeg_proc.stderr.read().decode("utf-8", errors="replace")
        ffmpeg_proc.wait()
        if am.returncode != 0:
            err = am.stderr.strip() or ff_err.strip() or f"audiomemo exit {am.returncode}"
            return None, err
        if not am.stdout.strip():
            return None, "audiomemo returned empty transcript"
        return am.stdout, None


    VTT_TS = re.compile(
        r"^\s*((?:\d+:)?\d+:\d+(?:\.\d+)?)\s+-->\s+((?:\d+:)?\d+:\d+(?:\.\d+)?)"
    )


    def vtt_seconds(ts):
        parts = ts.split(":")
        parts = [float(p) for p in parts]
        if len(parts) == 2:
            return parts[0] * 60 + parts[1]
        return parts[0] * 3600 + parts[1] * 60 + parts[2]


    def filter_vtt(vtt, window_start, window_end):
        if window_start is None and window_end is None:
            return vtt
        ws = window_start if window_start is not None else 0.0
        we = window_end if window_end is not None else float("inf")

        out = []
        # Preserve the WEBVTT header block (everything up through the first blank line)
        lines = vtt.splitlines()
        i = 0
        while i < len(lines):
            out.append(lines[i])
            if lines[i].strip() == "":
                i += 1
                break
            i += 1

        # Walk cues
        while i < len(lines):
            # Optional cue id line
            cue = []
            if lines[i].strip() and "-->" not in lines[i]:
                cue.append(lines[i])
                i += 1
            if i >= len(lines):
                break
            m = VTT_TS.match(lines[i])
            if not m:
                # Stray blank or unknown line; skip
                i += 1
                continue
            cs = vtt_seconds(m.group(1))
            ce = vtt_seconds(m.group(2))
            cue.append(lines[i])
            i += 1
            while i < len(lines) and lines[i].strip() != "":
                cue.append(lines[i])
                i += 1
            # Skip blank between cues
            if i < len(lines) and lines[i].strip() == "":
                i += 1
            if cs <= we and ce >= ws:
                out.extend(cue)
                out.append("")
        return "\n".join(out).rstrip() + "\n"


    # ── Main ──────────────────────────────────────────────────────────────
    source = _args.source
    start_s = parse_time(_args.start)
    end_s = parse_time(_args.end)
    focused = (start_s is not None) or (end_s is not None)

    try:
        max_frames = int(_args.max_frames)
    except (TypeError, ValueError):
        die(f"--max-frames must be an integer, got {_args.max_frames!r}")
    try:
        resolution = int(_args.resolution)
    except (TypeError, ValueError):
        die(f"--resolution must be an integer, got {_args.resolution!r}")
    override_fps = None
    if _args.fps:
        try:
            override_fps = float(_args.fps)
        except ValueError:
            die(f"--fps must be a number, got {_args.fps!r}")

    no_transcript = bool(_args.no_transcript)
    backend = _args.backend or None

    # Working dir
    if _args.out_dir:
        out_dir = Path(_args.out_dir).expanduser()
        out_dir.mkdir(parents=True, exist_ok=True)
    else:
        out_dir = Path(tempfile.mkdtemp(prefix="watchyt-"))

    # Resolve source
    if is_url(source):
        debug(f"downloading {source} to {out_dir}")
        media_path = download(source, out_dir)
        source_url = source
    else:
        media_path = Path(source).expanduser()
        if not media_path.exists():
            die(f"file not found: {media_path}")
        media_path = media_path.resolve()
        source_url = None

    # Probe duration
    total_duration = ffprobe_duration(media_path)
    window_start = start_s if start_s is not None else 0.0
    window_end = end_s if end_s is not None else total_duration
    if window_end > total_duration:
        window_end = total_duration
    windowed_duration = window_end - window_start
    if windowed_duration <= 0:
        die(f"empty window: start={window_start} end={window_end}")

    # Compute fps + target frame count
    if override_fps is not None:
        fps = min(override_fps, 2.0)
        target = max(1, min(int(round(fps * windowed_duration)), max_frames))
    else:
        fps, target = compute_fps(windowed_duration, max_frames, focused)

    # Long-video warning (only for unfocused full-video scans)
    if not focused and total_duration > 600:
        print(
            f"warning: {fmt_time(total_duration)} video — sparse scan ({target} frames). "
            "Re-run with --start/--end for denser coverage of a section.",
            file=sys.stderr,
        )

    # Extract frames
    frames_dir = out_dir / "frames"
    frames_dir.mkdir(exist_ok=True)
    ffmpeg_cmd = ["ffmpeg", "-loglevel", "error", "-y"]
    if start_s is not None:
        ffmpeg_cmd += ["-ss", str(start_s)]
    if end_s is not None:
        ffmpeg_cmd += ["-to", str(end_s)]
    ffmpeg_cmd += [
        "-i", str(media_path),
        "-vf", f"fps={fps:.4f},scale={resolution}:-2",
        "-q:v", "4",
        str(frames_dir / "frame_%04d.jpg"),
    ]
    r = run(ffmpeg_cmd, capture_output=True, text=True, check=False)
    if r.returncode != 0:
        die(f"ffmpeg frame extraction failed: {r.stderr.strip()}")

    # Rename frames to embed absolute video timestamps
    extracted = sorted(frames_dir.glob("frame_*.jpg"))
    renamed = []
    for i, src in enumerate(extracted):
        abs_ts = window_start + (i / fps if fps > 0 else 0)
        label = fmt_time(abs_ts).replace(":", "-")
        new_name = frames_dir / f"frame_{i + 1:04d}_t={label}.jpg"
        if new_name != src:
            src.rename(new_name)
        renamed.append((abs_ts, new_name))

    # Transcript
    vtt_content = None
    transcript_source = "none"
    transcript_error = None
    if not no_transcript:
        if source_url:
            debug("attempting captions via yt-dlp")
            vtt_content = fetch_vtt(source_url, out_dir)
            if vtt_content:
                transcript_source = "captions"
        if not vtt_content:
            debug(f"falling back to audiomemo transcribe (backend={backend or 'default'})")
            vtt_content, transcript_error = whisper_vtt(media_path, backend)
            if vtt_content:
                transcript_source = f"audiomemo:{backend or 'default'}"
        if vtt_content and (start_s is not None or end_s is not None):
            vtt_content = filter_vtt(vtt_content, start_s, end_s)

    # Report
    print("# watchyt report")
    print(f"source: {source}")
    print(f"working_dir: {out_dir}")
    print(f"duration: {fmt_time(total_duration)}")
    if focused:
        print(f"window: {fmt_time(window_start)} → {fmt_time(window_end)}")
    print(f"frames: {len(renamed)} @ {fps:.2f} fps")
    print(f"transcript: {transcript_source}")
    if transcript_error:
        print(f"transcript_error: {transcript_error}")
    print()
    print("## frames")
    for abs_ts, p in renamed:
        print(f"{p}  # t={fmt_time(abs_ts)}")
    print()
    print("## transcript")
    if vtt_content:
        print(vtt_content.rstrip())
    else:
        print("(no transcript available)")
  '';
}

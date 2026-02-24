{
  name = "getsubs";
  desc = "Extract subtitles from a YouTube video";
  usage = "getsubs URL";
  type = "python-argparse";
  body = ''
    import argparse
    import os
    import re
    import subprocess
    import sys
    import tempfile
    from pathlib import Path


    def get_vtt(url: str, arg: str) -> str | None:
        """Download VTT subtitles using yt-dlp."""
        with tempfile.TemporaryDirectory() as temp_dir:
            try:
                result = subprocess.run(
                    [
                        'yt-dlp',
                        '--skip-download',
                        arg,
                        '--sub-lang', 'en',
                        '--sub-format', 'vtt',
                        '-o', os.path.join(temp_dir, '%(id)s.%(ext)s'),
                        url
                    ],
                    capture_output=True,
                    text=True,
                    check=False
                )

                if result.returncode != 0:
                    return None

                # Find the VTT file
                for file in Path(temp_dir).iterdir():
                    if file.suffix == '.vtt':
                        return file.read_text(encoding='utf-8')

                return None

            except FileNotFoundError:
                print("Error: yt-dlp not found. Install with: pip install yt-dlp", file=sys.stderr)
                sys.exit(1)
            except Exception as e:
                print(f"Error downloading subtitles: {e}", file=sys.stderr)
                return None


    def clean_text(text: str) -> str:
        """Clean subtitle text by removing HTML tags and extra whitespace."""
        text = re.sub(r'<[^>]+>', "", text)
        text = ' '.join(text.split())
        text = text.replace(' ;', "").replace(';', "")
        return text.strip()


    def parse_vtt(vtt_content: str) -> list[str]:
        """Parse VTT content manually without external dependencies."""
        lines = []
        current_cue_lines = []
        in_cue = False

        for line in vtt_content.split('\n'):
            line = line.strip()

            if line.startswith('WEBVTT') or line.startswith('Kind:') or line.startswith('Language:'):
                continue

            if line.startswith('NOTE'):
                continue

            if '-->' in line:
                if current_cue_lines:
                    combined = ' '.join(current_cue_lines)
                    cleaned = clean_text(combined)
                    if cleaned:
                        lines.append(cleaned)
                    current_cue_lines = []
                in_cue = True
                continue

            if not line:
                in_cue = False
                continue

            if line.isdigit():
                continue

            if in_cue:
                current_cue_lines.append(line)

        if current_cue_lines:
            combined = ' '.join(current_cue_lines)
            cleaned = clean_text(combined)
            if cleaned:
                lines.append(cleaned)

        return lines


    def extract_new_words(lines: list[str]) -> list[str]:
        """Extract only the new words from YouTube's overlapping subtitles."""
        if not lines:
            return []

        result = []
        seen_text = ""

        for line in lines:
            if line == seen_text:
                continue

            if seen_text and line.startswith(seen_text):
                new_part = line[len(seen_text):].strip()
                if new_part:
                    result.append(new_part)
                seen_text = line
            elif seen_text and seen_text.endswith(line):
                continue
            else:
                words_current = line.split()
                words_seen = seen_text.split()

                overlap_found = False
                for i in range(1, min(len(words_seen), len(words_current)) + 1):
                    if words_seen[-i:] == words_current[:i]:
                        new_words = words_current[i:]
                        if new_words:
                            result.append(' '.join(new_words))
                            overlap_found = True
                            seen_text = line
                            break

                if not overlap_found:
                    result.append(line)
                    seen_text = line

        return result


    def vtt_lines(vtt_content: str) -> list[str]:
        """Convert VTT content to a list of unique subtitle lines."""
        raw_lines = parse_vtt(vtt_content)
        return extract_new_words(raw_lines)


    def main():
        parser = argparse.ArgumentParser(description='Download and extract subtitles from YouTube videos')
        parser.add_argument('url', help='YouTube video URL')
        args = parser.parse_args()

        vtt_content = get_vtt(args.url, '--write-sub')

        if not vtt_content:
            vtt_content = get_vtt(args.url, '--write-auto-sub')

        if not vtt_content:
            print("Error: no subs found", file=sys.stderr)
            sys.exit(1)

        lines = vtt_lines(vtt_content)
        for line in lines:
            print(line)


    if __name__ == '__main__':
        main()
  '';
}

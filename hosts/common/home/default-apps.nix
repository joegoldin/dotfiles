{ ... }:
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      let
        browser = "firefox.desktop";
        editor = "dev.zed.Zed-Nightly.desktop";
        fileManager = "org.kde.dolphin.desktop";
        imageViewer = "org.kde.gwenview.desktop";
        videoPlayer = "mpv.desktop";
        pdfViewer = "firefox.desktop";
        archiveManager = "org.kde.ark.desktop";
      in
      {
        # Browser
        "x-scheme-handler/http" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/about" = browser;
        "x-scheme-handler/unknown" = browser;
        "text/html" = browser;
        "application/xhtml+xml" = browser;

        # Editor - code and text files
        "text/plain" = editor;
        "text/markdown" = editor;
        "text/x-csrc" = editor;
        "text/x-chdr" = editor;
        "text/x-c++src" = editor;
        "text/x-c++hdr" = editor;
        "text/x-java" = editor;
        "text/x-python" = editor;
        "text/x-script.python" = editor;
        "text/x-ruby" = editor;
        "text/x-shellscript" = editor;
        "text/x-sql" = editor;
        "text/css" = editor;
        "text/xml" = editor;
        "application/json" = editor;
        "application/x-yaml" = editor;
        "application/toml" = editor;
        "application/xml" = editor;
        "application/javascript" = editor;
        "application/x-shellscript" = editor;

        # Images
        "image/png" = imageViewer;
        "image/jpeg" = imageViewer;
        "image/gif" = imageViewer;
        "image/webp" = imageViewer;
        "image/svg+xml" = imageViewer;
        "image/bmp" = imageViewer;
        "image/tiff" = imageViewer;

        # Video
        "video/mp4" = videoPlayer;
        "video/x-matroska" = videoPlayer;
        "video/webm" = videoPlayer;
        "video/x-msvideo" = videoPlayer;
        "video/quicktime" = videoPlayer;

        # Audio
        "audio/mpeg" = videoPlayer;
        "audio/flac" = videoPlayer;
        "audio/ogg" = videoPlayer;
        "audio/wav" = videoPlayer;
        "audio/x-wav" = videoPlayer;

        # PDF
        "application/pdf" = pdfViewer;

        # Archives
        "application/zip" = archiveManager;
        "application/x-tar" = archiveManager;
        "application/gzip" = archiveManager;
        "application/x-7z-compressed" = archiveManager;
        "application/x-rar-compressed" = archiveManager;
        "application/x-bzip2" = archiveManager;
        "application/zstd" = archiveManager;

        # File manager
        "inode/directory" = fileManager;
      };

    associations.removed = {
      # Prevent Elisa from claiming audio/video types
      "audio/mpeg" = "org.kde.elisa.desktop";
      "audio/flac" = "org.kde.elisa.desktop";
      "audio/ogg" = "org.kde.elisa.desktop";
      "audio/wav" = "org.kde.elisa.desktop";
      "audio/x-wav" = "org.kde.elisa.desktop";
      "audio/x-vorbis+ogg" = "org.kde.elisa.desktop";
      "audio/x-flac" = "org.kde.elisa.desktop";
      "audio/mp4" = "org.kde.elisa.desktop";
      "audio/aac" = "org.kde.elisa.desktop";
      "audio/x-ms-wma" = "org.kde.elisa.desktop";
      "audio/x-aiff" = "org.kde.elisa.desktop";
      "application/ogg" = "org.kde.elisa.desktop";

      # Prevent Kate from claiming text/code types
      "text/plain" = "org.kde.kate.desktop";
      "text/markdown" = "org.kde.kate.desktop";
      "text/x-csrc" = "org.kde.kate.desktop";
      "text/x-c++src" = "org.kde.kate.desktop";
      "text/x-python" = "org.kde.kate.desktop";
      "text/x-java" = "org.kde.kate.desktop";
      "text/x-shellscript" = "org.kde.kate.desktop";
      "text/css" = "org.kde.kate.desktop";
      "text/xml" = "org.kde.kate.desktop";
      "application/json" = "org.kde.kate.desktop";
      "application/xml" = "org.kde.kate.desktop";
      "application/javascript" = "org.kde.kate.desktop";
      "application/x-shellscript" = "org.kde.kate.desktop";
    };
  };
}

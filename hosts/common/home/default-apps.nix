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
        videoPlayer = "vlc.desktop";
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
  };
}

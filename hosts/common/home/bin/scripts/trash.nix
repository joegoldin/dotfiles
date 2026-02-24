{
  name = "trash";
  desc = "Move files to trash";
  usage = "trash FILE...";
  type = "fish";
  body = ''
    if test (uname) = Darwin
        for arg in $argv
            set file (realpath $arg)
            /usr/bin/osascript -e "tell application \"Finder\" to delete POSIX file \"$file\"" >/dev/null
        end
    else
        gio trash $argv
    end
  '';
}

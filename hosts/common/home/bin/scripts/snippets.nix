{
  name = "snippets";
  desc = "Print a snippet by name";
  usage = "snippets NAME";
  type = "fish";
  body = ''
    if test (count $argv) -ne 1
        echo 'must pass exactly 1 argument' >&2
        exit 1
    end

    set snippets_dir "$HOME/dotfiles/snippets"
    set path "$snippets_dir/$argv[1]"

    if not cat $path 2>/dev/null
        echo "no snippet found at $path" >&2
        exit 1
    end
  '';
}

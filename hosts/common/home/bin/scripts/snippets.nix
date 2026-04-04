{
  name = "snippets";
  desc = "Print a snippet by name";
  examples = [
    { cmd = "snippets gitignore"; desc = "Print gitignore snippet"; }
    { cmd = "snippets flake > flake.nix"; desc = "Write snippet to file"; }
  ];
  params = [
    {
      name = "NAME";
      desc = "Snippet name";
      completions = "ls $HOME/dotfiles/snippets/ 2>/dev/null";
    }
  ];
  fish = ''
    set snippets_dir "$HOME/dotfiles/snippets"
    set path "$snippets_dir/$argv[1]"

    if not cat $path 2>/dev/null
        echo "no snippet found at $path" >&2
        exit 1
    end
  '';
}

{ pkgs, ... }: 

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
    '';
    
    functions = {
      # Disable greeting
      fish_greeting = "echo '🐟'";
    };
  };

  home.shellAliases = {
    k = "kubectl";

    urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
    urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";
  };
}

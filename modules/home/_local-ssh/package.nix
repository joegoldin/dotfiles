{ pkgs }:
let
  askpass = pkgs.writeShellScript "ssh-login-askpass" ''
    # ssh-add otherwise retries forever with the same saved, incorrect value.
    case "$1" in
      "Enter passphrase for "*)
        exec ${pkgs.coreutils}/bin/cat -- "$SSH_KEY_PASSPHRASE_FILE"
        ;;
      *) exit 1 ;;
    esac
  '';
in
pkgs.writeShellApplication {
  name = "ssh-login-load-key";
  runtimeInputs = [
    pkgs.openssh
    pkgs.coreutils
  ];
  text = builtins.replaceStrings [ "@askpass@" ] [ (toString askpass) ] (
    builtins.readFile ./load-key.sh
  );
}

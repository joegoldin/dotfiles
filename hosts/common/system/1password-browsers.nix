_: {
  # Allow non-officially-trusted browsers (Zen) to connect to the 1Password
  # desktop app for native messaging / biometric unlock.
  # https://docs.zen-browser.app/guides/1password
  #
  # The file and its parent dir must be root-owned and not writable by others,
  # which environment.etc guarantees; 0755 matches the documented chmod. Both
  # binaries live in the root-owned /nix/store, satisfying the ownership
  # requirement. The 1Password app maintains the native-messaging manifest in
  # ~/.mozilla/native-messaging-hosts at runtime; Zen finds it through the
  # symlink set up in hosts/common/home/zen (it reads its own user-data root,
  # not the stock Firefox vendor dir).
  environment.etc."1password/custom_allowed_browsers" = {
    mode = "0755";
    user = "root";
    group = "root";
    # Cover the launcher and the inner wrapped binary, since 1Password matches
    # the connecting process name.
    text = ''
      zen
      .zen-wrapped
      zen-bin
    '';
  };
}

{ ... }:
{
  # Allow non-officially-trusted browsers (Zen) to connect to the 1Password
  # desktop app for native messaging / biometric unlock.
  # https://docs.zen-browser.app/guides/1password
  #
  # The file and its parent dir must be root-owned and not writable by others,
  # which environment.etc guarantees. The 1Password app writes the actual
  # native-messaging manifest into the browser profile dir at runtime once the
  # browser process is allow-listed here.
  environment.etc."1password/custom_allowed_browsers" = {
    mode = "0644";
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

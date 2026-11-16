{
  den.aspects.elphael.nixos = {
    # Random-encrypted swap cannot restore a hibernation image after reboot.
    # Keep suspend-to-RAM available, but reject every mode that writes an image.
    systemd.sleep.settings.Sleep = {
      AllowHibernation = false;
      AllowHybridSleep = false;
      AllowSuspendThenHibernate = false;
    };
  };
}

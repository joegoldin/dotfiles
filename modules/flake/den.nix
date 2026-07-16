# den (github:denful/den): the aspect engine on top of the dendritic
# pattern. Every .nix file under modules/ is a flake-parts module imported
# automatically by import-tree (paths containing "/_" are skipped); this one
# wires den itself plus repo-wide entity defaults.
{
  inputs,
  lib,
  den,
  ...
}:
{
  imports = [ inputs.den.flakeModule ];

  # Every user entity gets a home-manager environment.
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # Every host entity gets:
  #  - networking.hostName from its hostName option (hostname battery)
  #  - the host aspect tree's homeManager blocks projected onto its users
  #    (host-aspects battery); this is how hosts select home features
  #  - the shared home-manager plumbing (useGlobalPkgs/backupCommand)
  den.schema.host.includes = [
    den.batteries.hostname
    den.batteries.host-aspects
    den.aspects.hm-settings
  ];

  # Default stateVersions; hosts that diverge override in their own aspect
  # (dectus mkForces 25.11, darwin uses its own integer scheme).
  den.default = {
    nixos = {
      system.stateVersion = lib.mkDefault "24.11";
      imports = [
        # `unlock` alias for the initrd LUKS-unlock command (no-op off the encrypted
        # initrd-SSH hosts — see the module for details).
        ./_initrd-unlock.nix
        # fail2ban ignorecommand: never ban an IP with a recent successful SSH
        # key login (no-op where fail2ban is off — see the module for details).
        ./_fail2ban-key-exempt.nix
        # btop + gping (+ iputils) on every box, system-wide (see the module).
        ./_core-packages.nix
        # Prebuilt nix-index database on every box: wrapped nix-locate backs the
        # command-not-found handler, and comma (`,`) below rides the same db —
        # nothing to generate in ~/.cache/nix-index. torrent wires the darwin
        # flavor of this module itself.
        inputs.nix-index-database.nixosModules.default
      ];
      programs.nix-index-database.comma.enable = true;
    };
    homeManager.home.stateVersion = lib.mkDefault "24.11";
  };
}

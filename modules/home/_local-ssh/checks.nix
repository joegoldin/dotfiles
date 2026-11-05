{
  inputs,
  pkgs,
  lib,
}:
let
  aspect = (import ../local-ssh.nix { inherit inputs; }).den.aspects.local-ssh;
  home =
    system:
    (inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs { inherit system; };
      modules = [
        aspect.homeManager
        {
          home = {
            username = "joe";
            homeDirectory = if lib.hasSuffix "-darwin" system then "/Users/joe" else "/home/joe";
            stateVersion = "26.05";
          };
        }
      ];
    }).config;
  linux = home "x86_64-linux";
  mac = home "aarch64-darwin";
  agent = linux.systemd.user.services.ssh-agent;
  login = linux.systemd.user.services.ssh-login-key;
  macLogin = mac.launchd.agents.local-ssh-environment.config;
  loader = import ./package.nix { inherit pkgs; };
in
assert linux.services.ssh-agent.defaultMaximumIdentityLifetime == null;
assert mac.services.ssh-agent.defaultMaximumIdentityLifetime == null;
assert linux.programs.ssh.settings."*".data.AddKeysToAgent == "no";
assert mac.programs.ssh.settings."*".data.AddKeysToAgent == "no";
assert agent.Install.WantedBy == [ "graphical-session.target" ];
assert agent.Unit.PartOf == [ "graphical-session.target" ];
assert !(lib.hasInfix " -t " (builtins.head agent.Service.ExecStart));
assert login.Unit.Requires == [ "ssh-agent.service" ];
assert login.Unit.After == [ "ssh-agent.service" ];
assert login.Unit.PartOf == [ "graphical-session.target" ];
assert login.Install.WantedBy == [ "graphical-session.target" ];
assert login.Service.Type == "oneshot" && login.Service.RemainAfterExit;
assert !(login.Service ? Restart);
assert macLogin.RunAtLoad && macLogin.KeepAlive == null;
assert lib.hasInfix "ssh-login-load-key" (lib.last macLogin.ProgramArguments);
assert lib.hasInfix "launchctl setenv SSH_AUTH_SOCK" (lib.last macLogin.ProgramArguments);
pkgs.runCommand "local-ssh-tests"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.openssh
      pkgs.coreutils
    ];
    SSH_LOGIN_LOADER = lib.getExe loader;
    # Keep the evaluated arguments, but use a native executable on macOS too.
    SSH_LOGIN_AGENT_COMMAND =
      builtins.replaceStrings
        [ (lib.getExe' linux.services.ssh-agent.package "ssh-agent") ]
        [ (lib.getExe' pkgs.openssh "ssh-agent") ]
        (builtins.head agent.Service.ExecStart);
  }
  ''
    export PYTHONDONTWRITEBYTECODE=1
    python3 -m unittest discover -s ${./.} -p 'test_*.py' -v
    touch "$out"
  ''

# GitHub Actions self-hosted runner for joegoldin/zen-browser-desktop — the
# multi-hour zen (Firefox fork) release build. The workflow is Ubuntu-shaped
# (sudo apt-get, rustup, mach bootstrap), so it can't run on a bare NixOS
# runner; instead GitHub's official actions/runner runs inside an Ubuntu
# container with hard docker ceilings — 18 CPUs / 64 GiB — that reserve
# nothing while idle. Ephemeral: the runner deregisters and the container
# exits after every job; systemd restarts it and it re-registers with a fresh
# registration token minted from the PAT. Only the sccache volume persists.
# Design: docs/plans/2026-07-28-erdtree-github-runner-design.md
{ inputs, ... }:
{
  den.aspects.erdtree.nixos =
    { config, lib, ... }:
    {
      # Fine-grained PAT (Administration r/w on zen-browser-desktop only) as
      # ACCESS_TOKEN=… — the image mints runner registration tokens from it.
      # agenix defaults (root:root 0400) are correct: systemd reads the
      # env file as root.
      age.secrets.github-runner-zen-env.file = "${inputs.dotfiles-secrets}/github-runner-zen-env.age";

      virtualisation.oci-containers = {
        # docker is already this host's container runtime (wings); nothing
        # else on erdtree uses oci-containers.
        backend = "docker";
        containers.github-runner-zen = {
          # Official actions/runner inside Ubuntu noble; the tag tracks the
          # runner version. Updates arrive by bumping this tag (auto-update
          # off), so pin exactly.
          # NB: the ghcr package is named after the GitHub repo
          # (docker-github-actions-runner) — myoung34/github-runner is only
          # the Docker Hub name; pulling it from ghcr is denied.
          image = "ghcr.io/myoung34/docker-github-actions-runner:2.336.0-ubuntu-noble";
          autoStart = true;
          environment = {
            RUNNER_SCOPE = "repo";
            REPO_URL = "https://github.com/joegoldin/zen-browser-desktop";
            RUNNER_NAME = "erdtree";
            # Dedicated label: only jobs that say runs-on [self-hosted,
            # erdtree] land here.
            LABELS = "erdtree";
            EPHEMERAL = "1";
            DISABLE_AUTO_UPDATE = "1";
          };
          environmentFiles = [ config.age.secrets.github-runner-zen-env.path ];
          # Compile cache survives the ephemeral wipe; everything else is
          # fresh per job. NO docker socket mount — the socket would be a
          # root-equivalent escape hatch and the zen workflow doesn't need it.
          volumes = [ "gha-zen-sccache:/opt/sccache" ];
          # Ceilings, not reservations: 18 of the box's 32 threads at most,
          # and at half the default cgroup weight it yields to garnix, game
          # servers, and interactive use under contention. memory-swap ==
          # memory means the job OOMs at 64G instead of spilling into the
          # 16G swapfile.
          extraOptions = [
            "--cpus=18"
            "--cpu-shares=512"
            "--memory=64g"
            "--memory-swap=64g"
          ];
        };
      };

      # The PAT env file must exist before the container starts (melina
      # pattern). Restart=always (not the module's on-failure): an ephemeral
      # runner exits CLEANLY after each job, and that success exit is exactly
      # when a fresh container must start and re-register — on-failure would
      # end the loop after the first job.
      systemd.services.docker-github-runner-zen = {
        after = [ "agenix.service" ];
        wants = [ "agenix.service" ];
        serviceConfig.Restart = lib.mkForce "always";
      };
    };
}

# Fish abbreviations for git and git-stack. Consumed by the git aspect
# (./git.nix) and by the microVM guest fish config
# (../_data/microvm/fish-guest.nix), which doesn't use aspects.
{
  ga = "git add";
  gp = "git push";
  gc = "git commit";
  gcm = "git commit -m";
  gd = "git diff";
  gf = "git fetch";
  gl = "git log";
  gs = "git status";
  # git-stack aliases
  gss = "git stack sync";
  gnext = "git stack next";
  gprev = "git stack prev";
  greword = "git stack reword";
  gamend = "git stack amend";
  grs = "git rs";
  gps = "git ps";
  grb = "git rbs";
  graps = "git sync && git rs && git ps";
}

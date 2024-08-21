{pkgs, ...}:
with pkgs.nodePackages; [
  nodejs
  wrangler
  yarn
]

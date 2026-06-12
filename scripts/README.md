# Maintenance scripts

Repo upkeep helpers, invoked through the Justfile (`just --list`):

| Script | Just target | Job |
| --- | --- | --- |
| `secret-helper.sh` | `just secret …` | agenix secret create/edit/rekey workflows |
| `setup-python-packages.sh` | `just setup-python-packages` | add PyPI packages to `modules/home/_python/custom-pypi-packages.nix` (resolves deps, pins hashes) |
| `update-python-packages.sh` | `just update-python-packages` | bump versions/hashes of the custom PyPI package set |
| `set-wallpaper.py` | (used by the wallpaper rotation) | applies wallpapers across Plasma activities |

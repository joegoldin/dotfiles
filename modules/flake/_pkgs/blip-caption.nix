{
  lib,
  python3,
  fetchFromGitHub,
}:
python3.pkgs.buildPythonApplication {
  pname = "blip-caption";
  version = "0.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "simonw";
    repo = "blip-caption";
    rev = "0.1";
    hash = "sha256-09hROe6zg4v+Fi8wONeyp+BfIDixDHujOFR8bxC+b4s=";
  };

  build-system = with python3.pkgs; [ setuptools ];

  dependencies = with python3.pkgs; [
    transformers
    click
    torch
    pillow
  ];

  pythonImportsCheck = [ "blip_caption" ];

  meta = {
    description = "Generate captions for images with Salesforce BLIP";
    homepage = "https://github.com/simonw/blip-caption";
    license = lib.licenses.asl20;
    mainProgram = "blip-caption";
    platforms = lib.platforms.unix;
  };
}

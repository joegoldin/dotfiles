{
  pkgs,
  lib,
  ...
}: let
  pythonBase = pkgs.python3;

  # Build a custom Python environment with both nixpkgs packages and pip packages
  buildPythonEnv = {
    # Standard Python packages from nixpkgs
    nixPackages ? [],
    # Custom pip packages with specific versions
    # Format: [ { name = "package-name"; version = "x.y.z"; sha256 = "sha256-hash"; } ]
    pipPackages ? [],
    # Python interpreter to use (default: python3)
    python ? pythonBase,
    # Additional build inputs required by some packages
    extraBuildInputs ? [],
  }: let
    # Function to build a single pip package from source
    buildPipPackage = {
      name,
      version,
      sha256,
      buildInputs ? [],
      propagatedBuildInputs ? [],
    }: let
      # Try different URL patterns for the package
      # The URL structure can vary between packages
      baseName = builtins.replaceStrings ["_"] ["-"] name;
      firstChar = builtins.substring 0 1 baseName;

      # Standard PyPI URL pattern
      pypiUrl = "https://files.pythonhosted.org/packages/source/${firstChar}/${baseName}/${baseName}-${version}.tar.gz";

      # Build the package using nixpkgs' buildPythonPackage function
      package = python.pkgs.buildPythonPackage {
        pname = name;
        inherit version;

        # Fetch the source from PyPI with proper error handling
        src = pkgs.fetchurl {
          url = pypiUrl;
          inherit sha256;
          # Note: Remove the fallback url handling as it's causing the error
        };

        # Include any specified build inputs
        inherit buildInputs propagatedBuildInputs;

        # Disable tests to simplify the build
        doCheck = false;

        # Basic metadata
        meta = with lib; {
          description = "Python package: ${name}";
          homepage = "https://pypi.org/project/${name}/";
          license = licenses.mit; # Assumed license, change if needed
        };
      };
    in
      package;

    # Build all specified pip packages
    customPipPackages = map buildPipPackage pipPackages;

    # Create the Python environment with both nixpkgs and custom pip packages
    pythonEnv = python.withPackages (
      ps:
        nixPackages ++ customPipPackages
    );
  in
    # Return the Python environment directly
    pythonEnv;

  # Standard packages from nixpkgs
  nixPythonPackages = with pythonBase.pkgs;
    [
      anthropic
      black
      flake8
      flask
      isort
      jupyter
      numpy
      ollama
      openai
      pip
      scikit-learn
      tabulate
    ]
    ++ (
      if (pkgs.stdenv.isDarwin && pkgs.stdenv.isAarch64)
      then
        with pythonBase.pkgs; [
          torch-bin
          torchvision-bin
        ]
      else
        with pythonBase.pkgs; [
          torch
          torchvision
        ]
    );

  # Custom pip packages with specific versions and hashes
  # Use the included setup-python-packages.sh script to get the correct hash
  # or run: nix-prefetch-url https://files.pythonhosted.org/packages/source/p/package-name/package-name-version.tar.gz
  customPipPackages = [
    {
      name = "claudesync";
      version = "0.7.1";
      sha256 = "sha256-6gficPfbj4PpvX4k0MpPQQP7DDPb022Yen5LPGaZF/I=";
    }

    # Example custom pip packages - uncomment and update as needed
    # {
    #   name = "anthropic-bedrock";
    #   version = "0.15.0";
    #   sha256 = "sha256-HASH_GOES_HERE";
    # }
    # {
    #   name = "llamaindex";
    #   version = "0.10.0";
    #   sha256 = "sha256-HASH_GOES_HERE";
    # }
  ];
in
  buildPythonEnv {
    nixPackages = nixPythonPackages;
    pipPackages = customPipPackages;
    extraBuildInputs = [];
  }

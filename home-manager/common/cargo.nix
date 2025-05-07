{
  pkgs,
  lib,
  ...
}: {
  packages = {
    litra = pkgs.rustPlatform.buildRustPackage rec {
      pname = "litra-rs";
      version = "v2.2.0";

      buildInputs = with pkgs; [openssl systemd];
      nativeBuildInputs = with pkgs; [pkg-config];

      src = pkgs.fetchFromGitHub {
        owner = "timrogers";
        repo = pname;
        rev = version;
        hash = "sha256-0BwtC2gFdt8rri5WGGdqMThPdax/UrZRfpCykWMydhA=";
      };
      cargoHash = "sha256-4X/jASuXDLKuc3EIeSSnksLDI5CkJYNP/bkPi+24fdo=";
    };
    litra-autotoggle = pkgs.rustPlatform.buildRustPackage rec {
      pname = "litra-autotoggle";
      version = "v0.6.1";

      buildInputs = with pkgs; [openssl systemd];
      nativeBuildInputs = with pkgs; [pkg-config];

      src = pkgs.fetchFromGitHub {
        owner = "timrogers";
        repo = pname;
        rev = version;
        hash = "sha256-CoP9t8uvErvP3sU51pfsjsY/xp/zXNVcgXP8WmONz60=";
      };
      cargoHash = "sha256-hg65H6kALuHbRpiT6CZKP3aBTSLoN0xDEf5QBVfyrq8=";
    };
  };
}

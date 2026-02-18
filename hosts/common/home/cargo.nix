{ pkgs, ... }:
{
  packages = {
    litra = pkgs.rustPlatform.buildRustPackage rec {
      pname = "litra-rs";
      version = "ffc76804b4933585d10f76b6234c068ca84d009a";

      buildInputs = with pkgs; [
        openssl
        systemd
      ];
      nativeBuildInputs = with pkgs; [ pkg-config ];

      src = pkgs.fetchFromGitHub {
        owner = "joegoldin";
        repo = pname;
        rev = version;
        hash = "sha256-0BwtC2gFdt8rri5WGGdqMThPdax/UrZRfpCykWMydhA=";
      };
      cargoHash = "sha256-0T2oq+f7KwNn2nZVEsFBDEt2sRHe/Loq4zVx6jT7/us=";
    };
    litra-autotoggle = pkgs.rustPlatform.buildRustPackage rec {
      pname = "litra-autotoggle";
      version = "391de640657235219d663941120a02f127473f56";

      buildInputs = with pkgs; [
        openssl
        systemd
      ];
      nativeBuildInputs = with pkgs; [ pkg-config ];

      src = pkgs.fetchFromGitHub {
        owner = "joegoldin";
        repo = pname;
        rev = version;
        hash = "sha256-CoP9t8uvErvP3sU51pfsjsY/xp/zXNVcgXP8WmONz60=";
      };
      cargoHash = "sha256-MCabivlj8ye8WKMFJ9oP5+J72D8Ib0xlYEOjLCUKjYg=";
    };
  };
}

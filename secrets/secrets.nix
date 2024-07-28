let
  joegoldin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0vgzxNgZd51jZ3K/s64jltFRSyVLxjLPWM4Q6747Zw";
  users = [joegoldin];

  bastion = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJow7z2zGzCIumF/6ZhJDyBe7WwNm1x4CmvzBhIVDhTl";
  systems = [bastion];
in {
  "cf.age".publicKeys = users ++ systems;
}

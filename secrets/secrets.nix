let
  joegoldin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0vgzxNgZd51jZ3K/s64jltFRSyVLxjLPWM4Q6747Zw";
  users = [joegoldin];

  bastion = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJow7z2zGzCIumF/6ZhJDyBe7WwNm1x4CmvzBhIVDhTl";
  systems = [bastion];
in {
  "cf.json.age".publicKeys = users ++ systems;
  "raspi-printer-wlan.age".publicKeys = users;
  "atuin_session.age".publicKeys = users;
  "atuin_key.age".publicKeys = users;
  "pelican-app-key.age".publicKeys = users ++ systems;
  "pelican-db-password.age".publicKeys = users ++ systems;
  "pelican-redis-password.age".publicKeys = users ++ systems;
  "pelican-token-id.age".publicKeys = users ++ systems;
  "pelican-token.age".publicKeys = users ++ systems;
}

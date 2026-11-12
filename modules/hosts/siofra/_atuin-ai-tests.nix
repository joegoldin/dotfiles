# Evaluate against a NixOS config with lib.runTests; no credentials are needed.
{ lib, config }:
let
  routes = config.services.litellm.settings.model_list;
in
lib.runTests {
  testToolCallingForwarded = {
    expr = lib.all (
      route: builtins.elem "tools" (route.litellm_params.allowed_openai_params or [ ])
    ) routes;
    expected = true;
  };
  testToolsNotSilentlyDropped = {
    expr = !(config.services.litellm.settings.litellm_settings.drop_params or false);
    expected = true;
  };
  testProviderKeyStaysOnServer = {
    expr = lib.all (route: route.litellm_params.api_key == "os.environ/SYNTHETIC_API_KEY") routes;
    expected = true;
  };
  testProxyLoopbackOnly = {
    expr = config.services.litellm.host;
    expected = "127.0.0.1";
  };
}

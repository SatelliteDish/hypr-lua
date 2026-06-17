{
  description = "hypr-lua - Nix module for Hyprland Lua config";

  outputs = { self }: {
    homeManagerModules.default = import ./hypr-lua.nix;
  };
}

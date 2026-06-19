# hypr-lua

A Nix home-manager module for configuring Hyprland's Lua config declaratively.

Since Hyprland 0.55, configuration uses Lua instead of hyprlang. While home-manager's `wayland.windowManager.hyprland.settings` exposes the raw config as a Nix attrset, working with `mkLuaInline` and `_args` everywhere is verbose and error-prone. hypr-lua wraps the most common patterns into a clean interface, with escape hatches per-value using `mkLuaInline` and globally via `extraConfig`.

## Installation

Add hypr-lua as a flake input:

```nix
# flake.nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  home-manager = {
    url = "github:nix-community/home-manager";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  hypr-lua.url = "github:SatelliteDish/hypr-lua";
};

outputs = { nixpkgs, home-manager, hypr-lua, ... }:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    homeConfigurations."youruser" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./home.nix
        hypr-lua.homeManagerModules.default
      ];
    };
  };
```

You must also have the home-manager hyprland module enabled with `configType = "lua"`:

```nix
wayland.windowManager.hyprland = {
  enable = true;
  configType = "lua";
};
```

## Usage

```nix
{ config, lib, ... }:
let
  hl = config.programs.hypr-lua.lib;
in {
  programs.hypr-lua = {
    enable = true;

    # Commands run on Hyprland start
    on.hyprland.start = [
      (hl.exec_cmd "waybar")
      (hl.exec_cmd "hyprpolkitagent")
    ];

    # Keybindings
    bind = [
      { key = "SUPER + C"; handler = hl.dsp.window.close; }
      { key = "SUPER + M"; handler = hl.dsp.exit; }
      { key = "SUPER + T"; handler = hl.dsp.exec_cmd "kitty"; }

      # Use mkLuaInline directly for anything not covered by the helpers
      { key = "SUPER + V"; handler = lib.generators.mkLuaInline "hl.dsp.window.float({ action = 'toggle' })"; }
    ];

    # Passed directly to wayland.windowManager.hyprland.settings
    settings = {
      config.general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        layout = "dwindle";
      };
    };

    # Raw Lua appended at the end for anything the module doesn't cover
    extraConfig = ''
      hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd("dolphin"))
    '';
  };
}
```

See [examples/hyprland.nix](examples/hyprland.nix) for a more complete example including
workspace switching, ricing config, and environment variables.

## lib helpers

Access via `config.programs.hypr-lua.lib` (conventionally aliased to `hl`). All helpers resolve to `luaInline`, meaning any time the option you want is not present you can pass it directly with `mkLuaInline`.

### Top-level

| Helper | Lua equivalent |
|--------|---------------|
| `hl.exec_cmd "cmd"` | `hl.exec_cmd("cmd")` |

### hl.dsp

| Helper | Lua equivalent |
|--------|---------------|
| `hl.dsp.exec_cmd "cmd"` | `hl.dsp.exec_cmd("cmd")` |
| `hl.dsp.exit` | `hl.dsp.exit()` |
| `hl.dsp.no_op` | `hl.dsp.no_op()` |
| `hl.dsp.event "ev"` | `hl.dsp.event("ev")` |
| `hl.dsp.global "name"` | `hl.dsp.global("name")` |
| `hl.dsp.layout "msg"` | `hl.dsp.layout("msg")` |
| `hl.dsp.submap "name"` | `hl.dsp.submap("name")` |

### hl.dsp.window

| Helper | Lua equivalent |
|--------|---------------|
| `hl.dsp.window.close` | `hl.dsp.window.close()` |
| `hl.dsp.window.pseudo` | `hl.dsp.window.pseudo()` |
| `hl.dsp.window.drag` | `hl.dsp.window.drag()` |
| `hl.dsp.window.resize` | `hl.dsp.window.resize()` |

### hl.dsp.workspace

| Helper | Lua equivalent |
|--------|---------------|
| `hl.dsp.workspace.toggle_special "name"` | `hl.dsp.workspace.toggle_special("name")` |

## Known limitations

- **Parametered events** - `on` handlers that receive event parameters (e.g. `window.active` which passes the window) are not yet supported. Use `extraConfig` or `mkLuaInline` for these.
- **Bind options** - the `{ locked, repeating, mouse }` third argument to `hl.bind` is not yet supported. Use `extraConfig` for binds that need these.
- **Complex dispatchers** - helpers that take tables (`focus`, `window.float`, `window.move` etc.) are not provided since their parameter shapes vary. Use `lib.generators.mkLuaInline` directly.

## Contributing

Issues and PRs welcome. This is an early release - if something you need isn't covered, `extraConfig` is your friend in the meantime.

{ config, lib, ... }:
let
  cfg = config.programs.hypr-lua;
in
{
  options.programs.hypr-lua = let
    inherit(lib) types mkOption mkEnableOption;
  in {
    enable = mkEnableOption "hypr-lua";

    lib = mkOption {
      type = types.attrs;
      readOnly = true;
      description = "Helper functions for building Hyprland Lua config";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Raw Lua appended via a separate required file";
    };

    settings = mkOption {
      type = types.attrs;
      default = {};
      description = "Passed directly to wayland.windowManager.hyprland.settings";
    };

    on = let
      mkEvent = desc: mkOption {
        type = types.listOf types.luaInline;
        default = [ ];
        description = desc;
      };
    in mkOption { # Event configuration
      type = types.submodule {
        options = {

          hyprland = mkOption {
            type = types.submodule {
              options = {

                start = mkEvent "Code run once at start";
                shutdown = mkEvent "Code run once before Hyprland exits";

              };
            };
          };

        };
      };
      default = { };
    };

    bind = mkOption {
      type = types.listOf (types.submodule {
        options = {

          key = mkOption {
            type = types.str;
            description = "Key combination e.g. 'SUPER + T'";
          };
          handler = mkOption {
            type = types.luaInline;
            description = "Lua function to call on keypress";
          };
        };
      });
      default = [];
    };

  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.wayland.windowManager.hyprland.enable;
        message = "hypr-lua requires wayland.windowManager.hyprland.enable = true";
      }
      {
        assertion = config.wayland.windowManager.hyprland.configType == "lua";
        message = "hypr-lua requires wayland.windowManager.hyprland.configType = \"lua\"";
      }
    ];

    programs.hypr-lua.lib = let
      pre = "hl";
      mkLua = lib.mkLuaInline;
    in {
      exec_cmd = cmd: mkLua ''${pre}.exec_cmd("${cmd}")'';
      get_config = cfg: mkLua ''${pre}.get_config("${cfg}")'';
      dsp = let
        pre = "hl.dsp";
      in {
        event = ev: mkLua ''${pre}.event("${ev}")'';
        exec_cmd = cmd: mkLua ''${pre}.exec_cmd("${cmd}")'';
        exit = mkLua ''${pre}.exit()'';
        global = gb: mkLua ''${pre}.global("${gb}")'';
        layout = msg: mkLua ''${pre}.layout("${msg}")'';
        no_op = mkLua ''${pre}.no_op()'';
        submap = name: mkLua ''${pre}.submap("${name}")'';
        window = let
          pre = "hl.dsp.window";
        in {
          close = mkLua ''${pre}.close()'';
          pseudo = mkLua ''${pre}.pseudo()'';
          drag = mkLua ''${pre}.drag()'';
          resize = mkLua ''${pre}.resize()'';
        };
        workspace = let
          pre = "hl.dsp.workspace";
        in {
          toggle_special = name: mkLua ''${pre}.toggle_special("${name}")'';
        };
      };
    };

    wayland.windowManager.hyprland = {
      settings = lib.mkMerge [
        cfg.settings
        {
          on = let
            implEvent = { name, code }: {
              _args = [
                name
                (lib.generators.mkLuaInline ''
                  function()
                  ${
                    lib.concatMapStringsSep "\n" (inline: inline.expr) code
                  }
                  end
                '')
              ];
            };
          in [
            (implEvent { name = "hyprland.start"; code = cfg.on.hyprland.start; })
            (implEvent { name = "hyprland.shutdown"; code = cfg.on.hyprland.shutdown; })
          ];
          bind = builtins.map (conf: {
            _args = [
              conf.key
              conf.handler
            ];
          }) cfg.bind;

          # Hack to get extra Lua config imported
          get_config = lib.mkIf (cfg.extraConfig != "")
            (lib.generators.mkLuaInline ''(function() require("hypr-lua-extra") return "" end)()'');
        }
      ];
    };

    # For extra Lua config
    xdg.configFile."hypr/hypr-lua-extra.lua" = lib.mkIf (cfg.extraConfig != "") {
      text = cfg.extraConfig;
    };
  };

  meta = {
    maintainers = with lib.maintainers; [
      {
        name = "Michael Vitale";
        email = "michael@sortofrad.com";
        github = "SatelliteDish";
        githubId = "94733164";
      }
    ];
  };
}

{ config, lib, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    configType = "lua";
  };

  programs.hypr-lua = let
    hl = config.programs.hypr-lua.lib;
    mod = "SUPER";
    modShift = "${mod} + SHIFT";
  in {
    enable = true;

    on.hyprland.start = [
      (hl.exec_cmd "waybar")
      (hl.exec_cmd "hyprpolkitagent")
    ];

    bind = [
      { key = "${mod} + C";      handler = hl.dsp.window.close; }
      { key = "${mod} + M";      handler = hl.dsp.exit; }
      { key = "${mod} + RETURN"; handler = hl.dsp.exec_cmd "kitty"; }
      { key = "${mod} + V";      handler = lib.generators.mkLuaInline "hl.dsp.window.float({ action = 'toggle' })"; }
    ]
    ++ builtins.concatMap (i: let
      nm = if i == 10 then 0 else i;
    in [
      { key = "${mod} + ${toString nm}";      handler = lib.generators.mkLuaInline "hl.dsp.focus({ workspace = ${toString nm} })"; }
      { key = "${modShift} + ${toString nm}"; handler = lib.generators.mkLuaInline "hl.dsp.window.move({ workspace = ${toString nm} })"; }
    ]) (builtins.genList (x: x + 1) 10);

    settings = {
      env = [
        { _args = [ "XDG_CURRENT_DESKTOP" "Hyprland" ]; }
        { _args = [ "NIXOS_OZONE_WL" "1" ]; }
      ];
      config.general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        col = {
          active_border = {
            colors = [ "rgba(33ccffee)" "rgba(00ff99ee)" ];
            angle = 45;
          };
          inactive_border = "rgba(595959aa)";
        };
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };
      config.dwindle.preserve_split = true;
      config.input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad.natural_scroll = false;
      };
    };
  };
}

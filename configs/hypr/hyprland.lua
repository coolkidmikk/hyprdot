-----------------------------------------------------------------------------------------
--  _   _                  _                 _                                         --
-- | | | |                | |               | |                                        --
-- | |_| |_   _ _ __  _ __| | __ _ _ __   __| |                                        --
-- |  _  | | | | '_ \| '__| |/ _` | '_ \ / _` |                                        --
-- | | | | |_| | |_) | |  | | (_| | | | | (_| |                                        --
-- \_| |_/\__, | .__/|_|  |_|\__,_|_| |_|\__,_|                                        --
--         __/ | |                                                                     --
--        |___/|_|                                                                     --
-----------------------------------------------------------------------------------------

---------------------
---- MY PROGRAMS ----
---------------------

local mainMod    = "SUPER"
local terminal   = "kitty"
local fileManager= "nemo"
local browser    = "firefox"
local scriptsDir = os.getenv("HOME") .. "/.config/hypr/scripts"


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "DP-1",
    mode     = "1440x900@60",
    position = "auto",
    scale    = 1,
})


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function ()
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("hyprctl setcursor ComixCursors-White 50")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd(scriptsDir .. "/start_mic.sh")
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/screenshot")
hl.env("XCURSOR_THEME", "ComixCursors-White")
hl.env("XCURSOR_SIZE", "50")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 3,

        border_size = 2,

        col = {
            active_border   = "rgba(ffffffcc)",
            inactive_border = "rgba(111111aa)",
        },

        layout = "dwindle",

        resize_on_border = false,
        allow_tearing    = false,
    },

    decoration = {
        rounding = 0,

        active_opacity   = 1.9,
        inactive_opacity = 0.8,

        shadow = {
            enabled      = false,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 2,
            passes   = 3,
            vibrancy = 0.1696,
        },
    },
})

---------------------
---- ANIMATIONS -----
---------------------

-- Custom curves
hl.curve("linear",        { type = "bezier", points = { {0, 0},      {1, 1} } })
hl.curve("md3_standard", { type = "bezier", points = { {0.2, 0},    {0, 1} } })
hl.curve("md3_decel",    { type = "bezier", points = { {0.05, 0.7}, {0.1, 1} } })
hl.curve("md3_accel",    { type = "bezier", points = { {0.3, 0},    {0.8, 0.15} } })
hl.curve("overshot",      { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.1} } })
hl.curve("crazyshot",     { type = "bezier", points = { {0.1, 1.5},  {0.76, 0.92} } })
hl.curve("hyprnostretch", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0} } })
hl.curve("fluent_decel",  { type = "bezier", points = { {0.1, 1},    {0, 1} } })
hl.curve("easeInOutCirc", { type = "bezier", points = { {0.85, 0},   {0.15, 1} } })
hl.curve("easeOutCirc",   { type = "bezier", points = { {0, 0.55},   {0.45, 1} } })
hl.curve("easeOutExpo",   { type = "bezier", points = { {0.16, 1},   {0.3, 1} } })

hl.config({
    animations = {
        enabled = true,
    },
})

hl.animation({ leaf = "windows",    enabled = true, speed = 3,   bezier = "md3_decel",   style = "popin 60%" })
hl.animation({ leaf = "border",     enabled = true, speed = 10,  bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 2.5, bezier = "md3_decel" })
hl.animation({ leaf = "layers",     enabled = true, speed = 2.5, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5,   bezier = "easeOutExpo", style = "slidefade 20%" })


---------------------
---- LAYER RULES ----
---------------------

hl.layer_rule({
    name  = "mako-notifs",
    match = { namespace = "notifications" },
    animation = "slide",
})

hl.layer_rule({
    name  = "rofi-launcher",
    match = { namespace = "rofi" },
    animation = "slide-bottom",
})


-----------------
---- LAYOUTS ----
-----------------

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
})


--------------
---- MISC ----
--------------

hl.config({
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout    = "us",
        kb_variant   = ",alt",
        follow_mouse = 1,
        sensitivity  = 0,

        repeat_delay = 400,
        repeat_rate  = 60,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_initial_focus = true,
})

-- Windowrule for Music-player
hl.window_rule({
    name  = "music-player",
    match = { initial_class = "music" },
    float     = true,
    center    = true,
    size      = "875 500",
    animation = "popin",
})

-- Windowrule for Word-helper
hl.window_rule({
    name  = "word-helper",
    match = { title = "^(WordHelper)$" },
    float        = true,
    center       = true,
    pin          = true,
    border_size  = 0,
    stay_focused = true,
})


---------------------
---- KEYBINDINGS ----
---------------------

-- --- Important Apps ---
hl.bind(mainMod .. " + slash",    hl.dsp.exec_cmd(scriptsDir .. "/keybinds_hint.sh"))
hl.bind(mainMod .. " + T",        hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + T",hl.dsp.exec_cmd("foot"))
hl.bind(mainMod .. " + B",        hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E",        hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + A",        hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(mainMod .. " + D",        hl.dsp.exec_cmd("vesktop"))

-- --- Window Actions ---
hl.bind(mainMod .. " + Q",        hl.dsp.exec_cmd(scriptsDir .. "/dontkillsteam.sh"))
hl.bind(mainMod .. " + W",        hl.dsp.exec_cmd(scriptsDir .. "/float_custom.sh"))
hl.bind(mainMod .. " + Z",        hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + J",hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + SHIFT + S",hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + S",        hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + W",  hl.dsp.exec_cmd("killall -SIGUSR1 waybar || waybar"))
hl.bind("SHIFT + F11",            hl.dsp.window.fullscreen())

-- --- System & Tools ---
hl.bind("CTRL + ALT + DELETE",    hl.dsp.exec_cmd(scriptsDir .. "/powermenu.sh"))
hl.bind(mainMod .. " + V",        hl.dsp.exec_cmd(scriptsDir .. "/clipboard.sh"))
hl.bind(mainMod .. " + SHIFT + W",hl.dsp.exec_cmd(scriptsDir .. "/wallpaper_changer.sh"))
hl.bind("Print",                  hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + SHIFT + L",hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + P",        hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind(mainMod .. " + SHIFT + P",hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + period",   hl.dsp.exec_cmd(scriptsDir .. "/emoji_picker.sh"))
hl.bind(mainMod .. " + N",        hl.dsp.exec_cmd("python " .. scriptsDir .. "/gif.py"))
hl.bind(mainMod .. " + I",        hl.dsp.exec_cmd("python " .. scriptsDir .. "/helper.py"))
hl.bind(mainMod .. " + M",        hl.dsp.exec_cmd(scriptsDir .. "/music_player.sh"))
hl.bind(mainMod .. " + SHIFT + K",hl.dsp.exec_cmd(scriptsDir .. "/screenrecord.sh"))
hl.bind(mainMod .. " + SHIFT + G",hl.dsp.exec_cmd("foot --app-id=lyrics -e python3 ~/.config/hypr/scripts/mocp_lyrics.py"))
hl.bind(mainMod .. " + G",        hl.dsp.exec_cmd(scriptsDir .. "/gamemode.sh"))
hl.bind(mainMod .. " + SHIFT + R",hl.dsp.exec_cmd(scriptsDir .. "/voicerecord.sh"))
hl.bind(mainMod .. " + Tab",      hl.dsp.exec_cmd("hyprctl dispatch hyprwinview:overview toggle"))

-- --- Hardware Keys (Repeating) ---
hl.bind("F12", hl.dsp.exec_cmd(scriptsDir .. "/volumectrl.sh up"),   { repeating = true })
hl.bind("F11", hl.dsp.exec_cmd(scriptsDir .. "/volumectrl.sh down"), { repeating = true })
hl.bind("F10", hl.dsp.exec_cmd(scriptsDir .. "/volumectrl.sh mute"), { repeating = true })
hl.bind("F2",  hl.dsp.exec_cmd(scriptsDir .. "/brightnessctrl.sh up"),   { repeating = true })
hl.bind("F1",  hl.dsp.exec_cmd(scriptsDir .. "/brightnessctrl.sh down"), { repeating = true })

-- --- Alt + Arrow Keys for Gammastep ---
hl.bind("ALT + Up",   hl.dsp.exec_cmd(scriptsDir .. "/gammastep_ctrl.sh bright_up"))
hl.bind("ALT + Down", hl.dsp.exec_cmd(scriptsDir .. "/gammastep_ctrl.sh bright_down"))
hl.bind("ALT + Left", hl.dsp.exec_cmd(scriptsDir .. "/gammastep_ctrl.sh temp_down"))
hl.bind("ALT + Right",hl.dsp.exec_cmd(scriptsDir .. "/gammastep_ctrl.sh temp_up"))
hl.bind("ALT + 0",    hl.dsp.exec_cmd(scriptsDir .. "/gammastep_ctrl.sh reset"))

-- --- Navigation (Standard) ---
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

-- --- Resize Windows (Repeating) ---
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 30 0"),   { repeating = true })
hl.bind(mainMod .. " + SHIFT + Left",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive -30 0"),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + Up",    hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -30"),  { repeating = true })
hl.bind(mainMod .. " + SHIFT + Down",  hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 30"),   { repeating = true })

-- --- Precise Movement ---
local moveactivewindow = 'grep -q "true" <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive'
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.exec_cmd(moveactivewindow .. " -30 0 || hyprctl dispatch movewindow l"), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.exec_cmd(moveactivewindow .. " 30 0 || hyprctl dispatch movewindow r"),  { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.exec_cmd(moveactivewindow .. " 0 -30 || hyprctl dispatch movewindow u"), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.exec_cmd(moveactivewindow .. " 0 30 || hyprctl dispatch movewindow d"),  { repeating = true })

-- --- Mouse Actions ---
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- --- Workspace Switching & Window Movement (0-9) ---
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll Workspaces with mainMod + mouse wheel
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

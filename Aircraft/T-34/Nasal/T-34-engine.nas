##
## T-34 Engine Start/Stop Control (STABLE REVERSE + FIXED ANIMATIONS)
##

var engine_on         = props.globals.getNode("sim/model/t34/engine-on", 1);
var starter           = props.globals.getNode("sim/model/t34/starter", 1);
var engine_stop_sound = props.globals.getNode("sim/model/t34/engine-stop-sound", 1);

var MAX_REVERSE_FPS = 6.56;   # ~4 km/h
var REVERSE_ACCEL   = 0.35;

# -----------------------------------------------------------------------
# INIT
# -----------------------------------------------------------------------
engine_on.setBoolValue(0);
setprop("sim/multiplay/generic/bool[3]", 0);
starter.setBoolValue(0);
setprop("sim/multiplay/generic/bool[4]", 0);
engine_stop_sound.setBoolValue(0);
setprop("sim/multiplay/generic/bool[6]", 0);

setprop("controls/engines/engine[0]/magnetos", 0);
setprop("controls/engines/engine[0]/starter", 0);
setprop("controls/engines/engine[0]/throttle", 0);
setprop("controls/engines/engine[1]/throttle", 0);
setprop("controls/engines/engine[0]/mixture", 1);

setprop("/sim/model/t34/wheel-speed-ms", 0.0);
setprop("/sim/model/t34/ground-speed-kt", 0.0);
setprop("/sim/model/t34/reverse", 0);

var reverse_target_fps = 0.0;

# -----------------------------------------------------------------------
# TOGGLE REVERSE
# -----------------------------------------------------------------------
var toggle_reverse = func() {

    if (!engine_on.getBoolValue()) {
        screen.log.write("T-34: Engine is OFF!", 1, 0.3, 0);
        return;
    }

    var r = getprop("/sim/model/t34/reverse") or 0;

    if (!r) {
        var spd = math.abs(getprop("velocities/groundspeed-kt") or 0);
        if (spd > 0.5) {
            screen.log.write("T-34: Stop to REVERSE!", 1, 0.2, 0);
            return;
        }
        setprop("/sim/model/t34/reverse", 1);
        reverse_target_fps = 0.0;
        screen.log.write("T-34: Reverse ON", 1, 0.6, 0);
    } else {
        setprop("/sim/model/t34/reverse", 0);
        reverse_target_fps = 0.0;
        screen.log.write("T-34: Forward", 0, 1, 0);
    }
};

# -----------------------------------------------------------------------
# REVERSE LOOP (STABLE FIX + LIMIT)
# -----------------------------------------------------------------------
var reverse_loop = maketimer(0.02, func {

    var reverse = getprop("/sim/model/t34/reverse") or 0;

    if (!reverse or !engine_on.getBoolValue()) {
        reverse_target_fps = 0.0;
        return;
    }

    var user_thr = getprop("controls/engines/engine[0]/throttle") or 0;
    if (user_thr < 0) user_thr = 0;

    setprop("controls/engines/engine[0]/throttle", 0);
    setprop("controls/engines/engine[1]/throttle", 0);

    var bp = getprop("controls/gear/brake-parking") or 0;
    var bl = getprop("controls/gear/brake-left") or 0;
    var br = getprop("controls/gear/brake-right") or 0;
    var braking = math.max(bp, (bl + br) * 0.5);

    # acceleration (FIXED)
    if (user_thr > 0.02 and braking < 0.3) {
        reverse_target_fps += user_thr * REVERSE_ACCEL;
    }

    # HARD LIMIT (important)
    if (reverse_target_fps > MAX_REVERSE_FPS) {
        reverse_target_fps = MAX_REVERSE_FPS;
    }

    # braking
    if (braking > 0.3) {
        reverse_target_fps *= 0.85;
    }

    # natural decay
    elsif (user_thr <= 0.01) {
        reverse_target_fps *= 0.998;
    }

    if (reverse_target_fps < 0.01) {
        reverse_target_fps = 0.0;
    }

    var wow = getprop("gear/gear[0]/wow") or 0;
    if (!wow) return;

    setprop("velocities/uBody-fps", 0.0);
    setprop("velocities/vBody-fps", 0.0);

    if (reverse_target_fps <= 0.01) return;

    var heading_rad = getprop("orientation/heading-deg") * math.pi / 180.0;
    var lat = getprop("position/latitude-deg");
    var lon = getprop("position/longitude-deg");
    var R = 6378137.0;

    var dist = reverse_target_fps * 0.02;

    setprop("position/latitude-deg",
        lat - math.cos(heading_rad) * dist / R * (180.0 / math.pi));

    setprop("position/longitude-deg",
        lon - math.sin(heading_rad) * dist / (R * math.cos(lat * math.pi / 180.0)) * (180.0 / math.pi));
});
reverse_loop.start();

# -----------------------------------------------------------------------
# CLUTCH + ANIMATION SYNC (THIS FIXES YOUR TRACKS)
# -----------------------------------------------------------------------
var clutch_sync = maketimer(0.05, func {

    var spd     = getprop("velocities/groundspeed-kt") or 0;
    var abs_spd = math.abs(spd);
    var wow     = getprop("gear/gear[0]/wow") or 0;
    var reverse = getprop("/sim/model/t34/reverse") or 0;

    var clutch_fwd = (engine_on.getBoolValue() and wow and abs_spd > 0.3 and !reverse);

    var clutch_rev = (reverse and engine_on.getBoolValue() and wow and reverse_target_fps > 0.05);

    # -----------------------------
    # WHEELS (FIXED)
    # -----------------------------
    if (clutch_rev) {
        setprop("/sim/model/t34/wheel-speed-ms", -reverse_target_fps);
    } else {
        var roll = getprop("gear/gear[1]/rollspeed-ms") or 0;
        setprop("/sim/model/t34/wheel-speed-ms", clutch_fwd ? math.abs(roll) : 0.0);
    }

    # -----------------------------
    # TRACKS (FIXED)
    # -----------------------------
    var display_spd = 0.0;

    if (clutch_rev) {
        display_spd = -(reverse_target_fps * 1.944);
    } elsif (clutch_fwd) {
        display_spd = abs_spd;
    }

    setprop("/sim/model/t34/ground-speed-kt", display_spd);
    setprop("sim/multiplay/generic/bool[5]", clutch_fwd or clutch_rev ? 1 : 0);
});
clutch_sync.start();

# -----------------------------------------------------------------------
# START ENGINE
# -----------------------------------------------------------------------
var start_engine = func() {
    if (engine_on.getBoolValue()) return;

    setprop("/sim/model/t34/reverse", 0);
    reverse_target_fps = 0.0;

    setprop("controls/engines/engine[0]/magnetos", 3);
    setprop("controls/engines/engine[0]/starter", 1);

    starter.setBoolValue(1);

    settimer(func {
        setprop("controls/engines/engine[0]/starter", 0);
        starter.setBoolValue(0);

        engine_on.setBoolValue(1);
        setprop("sim/multiplay/generic/bool[3]", 1);
    }, 4.0);
};

# -----------------------------------------------------------------------
# STOP ENGINE
# -----------------------------------------------------------------------
var stop_engine = func() {

    engine_on.setBoolValue(0);
    starter.setBoolValue(0);

    setprop("controls/engines/engine[0]/magnetos", 0);
    setprop("controls/engines/engine[0]/throttle", 0);

    setprop("/sim/model/t34/reverse", 0);
    reverse_target_fps = 0.0;

    engine_stop_sound.setBoolValue(1);

    settimer(func {
        engine_stop_sound.setBoolValue(0);
    }, 3.0);
};

# -----------------------------------------------------------------------
# BRAKE SOUND SYNC (RESTORED)
# -----------------------------------------------------------------------
var brake_sync = maketimer(0.1, func {

    var wow   = getprop("gear/gear[0]/wow") or 0;
    var spd   = getprop("velocities/groundspeed-kt") or 0;

    var bl = getprop("controls/gear/brake-left") or 0;
    var br = getprop("controls/gear/brake-right") or 0;
    var bp = getprop("controls/gear/brake-parking") or 0;

    var brake = math.max(bp, (bl + br) * 0.5);

    var intensity = 0.0;

    # brzdy len keď sa tank hýbe
    if (wow and engine_on.getBoolValue() and math.abs(spd) > 0.5) {
        intensity = brake * math.min(math.abs(spd) / 10.0, 1.0);
    }

    setprop("sim/multiplay/generic/float[14]", intensity);
});
brake_sync.start();

print("T-34 Engine Control: STABLE REVERSE + ANIMATIONS LOADED");
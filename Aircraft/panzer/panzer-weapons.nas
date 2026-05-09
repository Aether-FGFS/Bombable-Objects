# =============================================================
# Panzer IV - Weapon System
# =============================================================
# Keys:
#   e       = Cannon fire (30s reload)
#   g       = Machine gun (hold)
#   q / w   = Turret left / right (hold = continuous)
#   x       = Turret center
#   r / f   = Barrel up / down (hold = continuous)
#   c       = Barrel center
# =============================================================

var BARREL_MAX =  20.0;
var BARREL_MIN =  -8.0;
var STEP_INTERVAL = 0.05;   # seconds between steps (hold)
var RELOAD_TIME   = 8.7;   # cannon reload seconds

# Panzer IV turret traverse: ~16 deg/s (historical)
# deg per timer tick = speed * STEP_INTERVAL
var TURRET_SPEED       = 16.0;                        # degrees per second
var TURRET_DEG_PER_STEP = TURRET_SPEED * STEP_INTERVAL; # = 0.8 deg / tick

var _barrel_timer  = nil;
var _turret_timer  = nil;
var _cannon_ready  = 1;     # 1 = ready, 0 = reloading
var _reload_timer  = nil;

# Init properties
setprop("sim/multiplay/generic/float[8]",  0);
setprop("sim/multiplay/generic/float[9]",  0);
setprop("sim/multiplay/generic/float[10]", 0);  # AA heading
setprop("sim/multiplay/generic/float[11]", 0);  # AA pitch
setprop("sim/model/turret[0]/heading", 0);
setprop("sim/model/turret[0]/pitch",   0);

# -------------------------------------------------------
# Turret rotation - continuous while held
# -------------------------------------------------------
var turret_step = func(deg) {
    var cur = getprop("sim/multiplay/generic/float[8]") or 0;
    var nxt = cur + deg;
    while (nxt >  180) nxt -= 360;
    while (nxt < -180) nxt += 360;
    setprop("sim/multiplay/generic/float[8]", nxt);
    setprop("sim/model/turret[0]/heading", nxt);
};

var turret_start = func(dir) {
    # dir: +1 = right, -1 = left
    var step = dir * TURRET_DEG_PER_STEP;
    turret_step(step);
    setprop("sim/multiplay/generic/bool[1]", 1);  # turret rotating sound
    _turret_timer = maketimer(STEP_INTERVAL, func { turret_step(step); });
    _turret_timer.start();
};

var turret_stop = func {
    if (_turret_timer != nil) {
        _turret_timer.stop();
        _turret_timer = nil;
    }
    setprop("sim/multiplay/generic/bool[1]", 0);
};

# -------------------------------------------------------
# Barrel elevation - continuous while held
# -------------------------------------------------------
var barrel_step = func(deg) {
    var cur = getprop("sim/multiplay/generic/float[9]") or 0;
    var nxt = cur + deg;
    if (nxt > BARREL_MAX) nxt = BARREL_MAX;
    if (nxt < BARREL_MIN) nxt = BARREL_MIN;
    setprop("sim/multiplay/generic/float[9]", nxt);
    setprop("sim/model/turret[0]/pitch", nxt);
    
};

var barrel_start = func(deg) {
    barrel_step(deg);
    _barrel_timer = maketimer(STEP_INTERVAL, func { barrel_step(deg); });
    _barrel_timer.start();
    setprop("sim/multiplay/generic/bool[2]", 1);  # barrel moving sound
};

var barrel_stop = func {
    if (_barrel_timer != nil) {
        _barrel_timer.stop();
        _barrel_timer = nil;
    setprop("sim/multiplay/generic/bool[2]", 0);  # barrel moving sound
    }
};

# -------------------------------------------------------
# Cannon with reload
# -------------------------------------------------------
var fire_cannon = func {
    if (!_cannon_ready) {
        print("Panzer CANNON: Reloading...");
        return;
    }
    # Fire!
    setprop("sim/multiplay/generic/int[10]", 1);
    settimer(func { setprop("sim/multiplay/generic/int[10]", 0); }, 1.4);

    # Start reload
    _cannon_ready = 0;
    print("Panzer CANNON: BOOM! Reloading... (" ~ RELOAD_TIME ~ "s)");
    _reload_timer = maketimer(RELOAD_TIME, func {
        _cannon_ready = 1;
        print("Panzer CANNON: Ready to fire!");
    });
    _reload_timer.singleShot = 1;
    _reload_timer.start();
};

# -------------------------------------------------------
# AA MG 34 - Fliegerabwehr (anti-aircraft)
# Heading: float[10]  Pitch: float[11]  Trigger: int[12]
# Pitch limits: -10° .. +85°
# -------------------------------------------------------
var AA_MAX =  85.0;
var AA_MIN = -10.0;

var _aa_rotate_timer = nil;
var _aa_elev_timer   = nil;

var aa_rotate_step = func(deg) {
    var cur = getprop("sim/multiplay/generic/float[10]") or 0;
    var nxt = cur + deg;
    while (nxt >  180) nxt -= 360;
    while (nxt < -180) nxt += 360;
    setprop("sim/multiplay/generic/float[10]", nxt);
};

var aa_rotate_start = func(deg) {
    aa_rotate_step(deg);
    _aa_rotate_timer = maketimer(STEP_INTERVAL, func { aa_rotate_step(deg); });
    _aa_rotate_timer.start();
};

var aa_rotate_stop = func {
    if (_aa_rotate_timer != nil) {
        _aa_rotate_timer.stop();
        _aa_rotate_timer = nil;
    }
};

var aa_elev_step = func(deg) {
    var cur = getprop("sim/multiplay/generic/float[11]") or 0;
    var nxt = cur + deg;
    if (nxt > AA_MAX) nxt = AA_MAX;
    if (nxt < AA_MIN) nxt = AA_MIN;
    setprop("sim/multiplay/generic/float[11]", nxt);
};

var aa_elev_start = func(deg) {
    aa_elev_step(deg);
    _aa_elev_timer = maketimer(STEP_INTERVAL, func { aa_elev_step(deg); });
    _aa_elev_timer.start();
};

var aa_elev_stop = func {
    if (_aa_elev_timer != nil) {
        _aa_elev_timer.stop();
        _aa_elev_timer = nil;
    }
};

# -------------------------------------------------------
# Sync listeners - REMOVED (float[8] and float[9] are tied
# properties in FG multiplay, setlistener does not work on them.
# Values are set directly via setprop in turret_step/barrel_step)
# -------------------------------------------------------

print("Panzer IV weapon system ready.");
print("  e=Cannon(30s reload)  g=MG(hold)  p=AA MG(hold)");
print("  q/w=Turret L/R(hold)  x=center");
print("  r/f=Barrel up/down(hold)  c=center");
print("  u/o=AA rotate L/R(hold)  i/k=AA up/down(hold)  j=AA center");

# Bombable faction
setprop("/bombable/player-faction", "B");

# =============================================================
# T-34 - Weapon System
# =============================================================
# Keys (defined in T-34-76-set.xml):
#   e         = Cannon fire (8s reload)
#   g (hold)  = MG Coaxial fire DT 7.62mm
#   y (hold)  = AA MG fire DT 7.62mm
#   u/o       = AA rotate left/right (hold)
#   i/k       = barrel up/down (hold)
#   q / w     = Turret left / right (hold)
#   x         = Turret center
#   r / f     = Cannon up / down (hold)
#   c         = Cannon center
#   shift+n   = Front MG fire (hold)
#   shift j/l = Front MG left/right (hold)
#   shift+i/k = Front MG up/down (hold)
# =============================================================

var BARREL_MAX    = 25.0;
var BARREL_MIN    = -5.0;
var STEP_INTERVAL = 0.05;
var RELOAD_TIME   = 8.3;

var TURRET_SPEED        = 15.0;
var TURRET_DEG_PER_STEP = TURRET_SPEED * STEP_INTERVAL;
var BARREL_SPEED        = 15.0;
var BARREL_DEG_PER_STEP = BARREL_SPEED * STEP_INTERVAL;
var AA_SPEED            = 15.0;
var AA_DEG_PER_STEP     = AA_SPEED * STEP_INTERVAL;

var _barrel_timer = nil;
var _turret_timer = nil;
var _cannon_ready = 1;
var _reload_timer = nil;

setprop("sim/multiplay/generic/float[8]",  0);
setprop("sim/multiplay/generic/float[9]",  0);
setprop("sim/multiplay/generic/float[10]", 0);
setprop("sim/multiplay/generic/float[11]", 0);
setprop("sim/multiplay/generic/int[10]",   0);
setprop("sim/multiplay/generic/int[11]",   0);
setprop("sim/multiplay/generic/int[12]",   0);
setprop("sim/model/turret[0]/heading",     0);
setprop("sim/model/turret[0]/pitch",       0);

# --- Turret ---
var turret_step = func(deg) {
    var cur = getprop("sim/multiplay/generic/float[8]") or 0;
    var nxt = cur + deg;
    while (nxt >  180) nxt -= 360;
    while (nxt < -180) nxt += 360;
    setprop("sim/multiplay/generic/float[8]", nxt);
    setprop("sim/model/turret[0]/heading",    nxt);
    setprop("sim/model/t34/sub-heading",     -nxt);  # negated for submodels
};

var turret_start = func(dir) {
    var step = dir * TURRET_DEG_PER_STEP;
    turret_step(step);
    setprop("sim/multiplay/generic/bool[1]", 1);
    _turret_timer = maketimer(STEP_INTERVAL, func { turret_step(step); });
    _turret_timer.start();
};

var turret_stop = func {
    if (_turret_timer != nil) { _turret_timer.stop(); _turret_timer = nil; }
    setprop("sim/multiplay/generic/bool[1]", 0);
};

var turret_center = func {
    turret_stop();
    var current = getprop("sim/multiplay/generic/float[8]") or 0;
    if (math.abs(current) < 0.01) return;
    var dir = (current > 0) ? -1 : 1;
    turret_start(dir);
    _turret_timer.stop();
    _turret_timer = maketimer(STEP_INTERVAL, func {
        var v = getprop("sim/multiplay/generic/float[8]") or 0;
        if ((dir < 0 and v <= 0) or (dir > 0 and v >= 0)) {
            turret_stop();
            setprop("sim/multiplay/generic/float[8]", 0);
            setprop("sim/model/turret[0]/heading",    0);
            setprop("sim/model/t34/sub-heading",      0);
        } else {
            turret_step(dir * TURRET_DEG_PER_STEP);
        }
    });
    _turret_timer.start();
};

# --- Barrel ---
var barrel_step = func(deg) {
    var cur = getprop("sim/multiplay/generic/float[9]") or 0;
    var nxt = cur + deg;
    if (nxt > BARREL_MAX) nxt = BARREL_MAX;
    if (nxt < BARREL_MIN) nxt = BARREL_MIN;
    setprop("sim/multiplay/generic/float[9]", nxt);
    setprop("sim/model/turret[0]/pitch",      nxt);
};

var barrel_start = func(dir) {
    barrel_step(dir);
    _barrel_timer = maketimer(STEP_INTERVAL, func { barrel_step(dir); });
    _barrel_timer.start();
    setprop("sim/multiplay/generic/bool[2]", 1);  # barrel moving sound
};

var barrel_stop = func {
    if (_barrel_timer != nil) { _barrel_timer.stop(); _barrel_timer = nil; }
    setprop("sim/multiplay/generic/bool[2]", 0);  # barrel moving sound
};

var barrel_center = func {
    barrel_stop();
    var current = getprop("sim/multiplay/generic/float[9]") or 0;
    if (math.abs(current) < 0.01) return;
    var dir = (current > 0) ? -1 : 1;
    _barrel_timer = maketimer(STEP_INTERVAL, func {
        var v = getprop("sim/multiplay/generic/float[9]") or 0;
        if ((dir < 0 and v <= 0) or (dir > 0 and v >= 0)) {
            barrel_stop();
            setprop("sim/multiplay/generic/float[9]", 0);
            setprop("sim/model/turret[0]/pitch",      0);
        } else {
            barrel_step(dir * BARREL_DEG_PER_STEP);
        }
    });
    _barrel_timer.start();
};

# --- 76mm Cannon ---
var fire_cannon = func {
    if (!_cannon_ready) { print("T-34: Still reloading..."); return; }
    setprop("sim/multiplay/generic/int[10]", 1);
    settimer(func { setprop("sim/multiplay/generic/int[10]", 0); }, 1.4);
    _cannon_ready = 0;
    print("T-34 CANNON: BUM! Loading (" ~ RELOAD_TIME ~ "s)");
    _reload_timer = maketimer(RELOAD_TIME, func {
        _cannon_ready = 1;
        print("T-34 Cannon: Ready!");
    });
    _reload_timer.singleShot = 1;
    _reload_timer.start();
};

# --- Coaxial MG ---
var fire_mg = func { setprop("sim/multiplay/generic/int[11]", 1); };
var stop_mg = func { setprop("sim/multiplay/generic/int[11]", 0); };

# --- AA MG ---
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
    if (_aa_rotate_timer != nil) { _aa_rotate_timer.stop(); _aa_rotate_timer = nil; }
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
    if (_aa_elev_timer != nil) { _aa_elev_timer.stop(); _aa_elev_timer = nil; }
};

var aa_center = func {
    aa_rotate_stop(); aa_elev_stop();
    var cur_r = getprop("sim/multiplay/generic/float[10]") or 0;
    var cur_e = getprop("sim/multiplay/generic/float[11]") or 0;
    if (math.abs(cur_r) > 0.01) {
        var dir_r = (cur_r > 0) ? -1 : 1;
        _aa_rotate_timer = maketimer(STEP_INTERVAL, func {
            var v = getprop("sim/multiplay/generic/float[10]") or 0;
            if ((dir_r < 0 and v <= 0) or (dir_r > 0 and v >= 0)) {
                aa_rotate_stop();
                setprop("sim/multiplay/generic/float[10]", 0);
            } else {
                aa_rotate_step(dir_r * AA_DEG_PER_STEP);
            }
        });
        _aa_rotate_timer.start();
    }
    if (math.abs(cur_e) > 0.01) {
        var dir_e = (cur_e > 0) ? -1 : 1;
        _aa_elev_timer = maketimer(STEP_INTERVAL, func {
            var v = getprop("sim/multiplay/generic/float[11]") or 0;
            if ((dir_e < 0 and v <= 0) or (dir_e > 0 and v >= 0)) {
                aa_elev_stop();
                setprop("sim/multiplay/generic/float[11]", 0);
            } else {
                aa_elev_step(dir_e * AA_DEG_PER_STEP);
            }
        });
        _aa_elev_timer.start();
    }
};

var fire_aa = func { setprop("sim/multiplay/generic/int[12]", 1); };
var stop_aa = func { setprop("sim/multiplay/generic/int[12]", 0); };

# --- FRONT DT MG (radista) ---
var FRONT_MG_H_MAX =  15.0;
var FRONT_MG_H_MIN = -15.0;
var FRONT_MG_V_MAX =  15.0;
var FRONT_MG_V_MIN =  -5.0;
var _front_h_timer = nil;
var _front_v_timer = nil;

setprop("sim/multiplay/generic/float[12]", 0);
setprop("sim/multiplay/generic/float[13]", 0);
setprop("sim/multiplay/generic/int[13]",   0);

var front_mg_h_step = func(deg) {
    var cur = getprop("sim/multiplay/generic/float[13]") or 0;
    var nxt = cur + deg;
    if (nxt > FRONT_MG_H_MAX) nxt = FRONT_MG_H_MAX;
    if (nxt < FRONT_MG_H_MIN) nxt = FRONT_MG_H_MIN;
    setprop("sim/multiplay/generic/float[13]", -nxt);
};
var front_mg_h_start = func(dir) {
    front_mg_h_step(dir);
    _front_h_timer = maketimer(STEP_INTERVAL, func { front_mg_h_step(dir); });
    _front_h_timer.start();
};
var front_mg_h_stop = func {
    if (_front_h_timer != nil) { _front_h_timer.stop(); _front_h_timer = nil; }
};

var front_mg_v_step = func(deg) {
    var cur = getprop("sim/multiplay/generic/float[12]") or 0;
    var nxt = cur + deg;
    if (nxt > FRONT_MG_V_MAX) nxt = FRONT_MG_V_MAX;
    if (nxt < FRONT_MG_V_MIN) nxt = FRONT_MG_V_MIN;
    setprop("sim/multiplay/generic/float[12]", nxt);
};
var front_mg_v_start = func(dir) {
    front_mg_v_step(dir);
    _front_v_timer = maketimer(STEP_INTERVAL, func { front_mg_v_step(dir); });
    _front_v_timer.start();
};
var front_mg_v_stop = func {
    if (_front_v_timer != nil) { _front_v_timer.stop(); _front_v_timer = nil; }
};

var front_mg_center = func {
    front_mg_h_stop(); front_mg_v_stop();
    var cur_h = getprop("sim/multiplay/generic/float[13]") or 0;
    var cur_v = getprop("sim/multiplay/generic/float[12]") or 0;
    if (math.abs(cur_h) > 0.01) {
        var dir_h = (cur_h > 0) ? -1 : 1;
        _front_h_timer = maketimer(STEP_INTERVAL, func {
            var v = getprop("sim/multiplay/generic/float[13]") or 0;
            if ((dir_h < 0 and v <= 0) or (dir_h > 0 and v >= 0)) {
                front_mg_h_stop();
                setprop("sim/multiplay/generic/float[13]", 0);
            } else {
                front_mg_h_step(dir_h);
            }
        });
        _front_h_timer.start();
    }
    if (math.abs(cur_v) > 0.01) {
        var dir_v = (cur_v > 0) ? -1 : 1;
        _front_v_timer = maketimer(STEP_INTERVAL, func {
            var v = getprop("sim/multiplay/generic/float[12]") or 0;
            if ((dir_v < 0 and v <= 0) or (dir_v > 0 and v >= 0)) {
                front_mg_v_stop();
                setprop("sim/multiplay/generic/float[12]", 0);
            } else {
                front_mg_v_step(dir_v);
            }
        });
        _front_v_timer.start();
    }
};

var fire_front_mg = func { setprop("sim/multiplay/generic/int[13]", 1); };
var stop_front_mg = func { setprop("sim/multiplay/generic/int[13]", 0); };

setprop("/bombable/player-faction", "A");

print("T-34 Weapon System load OK.");
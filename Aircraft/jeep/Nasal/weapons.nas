var masterarm = props.globals.getNode("controls/armament/master-arm");
var weapselected = props.globals.getNode ("sim/armament/weapon_selected");
var gun0 = props.globals.getNode("sim/armament/gun[0]/fire");
var gun1 = props.globals.getNode("sim/armament/gun[1]/fire");
var gun2 = props.globals.getNode("sim/armament/gun[2]/fire");

# var tracergun0 = props.globals.getNode("controls/armament/gun[0]/tracer");
# var tracergun1 = props.globals.getNode("controls/armament/gun[1]/tracer");
# var tracerevery = 20;
#  var times0 = 49;

var statgun0 = props.globals.getNode("sim/armament/gun[0]/serviceable");
var statgun1 = props.globals.getNode("sim/armament/gun[1]/serviceable");
var statgun2 = props.globals.getNode("sim/armament/gun[2]/serviceable");


setlistener("/controls/armament/trigger", func(n) {
  var stat = n.getValue();
  if	( stat ) {
    if ( masterarm.getValue() )  {
      if (statgun0.getValue() == 1) {
        gun0.setValue (1);
      }
      if (statgun1.getValue() == 1) {
        gun1.setValue (1);
      }
      if (statgun2.getValue() == 1) {
        gun2.setValue (1);
      }
    }
  } else {
    gun0.setValue (0);
    gun1.setValue (0);
    gun2.setValue (0);
  }
});




var gunflash0_trigger = props.globals.getNode("controls/armament/trigger", 0);
aircraft.light.new("sim/model/gun0/flash", [0.02, 0.024], gunflash0_trigger);

var gunflash1_trigger = props.globals.getNode("controls/armament/trigger", 0);
aircraft.light.new("sim/model/gun1/flash", [0.025, 0.029], gunflash1_trigger);

var gunflash2_trigger = props.globals.getNode("controls/armament/trigger", 0);
aircraft.light.new("sim/model/gun2/flash", [0.025, 0.029], gunflash2_trigger);

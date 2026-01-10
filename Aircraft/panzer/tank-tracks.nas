## Realistic tank track movement script
## By Skyop

var trackLoop = func
 {
 setprop("gear/gear[0]/track-pos-norm", getprop("gear/gear[0]/rollspeed-ms") * getprop("sim/time/delta-realtime-sec"));
 setprop("gear/gear[1]/track-pos-norm", getprop("gear/gear[1]/rollspeed-ms") * getprop("sim/time/delta-realtime-sec"));

 settimer(trackLoop, 0);
 }
setlistener("sim/signals/fdm-initialized", func
 {
 settimer(func
  {
  trackLoop();
  }, 2);
 });

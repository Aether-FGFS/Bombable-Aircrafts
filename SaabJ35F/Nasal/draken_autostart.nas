#Autostart (autostart)
#Opening fuel valve autostart (waiting_n1)
#System config. and autostart(start_systems)

var auto_gen=0;


# Opens fuel valve in autostart
 var waiting_n1 = func {
  if (verbose > 1) print("Autostart engaged");
  if (getprop("/engines/engine[0]/n1") < 5.2) settimer(waiting_n1, 1);
  else if (getprop("/engines/engine[0]/n1") < 27) {
    setprop("/controls/engines/engine[0]/cutoff", 0);
    settimer(waiting_n1, 1);
  } else {
    if (auto_gen == 1) {
      setprop("instrumentation/switches/generator/pos", 1);
      setprop("controls/electric/engine[0]/generator", 1);
      if (verbose > 1) print("Generator on");
      auto_gen=0;
      if (verbose > 0) print("Running");
    }
  }
 }
 
#Simulating autostart function
 var autostart = func {
  if (verbose > 0) print("Initializing Autostart");
  if (getprop("/velocities/groundspeed-kt") < 1e-3 and
      getprop("controls/electric/engine[0]/generator") == 0){
    setprop("/controls/engines/engine[0]/cutoff", 1);
    setprop("/controls/engines/engine[0]/starter", 1);
    settimer(waiting_n1, 1);
  }
 }

    
# Configure and autostart aircraft
 var start_systems = func {
   setprop("controls/electric/battery-switch", 1);
   if (verbose > 0) print("Battery on");
   #Canopy
   if (getprop("/controls/canopy/enabled") and 
       getprop("/controls/canopy/position-norm") == 0)
     canopy_operate();
   if (verbose > 0) print("Canopy closed");
   # Tanks and valves
   setprop("/fdm/jsbsim/propulsion/tank[4]/priority", 1);
   setprop("/fdm/jsbsim/propulsion/tank[5]/priority", 1);
   setprop("instrumentation/switches/fuel/pos", 1);
   setprop("/fdm/jsbsim/propulsion/afterburner-pump", 1);
   if (getprop("/consumables/droptanks")) 
       setprop("/instrumentation/switches/drop_selector/pos", 1);
   auto_gen=1;
   if (verbose > 0) print("Tanks and valves set");
   #Radio
   setprop("/instrumentation/fr21/pwr", 1);
   fr21_button_handlerAK("A");
   fr21_button_handler15("b1");
   if (verbose > 0) print("Radio on");
   if (getprop("/sim/time/sun-angle-rad") > 1.57) {
     setprop("instrumentation/switches/consol-light-knob/pos", 0.25);
     setprop("instrumentation/switches/nav-lights-setting", 1);
     setprop("instrumentation/switches/landing-light-left/pos", 1);
     setprop("instrumentation/switches/landing-light-right/pos", 1);
   } else {
     setprop("instrumentation/switches/consol-light-knob/pos", 0);
     setprop("instrumentation/switches/nav-lights-setting", 0);
     setprop("instrumentation/switches/landing-light-left/pos", 0);
     setprop("instrumentation/switches/landing-light-right/pos", 0);
   }
   nav_light_handler();   
   if (verbose > 0) print("Lights set");
   #Engine autostart
   autostart();
   #Clock ring
   setprop("instrumentation/clock/ring-pos", -(getprop("/instrumentation/clock/indicated-min")*6+3)); # 30 seconds ahead, length of start sequence
   #Radar
   setprop("instrumentation/radar/mode_select",1);
 }
 

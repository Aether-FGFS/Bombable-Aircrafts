#Included functions:
#Sound helper (sound_helper(name))
#Fuel control (fuel_handler)
#G watcher (g_watch)
#Autopilot settings (auto_setting(set))
#Handle droptanks (drophandle)
#Gear warning light (gear_watch, warning_on)
#Alt indicator watch (alt_watch)
#Autopilot locks (auto_settings)
#Canopy operation (canopy_operate)
#Light intensity setter (light_intens)
#Nav light handler (nav_light_handler, light_loop)
#Armament trigger (trigger_handler)
#Drag chute handler (chute_handler)
#Copy files for beacons and radio (file_copy)

 
 var gnegt=-1;
 var active_tank=0;
 var inactive_tank=3;
 var t1=0;
 var t2=3;

#Sound helper
# Triggers switch sound
# name is sound-large or sound-small
# that riggers different sounds.
 var sound_helper = func(name) {
   var sp = "/instrumentation/switches/"~name;
   setprop(sp,1);
   var timer = maketimer(0.1, func(){
     setprop(sp,0); });
   timer.singleShot = 1;
   timer.start();
 }
 

#Fuel handling helper function
 var choose_tank = func(tank1,tank2) {
   var ff=getprop("engines/engine[0]/fuel-flow_pph") or 0;
   if (ff > 17000) {
     setprop("/fdm/jsbsim/propulsion/tank["~tank1~"]/collector-valve", 1);
     setprop("/fdm/jsbsim/propulsion/tank["~tank2~"]/collector-valve", 1);
   } else {
       var atl=getprop("consumables/fuel/tank["~active_tank~"]/level-lbs");   
       if (atl+50 < getprop("consumables/fuel/tank["~inactive_tank~"]/level-lbs") or atl < 1) {
         var tmp=active_tank;
         active_tank=inactive_tank;
         inactive_tank=tmp;
       }
     setprop("/fdm/jsbsim/propulsion/tank["~active_tank~"]/collector-valve", 1);
     setprop("/fdm/jsbsim/propulsion/tank["~inactive_tank~"]/collector-valve", 0);     
   }
 }

 var use_drop = func {
   if (getprop("/instrumentation/switches/drop_selector/pos") and
      (getprop("/consumables/fuel/tank[1]/empty") != 1 or 
       getprop("/consumables/fuel/tank[2]/empty") != 1)) {
     setprop("/fdm/jsbsim/propulsion/tank[0]/collector-valve", 0);
     setprop("/fdm/jsbsim/propulsion/tank[3]/collector-valve", 0);
      t1=1;
      t2=2;
      active_tank=1;
      inactive_tank=2;
      setprop("/consumables/fuel/using-droptanks", 1);
      if (verbose > 0 and getprop("/consumables/fuel/using-droptanks")) 
         print("Fuel in droptanks. Using droptanks.");
   } else use_internal();   
 }
 
 var use_internal = func { 
   setprop("/fdm/jsbsim/propulsion/tank[1]/collector-valve", 0);
   setprop("/fdm/jsbsim/propulsion/tank[2]/collector-valve", 0);
   setprop("/consumables/fuel/using-droptanks", 0);
   t1=0;
   t2=3;
   active_tank=0;
   inactive_tank=3;
   if (verbose > 1) print("Using internal tanks.");
 }
 
#Fuel handling
 var fuel_handler = func {
   #Switches beteeen external and internal tanks when external empties
   if (getprop("/consumables/fuel/using-droptanks")) {
      if (verbose > 1) print("Using droptanks, checking fuel status");
      if (getprop("/consumables/fuel/tank[1]/empty") and 
          getprop("/consumables/fuel/tank[2]/empty")) {
         use_internal();
         if (verbose > 0) {
            print("Droptanks empty switched on internal.");
         }
      }
   }
   choose_tank(t1,t2);
   # Sets fuel gauge needles rotation
   if (getprop("/consumables/fuel/using-droptanks")) {
       setprop("/instrumentation/fuel/needleF_rot", 
          getprop("/consumables/fuel/tank[1]/level-lbs")*0.248628692);
       setprop("/instrumentation/fuel/needleB_rot", 
          getprop("/consumables/fuel/tank[2]/level-lbs")*0.248628692);
   } else {
       setprop("/instrumentation/fuel/needleF_rot", 
          getprop("/consumables/fuel/tank[0]/level-lbs")*0.097396697);
       setprop("/instrumentation/fuel/needleB_rot", 
          getprop("/consumables/fuel/tank[3]/level-lbs")*0.097396697);
   }
   var ltl = 1;
   var ftl = 1;
   #FT_light check
   if ((getprop("systems/electrical/outputs/battery") or 0) > 20) {
     if (getprop("/consumables/droptanks")) {
       if (getprop("/instrumentation/switches/drop_selector/pos") and 
           getprop("/instrumentation/switches/fuel/pos")) 
         ftl=0;
       else if (getprop("/consumables/fuel/tank[1]/empty") and 
                getprop("/consumables/fuel/tank[2]/empty") and 
                getprop("/gear/gear[0]/wow") == 0)
         ftl=0;
       else ftl=1;
     } else ftl=0;
     #LT light check
     if (getprop("/instrumentation/switches/fuel/pos") and
         getprop("fdm/jsbsim/propulsion/afterburner-pump"))
       ltl=0;
     else ltl=1; 
   } else {
     ftl=0;
     ltl=0;
     if (verbose > 1) print("No battery FT LT.");
   }
   setprop("/instrumentation/fuel/FT_light", ftl);
   setprop("/instrumentation/fuel/LT_light", ltl);
   settimer(fuel_handler, 0.2);
 }

#G-watcher for fuel and G-gauge
 var g_watch = func {
    var g = getprop("/accelerations/pilot-gdamped") or 1;
    if (g > getprop("/instrumentation/g-max")) {
       setprop("/instrumentation/g-max", g < 11.5 ? g : 11.5);
       if (verbose > 1) print("G-max rised");
    }
    if (gnegt < 0) {
       if (g < 0) {
          gnegt= getprop("/sim/time/elapsed-sec") or 0;
          if (verbose > 1) print("Detected negative G");
       }
    } else {
       if (g > 0) gnegt = -1;
       if (verbose > 1) print("End of negative G");
    }
    settimer(g_watch, 0.1);
 }


#generator switch handler 1=down, 0=up
var generator_switch = func(press) {
  if (press) {
    if (getprop("controls/electric/engine/generator")) {
      setprop("instrumentation/switches/generator/pos",0);
      setprop("controls/electric/engine/generator",0);
    } else {
      setprop("instrumentation/switches/generator/pos",1);
      if (getprop("engines/engine[0]/n1") > 27) 
      setprop("controls/electric/engine/generator",1);        
    }
  } else setprop("instrumentation/switches/generator/pos", getprop("controls/electric/engine/generator"));
}

#Drop tank handling helper functions

 var air_caution = func {
   setprop("consumables/fuel/pressure-fail", 1-getprop("consumables/fuel/pressure-fail"));
   if (getprop("consumables/fuel/pressure-fail") == 1) settimer(air_caution, 0.5);
 }
 
 
 var drop = func {
    setprop("/fdm/jsbsim/propulsion/tank[1]/collector-valve", 0);
    setprop("/fdm/jsbsim/propulsion/tank[2]/collector-valve", 0);
    setprop("fdm/jsbsim/inertia/pointmass-weight-lb", 0);
    setprop("/consumables/fuel/tank[1]/level-lbs", 0);
    setprop("/consumables/fuel/tank[2]/level-lbs", 0);
    setprop("/consumables/fuel/using-droptanks", 0);
    setprop("/consumables/droptanks", 0);
    use_internal();
    if (verbose > 0)print("Droptanks shut off and ejected. Using internal fuel");
    air_caution();
 }

 var add = func {
    setprop("/consumables/fuel/tank[1]/level-lbs", 942);
    setprop("/consumables/fuel/tank[2]/level-lbs", 942);
    setprop("fdm/jsbsim/inertia/pointmass-weight-lb", 200);
    setprop("/consumables/droptanks", 1);
    use_drop();
    air_caution();
 }

#Handle droptanks
 var drophandle = func(pilot) {
    if (pilot) {
       if (getprop("/gear/gear[0]/wow") > 0.05) {
         if (verbose > 0) print("Can not eject droptanks on ground"); 
         return;
       }
       if (getprop("/consumables/droptanks")) {
         setprop("/rendering/submodels/dropL", 1);
         setprop("/rendering/submodels/dropR", 1);
       }
       drop();
    } else {
       if (getprop("/velocities/groundspeed-kt") < 1e-3 and 
              getprop("/instrumentation/switches/drop_selector/pos") == 0) {
          if (getprop("/consumables/droptanks")) {
            drop(); 
            screen.log.write("Droptanks shut off and removed");
          } else {
            add();
            screen.log.write("Droptanks attached and connected");
          }
       } else {
          screen.log.write("Can not handle droptanks unless fuel D/T valve closed and stationary.");
       }
    }
 }

# We must establish these aliases only after the FDM is initialized:
setlistener ("/sim/signals/fdm-initialized", func (node) {
  if (node != nil and node.getValue() != 0) {
    for (var j = 0; j < 4; j += 1) {
      props.globals.getNode ("fdm/jsbsim/propulsion/tank[" ~ j ~ "]/collector-valve", 0)
                   .alias   ("consumables/fuel/tank[" ~ j ~ "]/selected");
    }
  }
});

#Gear warning light
 var warning_on = func {
     setprop("/instrumentation/gear_warning", 0);
     settimer(gear_watch, 0.8);
 }

 var gear_watch = func {
   var gp = getprop("/gear/gear[0]/position-norm");
   if ((gp > 0 and gp < 1) or (gp == 0 and getprop("instrumentation/airspeed-indicator/indicated-speed-kt") < 243 and
       getprop("/instrumentation/altimeter/indicated-altitude-ft") < 4700 and
       getprop("/controls/engines/engine[0]/throttle") < 0.85)) {
          setprop("/instrumentation/gear_warning", 1);
          settimer(warning_on, 0.5);
   } else {
      setprop("/instrumentation/gear_warning", 0);
      settimer(gear_watch, 2);
   }
 }

#Alt indicator watch
 var alt_watch = func {
   var target=getprop("/autopilot/settings/target-altitude-ft");
   if (getprop("/autopilot/locks/altitude") and getprop("controls/electric/engine[0]/generator") == 1) {
     var h=getprop("/instrumentation/altimeter/indicated-altitude-ft");
     var dh=7765/getprop("/systems/static/pressure-inhg");
     var vs=getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
     vs = vs < 0 ? -vs : vs ;
     if (h-target>-dh and h-target<dh and vs < 600 and !getprop("/autopilot/altoff") ) 
        setprop("/instrumentation/alt_indicator", 1);
     else setprop("/instrumentation/alt_indicator", 
                  1- getprop("/instrumentation/alt_indicator"));
     settimer(alt_watch, 0.5);
   } else {
     setprop("/instrumentation/alt_indicator", 0);
     settimer(alt_watch, 3);
   }
 }

#Handels autopilot locks
var auto_setting = func(set) {
  if (getprop("/autopilot/enabled")) {
    if (set == "alt") {
      if (getprop("/autopilot/locks/altitude"))  setprop("/autopilot/locks/altitude", 0);
      else {
        setprop("/autopilot/locks/damp", 1);
        setprop("/autopilot/locks/attitude", 0);
        setprop("/autopilot/locks/altitude", 1);
      }
    }
    else if (set == "att") {
      if (getprop("/autopilot/locks/attitude"))  setprop("/autopilot/locks/attitude", 0);
      else {
        setprop("/autopilot/locks/damp", 1);
        setprop("/autopilot/locks/altitude", 0);
        setprop("/autopilot/locks/attitude", 1);
      }
    }
    else if (set == "dmp") {
      if (getprop("/autopilot/locks/damp") == 0) {
        setprop("/autopilot/locks/damp", 1);
        setprop("/fdm/jsbsim/fcs/yaw-damper-enable", 1);
        setprop("fdm/jsbsim/fcs/pitch-damper-enable", 1);
      } else {
        setprop("/autopilot/locks/damp", 0);
        setprop("/fdm/jsbsim/fcs/yaw-damper-enable", 0);
        setprop("fdm/jsbsim/fcs/pitch-damper-enable", 0);
        setprop("/autopilot/locks/altitude", 0);
        setprop("/autopilot/locks/attitude", 0);
      }
    }
  }
}

var autoOnOff = func(n) {
  var on = n.getValue();
  print(on);
  if (on == 1) {
    setprop("/autopilot/locks/damp", 1);
    setprop("/fdm/jsbsim/fcs/yaw-damper-enable", 1);
    setprop("fdm/jsbsim/fcs/pitch-damper-enable", 1);
  } else {
    setprop("/autopilot/locks/damp", 0);
    setprop("/fdm/jsbsim/fcs/yaw-damper-enable", 0);
    setprop("fdm/jsbsim/fcs/pitch-damper-enable", 0);
    setprop("/autopilot/locks/altitude", 0);
    setprop("/autopilot/locks/attitude", 0);
  }
} 

#Canopy operation
var canopy_operate = func {
  sound_helper("sound-large");
  if (getprop("/controls/canopy/position-norm") > 0) {
    canopy.toggle();
    setprop("/controls/canopy/control", 1-getprop("/controls/canopy/control"));
  } else {
    if (canopy_opening == 0) {
      if (getprop("/controls/canopy/enabled")) setprop("/controls/canopy/enabled", 0);
      else {
        setprop("/controls/canopy/enabled", 1);
        canopy_opening=1;
      } 
    } else {
      canopy.toggle();
      setprop("/controls/canopy/control", 1-getprop("/controls/canopy/control"));
      canopy_opening=0;
    }
  }
}

# Switch LT fuel valve
 var lt_switch_toggle = func {
   var new_pos = 1 - getprop("instrumentation/switches/fuel/pos");
   setprop("/fdm/jsbsim/propulsion/tank[4]/priority", new_pos);
   setprop("/fdm/jsbsim/propulsion/tank[5]/priority", new_pos);
   setprop("instrumentation/switches/fuel/pos", new_pos);
   fuel_cover.toggle();   
 } 

# Drag chute handling
# chute_state: 0=no drag chute, 1=loaded, 2=deployed, 3=dropped
 var chute_handler = func {
   if (getprop("controls/dragchute/chute-lever") == 0 and 
       getprop("/controls/engines/engine[0]/throttle") < 0.85) {
     setprop("controls/dragchute/chute-lever", 1);
     var timer = maketimer(0.5, func(){
       setprop("controls/dragchute/chute-lever", 0);
       });
     timer.singleShot = 1;
     timer.start();
     var cs=getprop("/instrumentation/chute_state");
     if (cs==1) {
       var timer = maketimer(3, func() {
           setprop("/instrumentation/chute_state", 2);
           setprop("/fdm/jsbsim/fcs/drag-chute-deployed", 1);
           setprop("/controls/dragchute/chute-cap",1);
         });
       timer.singleShot = 1;
       timer.start();       
     } else if (cs==2) {
       setprop("/instrumentation/chute_state", 3);
       setprop("/fdm/jsbsim/fcs/drag-chute-deployed", 0);
       #TODO problem dropping at too low speed or (maybe) broken/unserviceable (see DrakenJ35F)
     }
   } else {
     setprop("controls/dragchute/chute-lever", 0);
   }
 }

# Loads chute on ground 
 var chute_loader = func {
   if (getprop("/velocities/groundspeed-kt") < 1e-3 and getprop("/engines/engine/running")==0) {
     setprop("/instrumentation/chute_state", 2);
     setprop("controls/dragchute/chute-lever", 0);
     screen.log.write("Drag chute loaded");
   } else screen.log.write("You need to be stationary with engine off to load chute");
 }

#Light intensity setter
var light_intens = func {
  var sa = getprop("/sim/time/sun-angle-rad") or 1;
  var ns = getprop("/controls/lighting/nav-lights-int") or 0;
  var i= sa > 1.58 ? sa/4+0.315 : sa/10+0.443 ;
  setprop("/rendering/lights-factor", i);
  setprop("/rendering/nav-lights-factor", i*ns);
  settimer(light_intens, 0.5);
}
 
#Nav light handler
var light_loop=func {
  setprop("instrumentation/nav-lights", 1-getprop("instrumentation/nav-lights"));
}
var light_timer =maketimer(1, light_loop);

var nav_light_handler = func {
  var ins=getprop("instrumentation/switches/nav-lights/pos");
  if (ins==3) ins=0; else ins=ins+1;
  setprop("instrumentation/switches/nav-lights/pos", ins);
  if (ins != 1 and light_timer.isRunning) light_timer.stop(); 
  if (ins==0) { #AV
    setprop("instrumentation/nav-lights", 0);
    setprop("controls/lighting/nav-lights-int", 0);
  }
  if (ins==1) { #EL
    setprop("instrumentation/nav-lights", 1);
    setprop("controls/lighting/nav-lights-int", 1);
  }
  if (ins==2) { #BLINK
    light_timer.start();
    setprop("controls/lighting/nav-lights-int", 1);
  }
  if (ins==3) { #HALV
    setprop("instrumentation/nav-lights", 1);
    setprop("controls/lighting/nav-lights-int", 0.25);
  }
}

#Armament trigger handling
var armamentprops = ["", "ai/submodels/ADEN", "", "", ""];
var armament_trigger_handler = func (trigged) {
  var ars=getprop("controls/armament/selected");
  if (ars !=1) return; #TODO other weapons
  if (trigged.getValue() == 1 and getprop("gear/gear[0]/position-norm") == 0) {
      setprop(armamentprops[ars], 1);
  } else setprop(armamentprops[ars], 0);
}

setlistener("/controls/armament/trigger", armament_trigger_handler, 1,0);

#RAT handler

var rat_timer = maketimer(0.05, func(){
  var r=getprop("engines/engine[0]/RAT");
  var rnorm=getprop("engines/engine[0]/RAT-angle-norm");
  if ( r == 1 and rnorm<1) rnorm=rnorm+0.025;
  if ( r == 0 and rnorm>0) rnorm=rnorm-0.025;
  rnorm=math.clamp(rnorm,0,1);
  setprop("engines/engine[0]/RAT-angle-norm", rnorm);
  if (r==rnorm) rat_timer.stop();  
});

setlistener("engines/engine[0]/RAT", func {rat_timer.start();}, 1,0);

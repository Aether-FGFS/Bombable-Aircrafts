#Included functions:
#Rain vector loop (splash_vec_loop)
#Copy files for beacons and radio (file_copy)
# Init systems and avionics
  
 #Rain effect speed loop
var splash_vec_loop = func(){
    var airspeed = getprop("/velocities/airspeed-kt");

    var airspeed_max = 120;

    if (airspeed > airspeed_max) {
        airspeed = airspeed_max;
    }

    airspeed = math.sqrt(airspeed / airspeed_max);

    var splash_x = -0.1 - 2 * airspeed;
    var splash_y = 0.0;
    var splash_z = 1.0 - 1.35 * airspeed;

    setprop("/environment/aircraft-effects/splash-vector-x", splash_x);
    setprop("/environment/aircraft-effects/splash-vector-y", splash_y);
    setprop("/environment/aircraft-effects/splash-vector-z", splash_z);

    settimer(func(){
        splash_vec_loop();
    }, 0.5);
}

splash_vec_loop();

#Copies radio and nav files to Export if first time.
 var file_copy = func {
  var path=getprop('/sim/fg-home')~"/Export/SaabJ35F-Fr21.txt";
  if (call(io.readfile, [path], nil, nil, var err=[]) == nil){
    file_cont = io.readfile(getprop('/sim/aircraft-dir')~"/Fr21.txt");
    var file = io.open(path, "w");
    io.write(file, file_cont);
    io.close(file); 
  }
  var path=getprop('/sim/fg-home')~"/Export/SaabJ35F-Beacons.txt";
  if (call(io.readfile, [path], nil, nil, var err=[]) == nil){
    file_cont = io.readfile(getprop('/sim/aircraft-dir')~"/beacons.txt");
    var file = io.open(path, "w");
    io.write(file, file_cont);
    io.close(file); 
  }
}

#Temperature loop for frost/fog
var temp=Temp.new();
temp.init((getprop("environment/temperature-degc") or 0));
   
######### Init objects etc ###############
#Copy file to Export if first time
file_copy();
#Init Canopy movement
var canopy = aircraft.door.new("/controls/canopy/", 5);
var canopy_opening = 1 - getprop("/controls/canopy/enabled");
#Prepare covers
var fuel_cover = aircraft.door.new ("/controls/fuel_cover/", 0.4);
var battery_cover = aircraft.door.new ("/controls/battery_cover/", 0.4);
#Liveries
aircraft.livery.init("Aircraft/SaabJ35F/Model/Liveries");
print("Liveries init");

#Electric system
var el = System_P.new("Systems/electric.txt");
el.init();
print("Electric ... Check");


#Clock
var clock = Clock.new(SaabJ35F.verbose);        
setlistener("/instrumentation/clock/indicated-sec", func { clock.update();}, 0, 0);
setlistener("/instrumentation/clock/clk-mode", func(node) { clock.changemode(node.getValue()); }, 0, 0);
setlistener("/instrumentation/clock/stopw-pressed", func { clock.stopwchange();},0,0);
if (SaabJ35F.verbose >0) print("Started clock");

#Fr21 radio
var fr21=Fr21.new(SaabJ35F.verbose);

var fr21_manual_handler= func(unit) {
  fr21.manual_handler(unit);
}

var fr21_button_handlerAK= func(btn) {
  fr21.button_handlerAK(btn);
}

var fr21_button_handler15= func(btn) {
  fr21.button_handler15(btn);
}

setlistener("/instrumentation/fr21/mode", func(node) { fr21.change_mode(node.getValue()); }, 0, 0);
if (SaabJ35F.verbose >0) print("Radio ... Check");

#AHK
var ahk = AHK.new(SaabJ35F.verbose);
setlistener("/instrumentation/AHK/mode", func(node) { ahk.set_AHK_mode(node.getValue()); }, 0, 0);

#Caution panel
setlistener("/nasal/canvas/loaded", func {
  var panel = Caution_panel.new();
  panel.update();
  if (SaabJ35F.verbose >0) print("Caution Panel ... Check");
}, 1);

#PN59 Navradio
var nav = NavRadio.new(SaabJ35F.verbose);
setlistener("autopilot/settings/plane", func(node) { nav.plane_change(node.getValue()); }, 0,1);
setlistener("instrumentation/navradio/mode", func(node) { nav.set_nav_mode(node.getValue()); }, 1,1); 
if (SaabJ35F.verbose >0) print("Navigation ... Check");

var set_beacon = func () {
  nav.set_beacon();
}

#PN-793 IFF
var iff=IFF.new(SaabJ35F.verbose);
setlistener("controls/iff/pwr",func(node) { iff.iff_pwr(node.getValue()); },0,0);

#Radar
setlistener("/nasal/canvas/loaded", func {
  var scope = radar.new(SaabJ35F.verbose);
  setlistener("/controls/radar/mode", func() { scope.mode_select(); }, 0, 0);
  setlistener("/controls/navradio/mode", func() { scope.mode_select(); }, 0, 0);
  scope.update();
}, 1);
if (SaabJ35F.verbose >0) print("Radar...Check");

#STRIL
var stril=Stril.new(SaabJ35F.verbose);
setlistener("/controls/navradio/mode", func(node) { stril.modehandler(node.getValue()); }, 0, 0);

var stril_message= func () {
  stril.transmit();
}

#Other handlers etc
setprop("/instrumentation/g-max", 0);
use_drop();
fuel_handler();
setlistener("/instrumentation/switches/drop_selector/pos", use_drop, 0, 0);
if (SaabJ35F.verbose >0) print("Fuel ... Check");
g_watch();
if (SaabJ35F.verbose >0) print("G-gauge ... Check");
gear_watch();
#landinglight_check();
if (SaabJ35F.verbose >0) print("Gears ... Check");
nav_light_handler();
light_intens();
settimer(alt_watch, 3);
setlistener("/autopilot/enabled", autoOnOff, 0, 0);
if (SaabJ35F.verbose >0) print("Autopilot ... Check");
setlistener("controls/gear/brake-parking", func {sound_helper("sound-large");}, 0, 0);



  
var Stril= {

  new: func(verb) {
    var m={parents:[Stril] };
    m.verbose=verb;
    m.timer=nil;
    m.init();
    m.first=true;
    m.text="";
    return m;
  },
  
  init: func() {
    me.timer=maketimer(1, me, me.uppdate);
  },
  
  modehandler: func(mode) {
    if (mode==2) {
      if (me.verbose>0) print("Started STRIL");
      fgcommand("activate-flightplan", props.Node.new({"activate": 1}));
      if (me.verbose>0) print("Target:" ~ getprop("instrumentation/navradio/stril-target"));
      me.timer.start();
    }
    else {
      me.timer.stop();
      me.popup=false;

    }
  },
  
  uppdate: func() {
    var starget=getprop("instrumentation/navradio/stril-target");
    if (starget=="Route") {
      setprop("sim/multiplay/target/bearing", getprop("autopilot/route-manager/wp[0]/bearing-deg") or 0);
      setprop("sim/multiplay/target/course", getprop("autopilot/route-manager/wp[0]/bearing-deg") or 0);
      setprop("sim/multiplay/target/dist", getprop("autopilot/route-manager/wp[0]/dist") or 0);
      setprop("sim/multiplay/target/alt", getprop("/autopilot/route-manager/cruise/altitude-ft") or 0);
    } else me.targetData();
  },
  
  targetData: func() {
    var self = geo.aircraft_position();
    foreach (var mp; multiplayer.model.list) {
      if(mp.callsign==getprop("instrumentation/navradio/stril-target")) {
	      var n = mp.node;
	      var x = n.getNode("position/global-x").getValue();
	      var y = n.getNode("position/global-y").getValue();
	      var z = n.getNode("position/global-z").getValue();
	      var ac = geo.Coord.new().set_xyz(x, y, z);
	      var distance = nil;
	      call(func distance = self.distance_to(ac), nil, var err = []);
	      if ((size(err))or(distance==nil)) {
	        # Oops, have errors. Bogus position data (and distance==nil).
	        print("Received invalid position data: " ~ debug._error(mp.callsign));
	        setprop("sim/multiplay/target/dist",0);
	        setprop("sim/multiplay/target/course",0);
	        setprop("sim/multiplay/target/bearing",0);
	        setprop("sim/multiplay/target/alt",0);
	        return;
	      }
	      setprop("sim/multiplay/target/bearing",self.course_to(ac));
	      setprop("sim/multiplay/target/dist", distance/1852);
	      setprop("sim/multiplay/target/course",n.getNode("orientation/true-heading-deg").getValue());
	      setprop("sim/multiplay/target/alt", n.getNode("position/altitude-ft").getValue());
        me.text=sprintf("Distance %.1f Course %.0f Speed %.0f",
          getprop("sim/multiplay/target/dist")*1.852,
          getprop("sim/multiplay/target/course"),
          n.getNode("velocities/true-airspeed-kt").getValue()*1.852);
        if (me.first) {
          me.transmit();
          me.first=false;
        }
	    }
	    return;
	  }   
  },
  
  transmit: func() {
    setprop("/sim/messages/pilot", me.text);
  },
};


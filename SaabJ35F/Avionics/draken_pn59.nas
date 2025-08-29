 var NavRadio = { 
  
  #Nav settings and beacons
  #Modes:
  # 0=Fran, 1=Forv., 2=Stril, 3=Strid, 4=NAVRIKTN(NDB)
  # 5=Nav 400 (VOR 400 km), 6=Nav 40 (VOR 40 km)
  # 7=Landn 40 (VOR 40 km, appr.), 8=Barbro (ILS)
  
  new: func(verb) {
    var m={parents:[NavRadio] };
    m.verbose=verb;
    m.letters=["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P"];
    m.nav_head="";
    m.nav_dir="";
    m.nav_dis="";
    m.nav_gsa="";
    m.nav_gsd="";
    m.plane_set=0;
    m.old_alt=300;
    m.beacon = { code: "", type: "", frq: 0, note: ""};
    m.new_beacon = func(bv) {
      var b = {parents:[m.beacon] };
      b.code=bv[0];
      b.type=bv[1];
      b.frq=num(bv[2]);
      b.note=bv[3];
      return b;
      
    }
    m.beacons = [];
    m.active=-1;
    m.timer=nil;
    m.init();
    return m;
  },

  init: func {
    if (me.verbose >0) print("Reading beacons");
    var fh = io.open(getprop('/sim/fg-home')~"/Export/SaabJ35F-Beacons.txt", "r");
    var b="";
    while (b != nil) {
      b = io.readln(fh);
      if (b != nil ) {
        if (b[0] != 35) {
          append(me.beacons, me.new_beacon(split(",", b)));
          if (me.verbose >1) print("Adding: "~b);
        }
      }
    }
    io.close(fh);
    me.timer=maketimer(0.1,me, me.update_nav);
    me.timer.start(); 
  },

  set_beacon: func {
    var md=(getprop("/controls/navradio/mode") or 0);
    if (md<4) return;
    me.active=-1;
    if (md < 7) {
      var cd=me.letters[getprop("/instrumentation/navradio/anita1")]~
              me.letters[getprop("/instrumentation/navradio/anita2")];
      forindex (i; me.beacons) {
        if (substr(me.beacons[i].code,0,2) == cd) {
          if (me.verbose >1) print("Selecting "~me.beacons[i].code);
          me.active=i;
          break;
        }
      }
      #VOR/DME
      if (me.beacons[i].type =="VOR") {
        setprop("/instrumentation/nav/frequencies/selected-mhz", me.beacons[i].frq);
        me.nav_head="/instrumentation/nav/radials/reciprocal-radial-deg";
        me.nav_dir="/instrumentation/nav/radials/reciprocal-radial-deg";
        me.nav_dis="/instrumentation/nav/nav-distance";
        me.nav_gsa="";
        me.nav_gsd="";
      #NDB
      } else if (me.beacons[i].type =="NDB") {
        setprop("/instrumentation/adf/frequencies/selected-khz", me.beacons[i].frq);
        me.nav_head="/instrumentation/adf/indicated-bearing-deg";
        me.nav_dir="/instrumentation/adf/indicated-bearing-deg";
        setprop("/instrumentation/navradio/dis", 0);
        me.nav_dis="";
        me.nav_gsa="";
        me.nav_gsd="";
      }      
    } else {
      #ILS
      var cd=me.letters[getprop("/instrumentation/navradio/anita1")]~
              me.letters[getprop("/instrumentation/navradio/anita2")]~
              me.letters[getprop("/instrumentation/navradio/barbro")];
      forindex (i; me.beacons) {
        if (me.beacons[i].code == cd and me.beacons[i].type =="ILS") {
          if (me.verbose >1)  print("Selecting "~me.beacons[i].code);
          me.active=i;
          setprop("/instrumentation/nav/frequencies/selected-mhz", me.beacons[i].frq);
          me.nav_head="/instrumentation/nav/radials/reciprocal-radial-deg";
          me.nav_dir="/instrumentation/nav/radials/reciprocal-radial-deg";
          me.nav_dis="/instrumentation/nav/nav-distance";
          me.nav_gsa="/instrumentation/nav/gs-needle-deflection-norm";
          me.nav_gsd="/instrumentation/nav/heading-needle-deflection-norm";
          break;
        }
      }  
    }
    if (me.active==-1) {
      if (me.verbose >1)  print("No beacon found");
      me.nav_head="";
      me.nav_dir="";
      me.nav_dis="";
      me.nav_gsa="";
      me.nav_gsd="";
    } else {
      if (me.verbose >0) print("Selected "~me.beacons[i].note);
      gui.popupTip("Selected "~me.beacons[i].note); 
    } 
  },


  # 0=Off, 1=preselected, 2=stril, 3=combat, 4=direction, 5= nav 400 km, 6=nav 40 km, 7=landing 40 km, 8=Barbro
  # Guides:
  # Preselected: course set by course selector, AHK altitude change
  # Stril: course as autopilot route, AHK distance and height to for the leg
  # Combat: course set by course selector, AHK altitude change (Same as preselected) TODO something more useful
  # Direction: Direction to nav beacon selected (Anita), AHK altitude change
  # Nav 400 km: Direction and distance to nav beacon selected (Anita). AHK distance 0-400 km and altitude change
  # Nav 40 km: Direction and distance to nav beacon selected (Anita). AHK distance 0-40 km and altitude change
  # Landing: Direction and distance to nav beacon selected Barbro. AHK distance and distance to touch down
  # Barbro: Direction to Barbro beacon, AHK distance 0-40 km and altitude change
  
  set_nav_mode: func(md) {
    var ahk_mode=0;
    if (md != 2) setprop("autopilot/route-manager/active", 0);
    if (md==0) {
      me.nav_head="/instrumentation/heading-indicator/heading-bug-deg";
      me.nav_dir="";
      me.nav_dis="";
      me.nav_gsa="";
      me.nav_gsd="";
      ahk_mode=0;
    } else if (md==1) {
      me.nav_head="/instrumentation/heading-indicator/heading-bug-deg";
      me.nav_dir="/instrumentation/heading-indicator/heading-bug-deg";
      me.nav_dis="";
      me.nav_gsa="";
      me.nav_gsd="";
      ahk_mode=1;  
    } else if (md==2) {
        me.nav_head="sim/multiplay/target/course";
        me.nav_dir="sim/multiplay/target/bearing";
        me.nav_dis="sim/multiplay/target/dist";
        me.nav_gsa="sim/multiplay/target/alt";
        me.nav_gsd="";
        ahk_mode=5;  
    } else if (md==3) {
      me.nav_head="/instrumentation/heading-indicator/heading-bug-deg";
      me.nav_dir="/instrumentation/heading-indicator/heading-bug-deg";
      me.nav_dis="";
      me.nav_gsa="";
      me.nav_gsd="";
      ahk_mode=1;  
    } else if (md==4) {
      ahk_mode=1;  
    } else if (md==5) {
      ahk_mode=4;  
    } else if (md==6) {
      ahk_mode=3;  
    } else if (md==7) {
      ahk_mode=2;  
    } else if (md==8) {
      ahk_mode=6;  
    }
    setprop("/instrumentation/AHK/mode", ahk_mode);
    if (md>=4) me.set_beacon();
  },

  calc_plane_gsa: func(d) {
    var h=getprop("instrumentation/altimeter/pressure-alt-ft")*0.304;
    var gh=0;
    if (d>19000) {
      gh=1000+(d-19000)*0.1391; # 8 deg
      setprop("/instrumentation/navradio/plane_alt", math.clamp((h-gh)/(d-7200)*16.4, -1,1)); #1 =3.5 deg avvikelse
    } else {
      gh=math.max(d*0.05234,50); # 3 deg
      setprop("/instrumentation/navradio/plane_alt", math.clamp((h-gh)/d*19.1, -1,1)); #1 =3.0 deg avvikelse
    }
    setprop("autopilot/settings/target-altitude-m", math.clamp(gh,300,math.max(h,300)));
    me.nav_gsa="/instrumentation/navradio/plane_alt";  
  },

  update_nav: func {
    var md=(getprop("/controls/navradio/mode") or 0);
    if (md == 0) {
      setprop("/instrumentation/navradio/head", getprop(me.nav_dir) or 0);
      setprop("/instrumentation/navradio/dir", 0);
      setprop("/instrumentation/navradio/dis", 0);
      setprop("/instrumentation/navradio/gs_alt", 0);
      setprop("/instrumentation/navradio/gs_dir", 0);
    } else {
      if (me.nav_dir != "") {
        #ADF gives bearing relative to aircraft the others compass-bearing
        if (me.beacons[me.active].type=="NDB" and md > 3) {
          var d=getprop(me.nav_dir) or 0;
          if (d>180) d=d-360;
          d=d+getprop("instrumentation/heading-indicator/indicated-heading-deg");
          if (d<0) d=d+360;
          else if (d>360) d=d-360;
          setprop("/instrumentation/navradio/head", d);
          setprop("/instrumentation/navradio/dir", d);
        } else {
          setprop("/instrumentation/navradio/head", getprop(me.nav_head) or 0);
          setprop("/instrumentation/navradio/dir", getprop(me.nav_dir) or 0);
        }
      }
      if (me.nav_dis != "") {
        var md=getprop("/controls/navradio/mode");
        if (getprop("autopilot/settings/plane") ==1 and (md==5 or md==6)) me.calc_plane_gsa(getprop(me.nav_dis));
        setprop("/instrumentation/navradio/dis", getprop(me.nav_dis) or 0);
      }
      if (me.nav_gsa != "") setprop("/instrumentation/navradio/gs_alt", getprop(me.nav_gsa) or 0);
      if (me.nav_gsd != "") setprop("/instrumentation/navradio/gs_dir", getprop(me.nav_gsd) or 0);
    }
  },

  plane_change: func(p) {
    if (me.plane_set == 0 and pc==1) me.old_alt=getprop("autopilot/settings/target-altitude-m");
    if (me.plane_set == 1 and pc==0) setprop("autopilot/settings/target-altitude-m", me.old_alt);
    me.plane_set=pc;
  },

};



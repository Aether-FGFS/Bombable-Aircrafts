
var AHK = {

  #AHK functions

  #Modes: NOLLA=0, HOJDANDR=1, LANDA=2, AVST. 40=3, AVST. 400=4, NYTT MAL=5, BARBRO=6

    new: func(verb) {
        var m = { parents:[AHK]};
        m.verbose=verb;
        #Running mean vectors
        m.dv = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        m.av = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
        #Conversion table AS to GS
        m.factor = 
        [ [-1000, 1],
          [0, 1],
          [5000, 1.11],
          [10000, 1.21],
          [15000, 1.29],
          [20000, 1.41],
          [25000, 1.54],
          [30000, 1.72],
          [36000, 2.00],
          [40000, 2.22],
          [50000, 2.86],
          [60000, 3.63],
          [70000, 4.44],
          [100000, 13]];
          m.mode=0;
          m.timer=nil;
          m.init();
          return m;
          },

  #Init AHK
  init: func() {
    me.timer=maketimer(0.0625,me, me.update_AHK);
    me.timer.start();
  },

  #Damped setting of distance needle
  set_dist: func(x, k) {
    var m=0;
    for (var i=1; i < 16; i = i+1) {
      me.dv[i-1]=me.dv[i];
        m=m+me.dv[i];
      }
      me.dv[15]=x*k;
      return (m+x*k)/16;
  },

  #Damped setting of target needle
  set_alt: func(x, k) {
    var m=0;
    for (var i=1; i < 16; i = i+1) {
      me.av[i-1]=me.av[i];
        m=m+me.av[i];
      }
      me.av[15]=x*k;
      return (m+x*k)/16;
  },

  #Calculating groundspeed from ias
  calc_gs: func(h, asp) {
    for (var i=1; i < 12; i = i+1) if (h<me.factor[i][0]) break;
    var y=(h-me.factor[i-1][0])/(me.factor[i][0]-me.factor[i-1][0]);
    return asp*(y*(me.factor[i][1]-me.factor[i-1][1])+me.factor[i-1][1]);
  },

  #HOJDANDRING
  mode_dh: func() {
    var h=getprop("/instrumentation/altimeter/pressure-alt-ft");
    var dhdt=getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm")*0.305;
    var gs=me.calc_gs(h, getprop("/instrumentation/airspeed-indicator/indicated-speed-kt")*1.852);
    setprop("/instrumentation/AHK/needle_target", me.set_alt(dhdt+h*0.305, 0.00005));
    if (dhdt != 0 and gs > 100) {
      var t = 1000/dhdt;
      var s2 = gs*gs/3600*t*t;
      if (s2 > 1) var d= math.sqrt(s2-1); else d=0;
        setprop("/instrumentation/AHK/needle_dist", me.set_dist(d, 0.025));
    }
  },

  #LANDA
  mode_landa: func() {
    var h=getprop("/instrumentation/altimeter/pressure-alt-ft");
    var dhdt=getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm")*0.305;
    setprop("/instrumentation/AHK/needle_target", me.set_alt(dhdt+h*0.305, 0.0005));
    setprop("/instrumentation/AHK/needle_dist", 
            me.set_dist(getprop("/instrumentation/navradio/dis"), 0.000025));
  },

  #NOLLA
  mode_nolla: func() {
    setprop("/instrumentation/AHK/needle_target", me.set_alt(0, 1));
    setprop("/instrumentation/AHK/needle_dist", me.set_dist(0, 1));
  },

  #AVST. 40
  mode_av40: func() {
    var h=getprop("/instrumentation/altimeter/pressure-alt-ft");
    var dhdt=getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm")*0.305;
    setprop("/instrumentation/AHK/needle_target", me.set_alt(dhdt+h*0.305, 0.00005));
    setprop("/instrumentation/AHK/needle_dist", 
            me.set_dist(getprop("/instrumentation/navradio/dis"), 0.000025));
  },

  #AVST. 400
  mode_av400: func() {
    var h=getprop("/instrumentation/altimeter/pressure-alt-ft");
    var dhdt=getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm")*0.305;
    setprop("/instrumentation/AHK/needle_target", me.set_alt(dhdt+h*0.305, 0.00005));
    setprop("/instrumentation/AHK/needle_dist", 
            me.set_dist(getprop("/instrumentation/navradio/dis"), 0.0000025));
  },

  #NYTT MAL
  mode_nm: func() {
    setprop("/instrumentation/AHK/needle_target", 
            me.set_alt(getprop("/instrumentation/navradio/gs_alt"), 0.00001663));
    var dist=getprop("/instrumentation/navradio/dis");
    if (dist >21.6) setprop("/instrumentation/AHK/needle_dist", me.set_dist(dist, 0.00463));
    else setprop("/instrumentation/AHK/needle_dist", me.set_dist(dist, 0.0463));
  },

  #BARBRO
  mode_barbro: func() {
    var h=getprop("/instrumentation/altimeter/pressure-alt-ft");
    var dhdt=getprop("/instrumentation/vertical-speed-indicator/indicated-speed-fpm");
    var gs=me.calc_gs(h, getprop("/instrumentation/airspeed-indicator/indicated-speed-kt")*1.852);
    setprop("/instrumentation/AHK/needle_target", me.set_alt(dhdt+h, 0.0001663));
    if (dhdt != 0 and gs > 100) {
      var t = h/dhdt;
      var s2 = gs*gs/3600*t*t;
      if (s2 > 1) var d= math.sqrt(s2-1); else d=0;
        setprop("/instrumentation/AHK/needle_dist", me.set_dist(d, 0.025));
    }

  },

  #Setting modes
  set_AHK_mode: func(ms) {
    me.mode=ms;
    if (ms==0) {
      if (me.verbose >1) print("AHK mode NOLLA");
      me.mode_nolla();
    } else if (ms==1) {
      if (me.verbose >1) print("AHK mode HOJDANDR");
      me.mode_dh();
    } else if (ms==2) {
      if (me.verbose >1) print("AHK mode LANDA");
      me.mode_landa();
    } else if (ms==3) {
      if (me.verbose >1) print("AHK mode AVST. 40");
      me.mode_av40();
    } else if (ms==4) {
      if (me.verbose >1) print("AHK mode AVST. 400");
      me.mode_av400();
    } else if (ms==5) {
      if (me.verbose >1) print("AHK mode NYTT MAL");
      me.mode_nm();
    } else if (ms==6) {
      if (me.verbose >1) print("AHK mode BARBRO");
      me.mode_barbro();
    }
  },
  
  update_AHK: func() {
    if (me.mode==0) {
      me.mode_nolla();
    } else if (me.mode==1) {;
      me.mode_dh();
    } else if (me.mode==2) {
      me.mode_landa();
    } else if (me.mode==3) {
      me.mode_av40();
    } else if (me.mode==4) {
      me.mode_av400();
    } else if (me.mode==5) {
      me.mode_nm();
    } else if (me.mode==6) {
      me.mode_barbro();
    }
  },    

};




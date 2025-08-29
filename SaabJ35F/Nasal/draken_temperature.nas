# https://aircraftdesignguide.com/wp-content/uploads/2020/03/9-Guidelines-for-the-Design-of-Aircraft-Windshield-Canopy-Systems-Chapter-Seven.pdf

var Temp = { 

  new: func() {
    var m = { parents:[Temp]};
    m.dt=0.5;
    m.step=0.05*m.dt;
    m.kout=0.05;
    m.kin=0.05;
    m.kdi=[0.8, 0, 1.6];
    m.kmach=0.95;
    m.T=0;
    m.Tac=20; #Constant AC temperature
    m.frost="/environment/aircraft-effects/frost-level";
    m.fog="/environment/aircraft-effects/fog-level";
    m.timer=nil;
    return m;
  },

  init: func(Tstart) {
    me.T=Tstart;
    me.Tin=math.max(getprop("environment/temperature-degc"), me.Tac);
    setprop(me.frost,0);
    setprop(me.fog,0);
    setprop("/environment/aircraft-effects/Tglass",me.T);
    setprop("/environment/aircraft-effects/DPcp",me.calcDPin());
    setprop("/hazards/skin-temp", me.T );
    me.timer=maketimer(me.dt, me, me.updateglasstemp);
    me.timer.start();
  },
  
  calcDPin: func() {
    DPout=getprop("/environment/dewpoint-degc");
    return math.max(9*math.exp(0.0341*DPout), 2);
  },

  updateglasstemp: func {
    var T0=getprop("environment/temperature-degc")+273;
    var M=getprop("velocities/mach");
    var Tout=T0*(1+me.kmach*M*M/5*getprop("/environment/pressure-inhg")/29.3)-273;
    setprop("/hazards/skin-temp", Tout);
    var deice=me.kdi[getprop("controls/canopy/deice")+1];
    me.Tin=math.max(getprop("environment/temperature-degc"), me.Tac);
    var dT=((Tout-me.T)*me.kout+(me.Tin-me.T)*me.kin+deice)*me.dt;
    var DPin=me.calcDPin();
    me.T=me.T+dT;
    setprop("/environment/aircraft-effects/Tglass", me.T);
    setprop("/environment/aircraft-effects/DPcp",DPin);
    if (getprop("/environment/dewpoint-degc")>me.T or DPin>me.T ) { 
        if(me.T<0) {
          setprop(me.frost, math.min(getprop(me.frost)+me.step,1));
          setprop(me.fog, math.max(getprop(me.fog)-me.step,0));
        } else {
          setprop(me.frost, math.max(getprop(me.frost)-me.step,0));
          setprop(me.fog, math.min(getprop(me.fog)+me.step,1));
        }
    } else {
        setprop(me.fog, math.max(getprop(me.fog)-me.step,0));
        setprop(me.frost, math.max(getprop(me.frost)-me.step,0));
    }  
  },
};  



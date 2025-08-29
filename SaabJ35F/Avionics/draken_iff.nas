# PN-793 IFF

var IFF = {

  new: func(verb) {
    var m = { parents:[IFF]};
    m.verbose=verb;
    m.pwr=false;
    m.timer=nil;
    m.pwr_setting=0;
    m.init();
    return m;
  },
  
  init: func() {
    me.timer=maketimer(20,me, func () {
                                       me.pwr_setting = getprop("/instrumentation/iff/pwr");
                                       if  (getprop("/instrumentation/iff/pwr") ==2) setprop("/instrumentation/iff/on",1);
                                       if (me.verbose>0) print(me.pwr_setting);
                                      });
    me.timer.singleShot=1;
    me.timer.simulatedTime=1;
  },
  
  pwr_knob: func() {
    if (!me.pwr) {me.pwr_setting=0; return;}
    var s=getprop("/instrumentation/iff/pwr");
    if (s==0) me.pwr_setting=0;
    if (s>0 and me.pwr_setting==0) me.timer.start();
    if (s==2 and me.pwr_setting >0) setprop("/instrumentation/iff/on",1);
    if (s<2) setprop("/instrumentation/iff/on",0);
  },
  
  test: func() {
    if (!me.pwr) {
      setprop("/instrumentation/iff/indicator",0);
      return;
    }
    if (getprop("/instrumentation/iff/test")<0) setprop("/instrumentation/iff/indicator",1);
    else setprop("/instrumentation/iff/indicator",0);
  },
  
  iff_pwr: func(p) {
    if (p) me.pwr=true;
    else me.pwr=false;
    me.test();
    me.pwr_knob();
  },
    
};



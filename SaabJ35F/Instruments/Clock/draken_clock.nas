# Clock handler
var Clock = {

    new: func(verb) {
        var m = { parents:[Clock]};
        m.clkmode=0;
        m.timermode=2;
        m.now=0;
        m.verbose=verb;
        m.timer=nil;
        m.init();
        return m;
    },
    
    init: func() {
        me.timer=maketimer(0.05,me, me.stopwatch);
    },
        
    stopwatch: func() {
        var t=getprop("/instrumentation/clock/indicated-sec")-me.now;
        setprop("instrumentation/clock/tenth-hand-pos", getprop("instrumentation/clock/tenth-hand-pos")+0.5);
        setprop("instrumentation/clock/hour-hand-pos", t/3600);
        setprop("instrumentation/clock/min-hand-pos", t/60);
        setprop("instrumentation/clock/sec-hand-pos", (t/60.0-math.floor(t/60.0))*60);
    },
    
    update: func() {
        if (!me.clkmode) {
            setprop("instrumentation/clock/hour-hand-pos", (getprop("/instrumentation/clock/indicated-hour") or 0));
            setprop("instrumentation/clock/min-hand-pos", (getprop("/instrumentation/clock/indicated-min") or 0));
            var nowsec= (getprop("/instrumentation/clock/indicated-sec") or 0);
            setprop("instrumentation/clock/sec-hand-pos", (nowsec/60.0-math.floor(nowsec/60.0))*60);
            setprop("instrumentation/clock/tenth-hand-pos", 0);
        }
    },
    
    changemode: func(mode) {
        if (me.verbose>1) print(sprintf("Change mode %d", mode));
        if (mode) {
            setprop("instrumentation/clock/hour-hand-pos", 0);
            setprop("instrumentation/clock/min-hand-pos", 0);
            setprop("instrumentation/clock/sec-hand-pos", 0);
            setprop("instrumentation/clock/tenth-hand-pos", 0);
        } else {
            setprop("instrumentation/clock/tenth-hand-pos", 0);
        }
        me.clkmode=mode;
    },
    
    # 0=stop, 1=running, 2=reset
    stopwchange: func() {
        if (!me.clkmode or getprop("/instrumentation/clock/stopw-pressed")==0) return;
        if (me.timermode==0) {
            me.timer.stop();
            me.timermode=2;
            setprop("instrumentation/clock/hour-hand-pos", 0);
            setprop("instrumentation/clock/min-hand-pos", 0);
            setprop("instrumentation/clock/sec-hand-pos", 0);
            setprop("instrumentation/clock/tenth-hand-pos", 0);
            if (me.verbose>1) print("Stw reset");
        }
        else if (me.timermode==1) {
            me.timermode=0;
            me.timer.stop();
            if (me.verbose>1) print("Stw stopped");
        } else {
            me.now=getprop("/instrumentation/clock/indicated-sec");
            me.timermode=1;
            if (me.verbose>1) print("Stw started");
            me.timer.start();
        }
    }
};


        

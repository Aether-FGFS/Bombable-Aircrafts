  # Fr-21 Controlpanel and transivers

var Fr21 = { 

  new: func(verb) {
    var m = { parents:[Fr21]};
    m.verbose=verb; 
    m.frqAK=[];
    m.frq15=[];
    m.btnsAK="ABCDEFGHIJK";
    m.init();
    return m;
  },

  init: func {
	  append(me.frqAK, getprop("/instrumentation/comm[0]/frequencies/selected-mhz") or 0);
	  append(me.frq15, getprop("/instrumentation/comm[1]/frequencies/selected-mhz") or 0);
	  var fh = io.open(getprop('/sim/fg-home')~"/Export/SaabJ35F-Fr21.txt", "r");
	  var line="";
	  var n=0;
	  if (me.verbose >0) print("Reading radio frequencies");
	  while (line != nil) {
		  line = io.readln(fh);
		  if (line != nil) {
			  var c_arr=split(",", line);
			  if (size(c_arr) > 1) {
			   if (n<10) { append(me.frqAK, num(c_arr[1])); }
			   else { append(me.frq15, num(c_arr[1])); }
			   n=n+1;
			   if (me.verbose >1) print(line);
			  }
		  }
	  }
	  if (me.verbose >0) print("Done reading radio frequencies");
	  io.close(fh);
  },

  set_frq: func(f, unit) {
	  if (unit=="A" and getprop("instrumentation/comm/power-btn") == 1) {
	   if (getprop("/instrumentation/fr21/mode")) {
	     setprop("/instrumentation/comm[1]/frequencies/selected-mhz", f);
	   } else { setprop("/instrumentation/comm[0]/frequencies/selected-mhz", f); }
	   setprop("/instrumentation/fr21/frequency_A", f);
	  }
	  if (unit=="B" and getprop("instrumentation/comm[1]/power-btn") == 1) {
	    if (getprop("/instrumentation/fr21/mode")) {
	     setprop("/instrumentation/comm[0]/frequencies/selected-mhz", f);
	   } else { setprop("/instrumentation/comm[1]/frequencies/selected-mhz", f); }
	   setprop("/instrumentation/fr21/frequency_B", f);
	  }
  },

  change_mode: func {
        com0= getprop("/instrumentation/comm[0]/frequencies/selected-mhz");
        com1= getprop("/instrumentation/comm[1]/frequencies/selected-mhz");
        setprop("/instrumentation/comm[0]/frequencies/selected-mhz", com1);
        setprop("/instrumentation/comm[1]/frequencies/selected-mhz", com0);
        sound_helper("sound-small");
  },

  button_handlerAK: func(btn) {
	  for (var i=0; i<11; i=i+1) {
	   setprop("/instrumentation/fr21/buttons/"~substr(me.btnsAK, i, 1), 0);
	  }
	  setprop("/instrumentation/fr21/buttons/Uslash", 0);
	  setprop("/instrumentation/fr21/buttons/"~btn, 1);
	  if (btn=="Uslash") { me.set_frq(getprop("/instrumentation/fr21/frequency_A_man"), "A"); }
	  else { me.set_frq(me.frqAK[find(btn, me.btnsAK)], "A"); }
  },

  button_handler15: func(btn) {
	  for (var i=1; i<6; i=i+1) {
	   setprop("/instrumentation/fr21/buttons/b"~i, 0);
	  }
	  setprop("/instrumentation/fr21/buttons/Lslash", 0);
	  setprop("/instrumentation/fr21/buttons/"~btn, 1);
	  if (btn=="Lslash") { me.set_frq(getprop("/instrumentation/fr21/frequency_B_man"), "B"); }
	  else { me.set_frq(me.frq15[num(btn[1])-49], "B") }
  },


  manual_handler: func(unit) {
	  if (unit == "A" and getprop("instrumentation/fr21/buttons/Uslash") == 1) {
	   me.set_frq(getprop("instrumentation/fr21/frequency_A_man"), "A"); 
	  }
	  if (unit == "B" and getprop("instrumentation/fr21/buttons/Lslash") == 1) {
	   me.set_frq(getprop("instrumentation/fr21/frequency_B_man"), "B"); 
	  }
  },
  
};




# ==============================================================================
# Radar
# ==============================================================================

var radar = {
  new: func(verb) {
    var m = { parents: [radar] };
    m.verbose=verb;
    # create a new canvas...
    m.canvas = canvas.new({
      "name": "RADAR",
      "size": [1024, 1024],
      "view": [1024, 1024],
      "mipmapping": 1
    });
    
    # ... and place it on the object called Screen
    m.canvas.addPlacement({"node": "Screen"});
    m.canvas.setColorBackground(0.20,0.27,0.16);
    var g = m.canvas.createGroup();

    m.dt=0.05;
    m.radar_mode=0;
    m.cross_mode=0;
    m.scan_mode=120;
    m.antenna_mode=0;
    m.temp=0;
    m.wutemp=10; # Time to warm up radar
    m.glide_pos=1000; #Actual position
    m.course_pos=1000; #Actual position
    m.glide_target=1000; #Target position
    m.course_target=1000; #Target position
    m.stroke_mode=120;
    m.antenna_pitch=0;
    m.stroke_dir=0; #center yaw -80 to 80 mode=2
    m.no_stroke = 6;
    m.no_blip=10;
    m.stroke_pos= [];
    for(var i=0; i < m.no_stroke; i = i+1) {
      append(m.stroke_pos, 0);
    }

    m.stroke = [];
    m.tfstroke=[];
    for(var i=0; i < m.no_stroke; i = i+1) {
        append(m.stroke,
         g.createChild("path")
         .moveTo(512, 120)
         .lineTo(512, 904)
         .close()
         .setStrokeLineWidth(12)
         .setColor(0.6,0.7,1.0, 1.0));
       append(m.tfstroke, m.stroke[i].createTransform());
       m.tfstroke[i].setTranslation(0, 0);
       m.stroke[i].hide();
     }

    m.blip = [];
    m.blip_alpha=[];
    m.tfblip=[];
    for(var i=0; i < m.no_blip; i = i+1) {
        append(m.blip,
         g.createChild("path")
         .moveTo(502, 860)
         .lineTo(522, 860)
         .close()
         .setStrokeLineWidth(12)
         .setColor(0.6,0.7,1.0, 1.0));
       append(m.tfblip, m.blip[i].createTransform());
       m.tfblip[i].setTranslation(0, 0);
       m.blip[i].hide();
       append(m.blip_alpha, 1);
     }
     
    m.antennay=g.createChild("path")
                .moveTo(900, 512)
                .lineTo(920, 512)
                .close()
                .setStrokeLineWidth(18)
                .setColor(0.6,0.7,1.0, 1.0);
    m.antennay.hide();
    m.tfantennay=m.antennay.createTransform();
    
    m.horizon=g.createChild("path")
                .moveTo(10, 512)
                .lineTo(1014, 512)
                .close()
                .setStrokeLineWidth(12)
                .setColor(0.6,0.7,1.0, 1.0);
    m.horizon.updateCenter();
    m.horizon.hide();
    m.thorizon_pitch=m.horizon.createTransform();
    m.thorizon_roll=m.horizon.createTransform();

    m.glide=g.createChild("path")
                .moveTo(10, 512)
                .lineTo(1000, 512)
                .close()
                .setStrokeLineWidth(18)
                .setColor(0.96,0.74,0.20, 1.0);
    m.tfglide=m.glide.createTransform();
    m.tfglide.setTranslation(0, 500);

    m.course=g.createChild("path")
                .moveTo(512, 10)
                .lineTo(512, 1000)
                .close()
                .setStrokeLineWidth(18)
                .setColor(0.96,0.74,0.20, 1.0);
    m.tfcourse=m.course.createTransform();
    m.tfcourse.setTranslation(500, 0);

    m.scale=g.createChild("image")
             .setFile("Radar/scale.png")
             .setSourceRect(0,0,1,1)
             .setSize(1024,1024)
             .setTranslation(0,0);
    if (m.verbose>1) print("Created radar canvas");
    return m;
  },


 # To hide unhide radar things.
  mode_select: func() {
    me.radar_mode = (getprop("controls/radar/mode") or 0);
    var nmode= (getprop("controls/navradio/mode") or 0);    
    if (nmode < 2 or nmode==3) me.cross_mode=0;
    else if (nmode==7) me.cross_mode=2;
    else if ((nmode==5 or nmode==6) and getprop("autopilot/settings/plane")==1) me.cross_mode=3;
    else me.cross_mode=1;
  },
  
  update: func()
  {
  #Radar Modes 0=Off, 1=Standby, 2=On, 3=Silent, 4=Emitting
  #Stroke Modes 120 deg, 40 deg
  #Antenna Modes 0=Auto, 1=Manual
  #Cross Modes 0=Off, 1=Course guide, 2=Course and glide ILS, 3=Course and glide Plane
  # B-skop STRIL TODO
    if (me.radar_mode == 0) me.temp=math.max(me.temp - me.dt, 0)
    else me.temp=math.min(me.temp + me.dt, me.wutemp);
    var intskope = (getprop("controls/radar/radar_skope_light") or 0);
    var intcross = (getprop("controls/radar/radar_cross_light") or 0);
    if (me.temp+me.dt < me.wutemp or me.radar_mode <2) {
	    #Off
      forindex (i; me.stroke) if (me.stroke[i].getVisible()==1) me.stroke[i].hide();
      forindex (i; me.blip) if (me.blip[i].getVisible()==1) me.blip[i].hide();
      if (me.antennay.getVisible()==1) me.antennay.hide();
      if (me.horizon.getVisible()==1) me.horizon.hide();
    } else {
      if (me.horizon.getVisible()==0) me.horizon.show();
      var pitch=(getprop("instrumentation/attitude-indicator/indicated-pitch-deg") or 0);
      var roll=(getprop("instrumentation/attitude-indicator/indicated-roll-deg") or 0);
      me.thorizon_roll.setRotation(-roll*0.0174533, 512,512);
      me.thorizon_pitch.setTranslation(0, pitch*10);
      me.horizon.setColor(0.6,0.7,1.0, 1.0*intskope);
      if (me.radar_mode >= 3) {
        forindex (i; me.stroke)
          if (me.stroke[i].getVisible()==0) me.stroke[i].show();
        if (me.antennay.getVisible()==0) me.antennay.show();
        me.stroke_mode=getprop("instrumentation/radar/scan_mode");
        if (me.stroke_mode == 40) 
		      me.stroke_dir=getprop("instrumentation/radar/antenna_yaw");
		    else me.stroke_dir=0;

		    #Stroke animation
		    var pos=6*me.stroke_dir+
		        3*me.stroke_mode*math.sin(getprop("sim/time/elapsed-sec")*60/me.stroke_mode);
		    for(var i=1; i < me.no_stroke; i = i+1) {
		      me.stroke_pos[i-1]=me.stroke_pos[i];
		      me.tfstroke[i-1].setTranslation(me.stroke_pos[i-1], 0);
		      me.stroke[i-1].setColor(0.6,0.7,1.0,1.0/(me.no_stroke+1-i)*intskope);
		    }
		    me.stroke_pos[me.no_stroke-1] = pos;
		    me.tfstroke[me.no_stroke-1].setTranslation(pos, 0);
		    me.stroke[me.no_stroke-1].setColor(0.6,0.7,1.0, 1.0*intskope);

		    #Antenna pitch
		    if ( me.antenna_mode == 0)
		      me.antenna_pitch=30.0*math.sin(getprop("sim/time/elapsed-sec")*2);
		    else if ( me.antenna_mode== 1)
		      me.antenna_pitch=getprop("instrumentation/radar/antenna_pitch");
		    me.tfantennay.setTranslation(0, -5.06*me.antenna_pitch);
         
      #Uppdaterar blips
        if (me.radar_mode== 4) me.update_blip(intskope);
        else forindex (i; me.blip) if (me.blip[i].getVisible()==1) me.blip[i].hide();
      } else {
      # mode <3 no radar
        forindex (i; me.stroke) if (me.stroke[i].getVisible()==1) me.stroke[i].hide();
        forindex (i; me.blip) if (me.blip[i].getVisible()==1) me.blip[i].hide();
        if (me.antennay.getVisible()==1) me.antennay.hide();
      }
    }
    #Guide animation
    if (me.cross_mode == 0) {
        me.glide_target=480;
        me.course_target=480;
    } else if (me.cross_mode == 1) {
        me.glide_target=480;
        me.course_target=
          calc_c_target(getprop("instrumentation/heading-indicator/indicated-heading-deg"),
                        getprop("/instrumentation/navradio/dir"));
    } else if (me.cross_mode == 2) {
        me.glide_target=getprop("/instrumentation/navradio/gs_alt")*430;
        me.course_target=getprop("/instrumentation/navradio/gs_dir")*430;
    } else { # cross mode 3
      me.course_target=
          calc_c_target(getprop("instrumentation/heading-indicator/indicated-heading-deg"),
                        getprop("/instrumentation/navradio/dir"));
      me.glide_target=getprop("/instrumentation/navradio/gs_alt")*430;
    }                  
    var gm=me.glide_target-me.glide_pos;
    var cm=me.course_target-me.course_pos;
    if (math.abs(gm) > 36) gm=36*math.sgn(gm);
    me.glide_pos=me.glide_pos+gm;
    if (math.abs(cm) > 36) cm=36*math.sgn(cm);
    me.course_pos=me.course_pos+cm;
    me.tfglide.setTranslation(0, me.glide_pos);
    me.tfcourse.setTranslation(me.course_pos, 0);
    me.glide.setColor(0.96,0.74,0.20, 1.0*intcross);
    me.course.setColor(0.96,0.74,0.20, 1.0*intcross);
    settimer(func me.update(), me.dt);
  },
  
  update_blip: func(intskope) {
		var self = geo.aircraft_position();
		var pitch=getprop("orientation/pitch-deg")*0.0174533;
		var roll=-getprop("orientation/roll-deg")*0.0174533;
		var alt0=getprop("position/altitude-ft")*0.305;
		var dir=getprop("orientation/heading-deg");
		var b_i=0;
		foreach (var mp; multiplayer.model.list) {
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
	    }
	    else
	    {
        # Node with valid position data (and "distance!=nil").
        var alt=n.getNode("position/altitude-ft").getValue()*0.305;
        var yg_rad=math.atan2((alt-alt0), distance)-pitch;
        var xg_rad=(self.course_to(ac)-dir)*0.0174533;
        if (xg_rad > math.pi) xg_rad=xg_rad-2*math.pi;
        var ya_rad=xg_rad*math.sin(roll)+yg_rad*math.cos(roll);
        var xa_rad=xg_rad*math.cos(roll)-yg_rad*math.sin(roll);
        if (b_i < me.no_blip and distance < 40000 and 
            alt-100 > getprop("/environment/ground-elevation-m")){
          if (ya_rad > -0.5 and ya_rad < 0.5 and xa_rad > -1 and xa_rad < 1) {
              if (math.abs(xa_rad*430-me.stroke_pos[me.no_stroke-1]) < 30) {
                if (me.antenna_mode==1) me.blip_alpha[b_i]=1-math.abs(me.antenna_pitch*0.01745-ya_rad);
                else me.blip_alpha[b_i]=1;
                me.tfblip[b_i].setTranslation(xa_rad*430, -distance*0.0174); 
              } else me.blip_alpha[b_i] = me.blip_alpha[b_i]*0.98;
              me.blip[b_i].show();
              me.blip[b_i].setColor(0.6,0.7,1.0, me.blip_alpha[b_i]*intskope);
              b_i=b_i+1;
          }
        }
	    }
		}
		for (i = b_i; i < me.no_blip; i=i+1) me.blip[i].hide();
	},
};

var calc_c_target= func(crs, trg) {
  var diff=trg-crs;
  if (diff>180) diff=diff-360;
  if (diff<-180) diff=360+diff;
  diff=7.1667*diff;
  if (diff > 430) diff=430;
  else if (diff < -430) diff=-430;
  return diff;
}


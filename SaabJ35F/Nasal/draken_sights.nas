var AKAN_Sight = {
  new: func(x,y) {
    var m = { parents: [AKAN_Sight] };
    m.canvas = canvas.new({
      "name": "Sight-Test",   
      "size": [512, 512], 
      "view": [512, 512],  
      "mipmapping": 1});
      
      m.canvas.setColorBackground(1,1,1,0);
      m.canvas.addPlacement({"node": "HUD_sight"});
      
    var root = m.canvas.createGroup();
    m.target = root.createChild('group');
    
    m.x=x;
    m.y=y;
    m.angles=[0, math.pi/3, 2*math.pi/3, math.pi, 4*math.pi/3, 5*math.pi/3];
    m.HUD_angle=90*math.pi/180;
    m.HUD_scale=512/15; #pixels per cm width
    m.projectile_speed=790;
    m.HUD_distance = 78; # cm from eyes
    m.rombs=[];
    m.timer_hud=nil;
    m.listener_dist=nil;
    m.listener_onoff=nil;
    m.listener_ws=nil;
    for (var i=0; i<6; i+=1) {
      append(m.rombs,
          m.target.createChild("path")
          .moveTo(-6,0)
          .lineTo(0,4)
          .lineTo(6,0)
          .lineTo(0,-4)
          .lineTo(-6,0)
          .close()
          .setStrokeLineWidth(3)
          .setColor([1,0.9,0,1]));
    }
    m.cp=m.target.createChild("path", "center")
         .circle(4,m.x,m.y)
         .setStrokeLineWidth(3)
         .setColor([1,0.9,0,1]);
         
    m.target.setScale(1, 1/math.sin(m.HUD_angle));
    return m;
  },
  
  setIntensity: func () {
    var i =getprop("instrumentation/sight/brightness") or 0;
    foreach (romb; me.rombs) romb.setColor(1,0.9,0, i);
    me.cp.setColor(1,0.9,0,i);
  },
  
  setRadius: func () {
    var ws = getprop("instrumentation/sight/wingspan") or 10;
    var df= getprop("instrumentation/sight/dist_factor") or 0.195;
    var r = ws*df*me.HUD_scale/2;
    for (var i=0; i<6; i+=1) me.rombs[i]
      .setTranslation(me.x+r*math.cos(me.angles[i]),me.y+r*math.sin(me.angles[i]))
      .setRotation(me.angles[i]);
  },
  
  setOnOff: func (state) {
    foreach (romb; me.rombs) romb.setVisible(state);
    me.cp.setVisible(state);
    if (me.timer_hud.isRunning and !state) me.timer_hud.stop();
    if (!me.timer_hud.isRunning and state) me.timer_hud.start();
  },
  
  uppdatePosition: func () {
  #TODO better physics
    var ws = getprop("instrumentation/sight/wingspan") or 10;
    var df= getprop("instrumentation/sight/dist_factor") or 0.195;
    var dist=me.HUD_distance/df;
    var t=dist/me.projectile_speed + (1.691e-7*dist*dist+1.464e-5*dist)*getprop("fdm/jsbsim/atmosphere/rho-slugs_ft3")/0.00237;
    var ahead_cm=getprop("orientation/yaw-rate-degps")*math.pi/180*t*me.HUD_distance;
    var drop_cm= 4.91*t*t*df;
    var r=getprop("orientation/roll-deg")*math.pi/180;
    var dx=(drop_cm*math.sin(r)-ahead_cm*math.cos(r))*me.HUD_scale;
    var dy=(ahead_cm*math.sin(r)-drop_cm*math.cos(r))*me.HUD_scale;
    me.target.setTranslation(dx,dy);
  },
  
  weaponMonitor: func ()  {
    if (getprop("controls/armament/selected") == 1) me.setOnOff(1); 
    else me.setOnOff(0);
  },
  
  start: func {
    me.timer_hud= maketimer(0.05, func {me.uppdatePosition();});
    me.listener_dist = setlistener("instrumentation/sight/dist_factor", func {me.setRadius();}, 1, 0);
    me.listener_ws = setlistener("instrumentation/sight/wingspan", func {me.setRadius();}, 1, 0);
    me.listener_onoff = setlistener("controls/armament/selected", func(ws) me.weaponMonitor(ws), 1, 0);
  },
  
  del: func {
    me.timer_hud.stop();
    removelistener(me.listener_dist);
    removelistener(me.listener_ws);
    removelistener(me.listener_onoff);
  }  
};

var akan_sight = func {
  var asg=AKAN_Sight.new(256,138);
  asg.setRadius();
  asg.start();
  return asg;
}

var akansight= akan_sight();

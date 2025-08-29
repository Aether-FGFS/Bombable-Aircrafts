########## About dialog. Shows README file ############
var show_about_dialog = func () {
  var (width,height) = (600,520);
  var title = 'About J35F';

  var file =getprop("/sim/aircraft-dir")~"/README";
  var text = io.readfile(file);

  var window = canvas.Window.new([width,height],"dialog")
   .set('title',title)
   .setBool("resize", 1);
   
  var myCanvas = window.createCanvas().set("background", canvas.style.getColor("bg_color"));

  var root = myCanvas.createGroup();
  var vbox = canvas.VBoxLayout.new();
  myCanvas.setLayout(vbox);

  var scroll = canvas.gui.widgets.ScrollArea.new(root, canvas.style, {size: [96, 128]}).move(20, 100);
  vbox.addItem(scroll, 1);

  var scrollContent =
        scroll.getContent()
              .set("font", "LiberationFonts/LiberationSans-Bold.ttf")
              .set("character-size", 16)
              .set("alignment", "left-top");

  var label1 = canvas.gui.widgets.Label.new(scrollContent, canvas.style, {wordWrap: 1}); 
  label1.setText(text);
  label1._view._text.setMaxWidth(580);
}

########## Dialogs to show settings for Fr21 and Navigation radio ##############
#Radio frequency dialog

var get_radio_settings= func() {
  var frqAK=[];
  var frq15=[];
  var descrAK=[];
  var descr15=[];
  var btnsAK="ABCDEFGHIJK";
  # Read frequency file
  var fh = io.open(getprop('/sim/fg-home')~"/Export/SaabJ35F-Fr21.txt", "r");
  var line="";
  # Initial frequencies
  append(frqAK, getprop("/instrumentation/comm[0]/frequencies/selected-mhz") or 0); #COM1
  append(descrAK, "Initial COM1");
  append(frq15, getprop("/instrumentation/comm[1]/frequencies/selected-mhz") or 0); #COM2
  append(descr15, "Initial COM2");
  while (line != nil) {
    line = io.readln(fh);
    if (line != nil) {
      var c_arr=split(",", line);
      if (size(c_arr) > 1) {
        if (size(c_arr[0])==1) { 
          append(frqAK, num(c_arr[1]));
          if (size(c_arr)>2) append(descrAK, c_arr[2]);
          else append(descrAK, "");
        }
        else { 
          append(frq15, num(c_arr[1]));
          if (size(c_arr)>2) append(descr15, c_arr[2]);
          else append(descr15, ""); 
        }
      }
    }
  }
  io.close(fh);

  #Create text
  text=sprintf("\nChange in Export/SaabJ35F-Fr21.txt\n\nBtn%5s%15s\n","frq","Description");
  forindex(i; frqAK){
    text=text~sprintf("%c%8.2f%3s%s\n",btnsAK[i], frqAK[i], " ", descrAK[i]);
  }
  text=text~"\n";
  forindex (i; frq15){
    text=text~sprintf("%i%8.2f%3s%s\n",i+1, frq15[i], " ", descr15[i]);
  }
  return text;
}


var show_radio_dialog =func() {
  # create a new window, dimensions are WIDTH x HEIGHT, using the dialog decoration (i.e. titlebar)
  var (width,height) = (352,292);
  var title = 'Radio Frequencies';
  var window = canvas.Window.new([width,height],"dialog").set('title',title);
  window.move(200,100);

  # adding a canvas to the new window and setting up background colors/transparency
  var myCanvas = window.createCanvas()
                 .setColorBackground(1,1,1,1);

  # creating the top-level/root group which will contain all other elements/group
  var root = myCanvas.createGroup();

  #Show text
  var dialogText = root.createChild("text")
    .setText(get_radio_settings())
    .setFontSize(12, 0.9)
    .setColor(0,0,0,1)
    .setColorFill(1,1,1,1)
    .setAlignment("left-top")
    .setTranslation(10, 10); 
    
}


##################################################################
#Nav beacon dialog

var get_beacon_settings= func() {
  var lines=[];
  # Read beacons file
  var fh = io.open(getprop('/sim/fg-home')~"/Export/SaabJ35F-Beacons.txt", "r");
  var line="";
  while (line != nil) {
    line = io.readln(fh);
    if (line != nil) {
      if (line[0] != 35) {
        append(lines, line);
      }
    }
  }
  io.close(fh);

  #Create text
  text=["Code\n","Type\n","Frq\n", "Description\n"];
  forindex(i; lines){
    var data=split(",", lines[i]);
    text[0]=text[0]~sprintf("%s\n", data[0]);
    text[1]=text[1]~sprintf("%s\n", data[1]);
    text[2]=text[2]~sprintf("%s\n", data[2]);
    text[3]=text[3]~sprintf("%s\n", data[3]);
  }
  return text;
}


var show_beacon_dialog =func() {
  # create a new window, dimensions are WIDTH x HEIGHT, using the dialog decoration (i.e. titlebar)
  var (width,height) = (420,320);
  var title = 'Stored navigation beacons';
  var window = canvas.Window.new([width,height],"dialog").set('title',title);
  window.move(200,100);

  # adding a canvas to the new window and setting up background colors/transparency
  var myCanvas = window.createCanvas()
                 .setColorBackground(1,1,1,1);

  # creating the top-level/root group which will contain all other elements/group
  var root = myCanvas.createGroup();

  #Create Scroll area
  var vbox = canvas.VBoxLayout.new();
  myCanvas.setLayout(vbox);
  var expl="Two or three letter navradio codes\nChange in Export/SaabJ35F-Beacons.txt";
  var lastlabel = canvas.gui.widgets.Label.new(root, canvas.style, {wordWrap: 1}).setText(expl);
  vbox.addItem(lastlabel);
  var scroll = canvas.gui.widgets.ScrollArea.new(root, canvas.style, {size: [96, 128]}).move(20, 100);
  vbox.addItem(scroll, 1);


  var scrollContent =
        scroll.getContent()
              .set("font", "LiberationFonts/LiberationMono-Regular.ttf")
              .set("character-size", 12)
              .set("alignment", "left-top");
              
  var columns = canvas.HBoxLayout.new();
  scroll.setLayout(columns);
  
  #Add text
  text=get_beacon_settings();
  var label0 = canvas.gui.widgets.Label.new(scrollContent, canvas.style, {wordWrap: 0})
  .setText(text[0]);
  columns.addItem(label0);
  var label1 = canvas.gui.widgets.Label.new(scrollContent, canvas.style, {wordWrap: 0})
  .setText(text[1]);
  columns.addItem(label1);
  var label2 = canvas.gui.widgets.Label.new(scrollContent, canvas.style, {wordWrap: 0})
  .setText(text[2]);
  columns.addItem(label2);
  var label3 = canvas.gui.widgets.Label.new(scrollContent, canvas.style, {wordWrap: 0})
  .setText(text[3]);
  columns.addItem(label3);   
}

########################################################
# Heading dialog shows heading indicator

var Compass_Dialog = {

  new: func() {
    var m = { parents: [Compass_Dialog] };
		var (width,height) = (180,180);
		var title = 'Heading Ind.';
		var window = canvas.Window.new([width,height],"dialog").set('title',title);

		var myCanvas = window.createCanvas().setColorBackground([0,0,0,1]);
		var root = myCanvas.createGroup();

		var filename = "Nasal/heading.svg";
		var svg_symbol = root.createChild('group');
		canvas.parsesvg(svg_symbol, filename, {parse_images:true});
		svg_symbol.setScale(2.0);

	  m.face=svg_symbol.getElementById("face");
	  m.course=svg_symbol.getElementById("course");
	  m.timer=nil;
	  m.init();
	  return m;
	},
	
	init: func() {
	  me.timer= maketimer(0.2, me, me.update );
	  me.timer.start();
	},
	
	update: func() {
	  var heading=getprop("instrumentation/heading-indicator/indicated-heading-deg") or 0;
	  var bug=getprop("/instrumentation/navradio/dir") or 0;
	  me.face.setRotation(-heading*D2R);
          me.course.setRotation((-heading+bug)*D2R);
	},
	
};

var open_Compass_Dialog = func() {
  var cd=Compass_Dialog.new();
} 
  
###########################################################
# Choose STRIL target

var StrilDialog = {
  new: func(verb)
  {
    var width=140;
    var height=160;
    var m = {
      parents: [StrilDialog],
      _dlg: canvas.Window.new([width, height], "dialog")
                         .set("title", "STRIL target")
                         .set("resize", 1),
    };
    m.verbose=verb;
    m._dlg.getCanvas(1)
          .set("background", canvas.style.getColor("bg_color"));
    m._root = m._dlg.getCanvas().createGroup();
 
    var vbox = canvas.VBoxLayout.new();
    m._dlg.setLayout(vbox);

    var cb=canvas.gui.widgets.ComboBox.new(m._root, canvas.style, {});
    cb.setText("Target");
    var csign=["Route"];
    cb.addMenuItem(csign[0],0);
    var i=1;
    foreach (var mp; multiplayer.model.list) {
      append(csign, mp.node.getNode("callsign").getValue());
      cb.addMenuItem(csign[i],i);
      i=i+1;
    }  
    vbox.addItem(cb);

    var button = canvas.gui.widgets.Button.new(m._root, canvas.style, {})
	    .setText("Set")
	    .setFixedSize(75, 25);

    button.listen("clicked", func {
    if (m.verbose >1) print(csign[cb._currentIndex]);
    setprop("instrumentation/navradio/stril-target",csign[cb._currentIndex]); 
    m._dlg.del();
    });

    vbox.addItem(button);

    var hint = vbox.sizeHint();
    hint[0] = math.max(width, hint[0]);
    m._dlg.setSize(hint);

    return m;
  },
};

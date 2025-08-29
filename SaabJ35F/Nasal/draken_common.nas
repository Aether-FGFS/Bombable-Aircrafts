#General Nasal functions and variables

#Debug level (0,1,2)
var verbose=getprop("nasal/SaabJ35F/verbose");
setlistener("nasal/SaabJ35F/verbose", func(node) { verbose=node.getValue()});


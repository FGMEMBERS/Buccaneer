var loopid = 0;
var gunview = nil;

var views = props.globals.getNode("/sim").getChildren("view");
forindex (var i; views)
	if (views[i].getNode("name", 1).getValue() == "Gun Camera View")
		gunview = i;

var loop = func(id) {
	id != loopid and return;
	setprop("/sim/current-view/heading-offset-deg", 0);
	setprop("/sim/current-view/pitch-offset-deg", 0);
	setprop("/sim/current-view/roll-offset-deg", 0);
	settimer(func { loop(id) }, 0);
}

setlistener("/sim/current-view/view-number", func {
	loopid += 1;
	if (cmdarg().getValue() == gunview)
		loop(loopid);
}, 1);

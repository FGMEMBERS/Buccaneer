var loopid = 0;
var gunview = view.indexof("Gun Camera View");

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

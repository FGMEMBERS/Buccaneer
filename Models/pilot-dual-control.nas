###############################################################################
## $Id$
##
## Nasal for main pilot for dual control over the multiplayer network.
##
##  Copyright (C) 2007  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license.
##
###############################################################################

# Renaming (almost :)
var DCT = dual_control_tools;
var ADC = buccaneer_dual_control;

# Local properties
#var l_dual_control         = "fdm/jsbsim/fcs/dual-control";

######################################################################
# Connect new copilot
var in_data = 0;
var out_data = 0;

var connect = func (copilot) {
# Tweak MP/AI filters
#  copilot.getNode("controls/allow-extrapolation").setBoolValue(0);
#  copilot.getNode("controls/lag-adjust-system-speed").setValue(5);

	in_data  = ADC.pilot_in_data(copilot);
	out_data = ADC.pilot_out_data(copilot);

	print("Dual control ... copilot connected.");
	setprop("/sim/messages/copilot", "Hi.");
}

######################################################################
# Main loop
var active = 0;
var update = func {
	var mpplayers =
		props.globals.getNode("/ai/models").getChildren("multiplayer");
	var r_callsign = getprop("/sim/remote/pilot-callsign");
#  print("r_callsign pilot", r_callsign );

	foreach (copilot; mpplayers) {
		if ((copilot.getChild("valid").getValue()) and
			(copilot.getChild("callsign") != nil) and
			(copilot.getChild("callsign").getValue() == r_callsign)) {

				if (active == 0) {
					connect(copilot);
					active = 1;
				}
# Make sure dual-control is activated in the FDM FCS.
#				setprop(l_dual_control, 1);

# Mess with the MP filters. Highly experimental.
#if (copilot.getNode("controls/lag-time-offset") != nil) {
#        var v = copilot.getNode("controls/lag-time-offset").getValue();
#        copilot.getNode("controls/lag-time-offset").setValue(0.97 * v);
#				}

				foreach (w; in_data) {
					w.update();
				}
				foreach (w; out_data) {
					w.update();
				}

				settimer(update, 0);
				return;
		}
	}
# The copilot player is not around. Idle loop.
	if (active) {
		print("Dual control ... copilot disconnected.");

# Reset copilot controls. Slightly dangerous.
# This could be replaced with a listener on the MP/AI node.
#    setprop("/fdm/jsbsim/fcs/copilot-elevator-cmd-norm", 0.0);
#    setprop("/fdm/jsbsim/fcs/copilot-rudder-cmd-norm", 0.0);
#    setprop("/fdm/jsbsim/fcs/copilot-aileron-cmd-norm", 0.0);
#    setprop(l_dual_control, 0);

		active = 0;
	}
	settimer(update, 3.1415);
}

######################################################################
# Initialization.
setlistener("/sim/signals/fdm-initialized", func {
	settimer(func {
		update();
		print("Pilot dual control ... initialized");
	}, 8);
});

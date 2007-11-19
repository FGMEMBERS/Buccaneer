###############################################################################
## $Id$
##
## Nasal for copilot for dual control over the multiplayer network.
##
##  Copyright (C) 2007  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license.
##
###############################################################################

# Renaming (almost :)
var DCT = dual_control_tools;
var ADC = buccaneer_dual_control;

# Properties for position and orientation of local aircraft.
var l_lat     = "/position/latitude-deg";
var l_lon     = "/position/longitude-deg";
var l_alt     = "/position/altitude-ft";
var l_heading = "/orientation/heading-deg";
var l_pitch   = "/orientation/pitch-deg";
var l_roll    = "/orientation/roll-deg";

# Replicate remote state.
var rpm         = "engines/engine/rpm";
var r_airspeed  = "velocities/true-airspeed-kt";
var l_airspeed  = "/velocities/airspeed-kt";
var vertspeed   = "velocities/vertical-speed-fps";

######################################################################
# Connect to new pilot
var in_data = 0;
var out_data = 0;

var connect = func (pilot) {
  # Set view eye paths.
  setprop("/sim/view[97]/config/eye-lat-deg-path",
          pilot.getNode(DCT.lat_mpp).getPath());
  setprop("/sim/view[97]/config/eye-lon-deg-path",
          pilot.getNode(DCT.lon_mpp).getPath());
  setprop("/sim/eye-alt-ft-path",
          pilot.getNode(DCT.alt_mpp).getPath());

  setprop("/sim/view[97]/config/eye-heading-deg-path",
          pilot.getNode(DCT.heading_mpp).getPath());
  setprop("/sime/view[97]/config/ye-pitch-deg-path",
          pilot.getNode(DCT.pitch_mpp).getPath());
  setprop("/sim/view[97]/config/eye-roll-deg-path",
          pilot.getNode(DCT.roll_mpp).getPath());

  # Tweak MP/AI filters
#  pilot.getNode("controls/allow-extrapolation").setBoolValue(1);
#  pilot.getNode("controls/lag-adjust-system-speed").setValue(5.0);  

  # Set up property mappings.
  in_data = 
	[
	  # Map /postition
#      #DCT.Translator.new
#        (pilot.getNode(DCT.lat_mpp), props.globals.getNode(l_lat)),
#      DCT.Translator.new
#        (pilot.getNode(DCT.lon_mpp), props.globals.getNode(l_lon)),
#      DCT.Translator.new
#        (pilot.getNode(DCT.alt_mpp), props.globals.getNode(l_alt)),
#      # Map /orientation
#      DCT.Translator.new
#        (pilot.getNode(DCT.heading_mpp),
#         props.globals.getNode(l_heading)),
#      DCT.Translator.new
#        (pilot.getNode(DCT.pitch_mpp),
#         props.globals.getNode(l_pitch)),
#      DCT.Translator.new
#        (pilot.getNode(DCT.roll_mpp),
#         props.globals.getNode(l_roll)),
#	  # Map /velocities
#	  DCT.Translator.new
#		(pilot.getNode(r_airspeed),
#		 props.globals.getNode(l_airspeed)),
#	  DCT.Translator.new
#		(pilot.getNode(vertspeed),
#		 props.globals.getNode(vertspeed)),

	] ~ ADC.copilot_in_data(pilot);

  out_data = ADC.copilot_out_data(pilot);

  print("Dual control ... connected to pilot.");
  setprop("/sim/messages/copilot", "Welcome onboard.");
}


######################################################################
# Main loop.
var active = 0;
var update_state = func {
  var mpplayers =
	props.globals.getNode("/ai/models").getChildren("multiplayer");
  var r_callsign = getprop("/sim/remote/pilot-callsign");
#  print("r_callsign ", r_callsign );

  foreach (pilot; mpplayers) {
	if ((pilot.getChild("valid").getValue()) and
		(pilot.getChild("callsign") != nil) and
		(pilot.getChild("callsign").getValue() == r_callsign)) {

	  if (active == 0) {
		active = 1;
		connect(pilot);
	  }

	  # Mess with the MP filters. Highly experimental.
	  if (pilot.getNode("controls/lag-time-offset") != nil) {
#		var v = pilot.getNode("controls/lag-time-offset").getValue();
#		pilot.getNode("controls/lag-time-offset").setValue(0.99 * v);
	  }

	  foreach (w; in_data) {
		w.update();
	  }

	  foreach (w; out_data) {
		w.update();
	  }

	  settimer(update_state, 0);
	  return;
	}
  }
  # The pilot player is not around. Idle loop.
  if (active) {
	active = 0;
	print("Dual control ... disconnected from pilot.");
  }

  settimer(update_state, 3.1415);
}

###############################################################################
# Control wrapper overrides.

# Flap control input is -1 for step decrease; 1 for step increase; 0 idle
controls.flapsDown = func {
  var val = arg[0];
  if(val > 1) { val = 1 } elsif(val < -1) { val = -1 }
  setprop(DCT.copilot_flap_mpp, val);
}

# Brake control
controls.applyBrakes = func(v, which = 0) {
  if (which <= 0) { setprop(DCT.copilot_lbrake_mpp, v); }
  if (which >= 0) { setprop(DCT.copilot_rbrake_mpp, v); }
}

# FIXME: Odd.
controls.applyParkingBrake = func(v) {
  if (!v) { return; }
  setprop(DCT.copilot_lbrake_mpp, -v);
  return 0;
}

###############################################################################
# Initialization.

var last_view = 0;

setlistener("/sim/signals/fdm-initialized", func {
	setlistener("/sim/current-view/view-number", func {
		var vn = getprop("/sim/current-view/view-number");
		print("Index ", view.indexof("Copilot View"));
		var copilot_index = view.indexof("Copilot View");
		if (vn < copilot_index or vn > copilot_index) {
			setprop("/sim/current-view/view-number", view.indexof("Copilot View"));
		}
	});

  settimer(func { 
	update_state();
	print("Copilot dual control ... initialized");
  }, 8);
	});


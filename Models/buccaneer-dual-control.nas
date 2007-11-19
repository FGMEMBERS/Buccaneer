###############################################################################
## $Id$
##
## Nasal for dual control of the c172p over the multiplayer network.
##
##  Copyright (C) 2007  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license.
##
###############################################################################

# Renaming (almost :)
var DCT = dual_control_tools;


# Useful instrument related property paths.

# Flight controls
var rudder_cmd		= "controls/flight/rudder";
var elevator_cmd	= "controls/flight/elevator";
var aileron_cmd		= "controls/flight/aileron";
var throttle_cmd	= "controls/engines/engine/throttle";
var mixture_cmd		= "controls/engines/engine/mixture";
#var elevator_trim_cmd = "controls/flight/elevator-trim";

#Controls
var dump_valve			= "controls/fuel/dump-valve-lever-pos";

# Instruments
var hsi_heading			= "instrumentation/heading-indicator/indicated-heading-deg";
var altimeter_setting	= "instrumentation/altimeter/setting-inhg";
var tc_turn_rate		= "instrumentation/turn-indicator/indicated-turn-rate";
var tc_slip_skid		= "instrumentation/slip-skid-ball/indicated-slip-skid";
var egt_stbd			= "engines/engine[1]/egt-degf";
var egt_port			= "engines/engine/egt-degf";
var sb_hdg_indicator	= "instrumentation/master-reference-gyro[1]/indicated-hdg-deg";
var sb_hdg_ind_bug		= "instrumentation/heading-indicator[1]/heading-bug-deg";
var tank_1_level_lbs	= "consumables/fuel/tank[0]/level-lbs";
var tank_2_level_lbs	= "consumables/fuel/tank[1]/level-lbs";
var tank_3_level_lbs	= "consumables/fuel/tank[2]/level-lbs";
var tank_4_level_lbs	= "consumables/fuel/tank[3]/level-lbs";
var tank_5_level_lbs	= "consumables/fuel/tank[4]/level-lbs";
var tank_6_level_lbs	= "consumables/fuel/tank[5]/level-lbs";
var tank_7_level_lbs	= "consumables/fuel/tank[6]/level-lbs";
var tank_8_level_lbs	= "consumables/fuel/tank[7]/level-lbs";

# Switches
var carb_heat         = "controls/anti-ice/engine/carb-heat";
var pitot_heat        = "controls/anti-ice/pitot-heat";
var taxi_light        = "controls/lighting/taxi-light";
var landing_lights    = "controls/lighting/landing-lights";
var nav_lights        = "controls/lighting/nav-lights";
var beacon_light      = "controls/lighting/beacon";
var strobe_light      = "controls/lighting/strobe";

###############################################################################
# Pilot MP property mappings.

#var l_dual_control         = "fdm/jsbsim/fcs/dual-control";

#var l_throttle_pos         = "fdm/jsbsim/fcs/throttle-pos-norm";
#var l_pilot_throttle_cmd   = "fdm/jsbsim/fcs/throttle-cmd-norm";
#var l_copilot_throttle_cmd = "fdm/jsbsim/fcs/copilot-throttle-cmd-norm";
#var l_shared_throttle_cmd  = "fdm/jsbsim/fcs/shared-throttle-cmd-norm";

#var l_mixture_pos          = "fdm/jsbsim/fcs/mixture-pos-norm";
#var l_pilot_mixture_cmd    = "fdm/jsbsim/fcs/mixture-cmd-norm";
#var l_copilot_mixture_cmd  = "fdm/jsbsim/fcs/copilot-mixture-cmd-norm";
#var l_shared_mixture_cmd   = "fdm/jsbsim/fcs/shared-mixture-cmd-norm";

#var l_elevator_trim_cmd    = "controls/flight/elevator-trim";

var pilot_in_data = func (copilot) {
	return [
# Copilot main flight control
#    DCT.Translator.new
#      (copilot.getNode("surface-positions/elevator-pos-norm"),
#       props.globals.getNode("/fdm/jsbsim/fcs/copilot-elevator-cmd-norm")),
#    DCT.Translator.new
#      (copilot.getNode("surface-positions/left-aileron-pos-norm"),
#       props.globals.getNode("/fdm/jsbsim/fcs/copilot-aileron-cmd-norm")),
#    DCT.Translator.new
#      (copilot.getNode("surface-positions/rudder-pos-norm"),
#       props.globals.getNode("/fdm/jsbsim/fcs/copilot-rudder-cmd-norm")),
#    # Copilot engine control inputs
#    DCT.Translator.new
#      (copilot.getNode(DCT.copilot_throttle_mpp),
#       props.globals.getNode(l_copilot_throttle_cmd)),
#    DCT.Translator.new
#      (copilot.getNode(DCT.copilot_mixture_mpp),
#       props.globals.getNode(l_copilot_mixture_cmd)),
#    # Copilot flap control
#   DCT.EdgeTrigger.new
#      (copilot.getNode(DCT.copilot_flap_mpp),
#       func (v) { controls.flapsDown(v); },
#       func (v) { controls.flapsDown(-v); }),
#    # Copilot brake control
#    DCT.EdgeTrigger.new
#      (copilot.getNode(DCT.copilot_lbrake_mpp),
#       func (v) { controls.applyBrakes(v, -1); },
#       func (v) { controls.applyParkingBrake(v); }),
#    DCT.EdgeTrigger.new
#      (copilot.getNode(DCT.copilot_rbrake_mpp),
#       func (v) { controls.applyBrakes(v, 1); },
#       func (v) { }),
#    # Engine sharing
#    DCT.MostRecentSelector.new
#      (props.globals.getNode(l_pilot_throttle_cmd),
#       props.globals.getNode(l_copilot_throttle_cmd),
#       props.globals.getNode(l_shared_throttle_cmd),
#       threshold = 0.02),
#    DCT.MostRecentSelector.new
#      (props.globals.getNode(l_pilot_mixture_cmd),
#       props.globals.getNode(l_copilot_mixture_cmd),
#       props.globals.getNode(l_shared_mixture_cmd),
#       threshold = 0.02),
#    # Copilot trim control
#   DCT.DeltaAdder.new
#      (copilot.getNode(DCT.copilot_elevator_trim_mpp),
#       props.globals.getNode(l_elevator_trim_cmd)),
# Decode copilot cockpit switch states.
#   NOTE: Actions are only triggered on change.
		DCT.SwitchDecoder.new
			(copilot.getNode(DCT.copilot_switches_mpp),
			[func (b) {
				props.globals.getNode(carb_heat).setValue(b?1:0);
		},
			func (b) {
				props.globals.getNode(taxi_light).setValue(b?1:0);
		},
			func (b) {
				props.globals.getNode(pitot_heat).setValue(b?1:0);
		},
			func (b) {
				props.globals.getNode(nav_lights).setValue(b?1:0);
		},
			func (b) {
				props.globals.getNode(landing_lights).setValue(b?1:0);
		},
			func (b) {
				props.globals.getNode(beacon_light).setValue(b?1:0);
		},
			func (b) {
				props.globals.getNode(strobe_light).setValue(b?1:0);
		},
			]),
	];
}

var pilot_out_data = func (copilot) {
	return [
# ***** Control settings *****
#    DCT.Translator.new
#      (props.globals.getNode(l_throttle_pos),
#       props.globals.getNode(DCT.pilot_throttle_mpp)),
#    DCT.Translator.new
#      (props.globals.getNode(l_mixture_pos),
#       props.globals.getNode(DCT.pilot_mixture_mpp)),
#    DCT.Translator.new
#      (props.globals.getNode(l_elevator_trim_cmd),
#       props.globals.getNode(DCT.pilot_elevator_trim_mpp)),
		DCT.Translator.new
			(props.globals.getNode(dump_valve),
			props.globals.getNode(DCT.pilot_dump_valve_mpp)),

#	***** Instruments *****
#	 # Standby heading indicator
			DCT.Translator.new
			(props.globals.getNode(sb_hdg_indicator),
			props.globals.getNode(DCT.pilot_sb_hdg_indicator_mpp)),
			DCT.Translator.new
			(props.globals.getNode(sb_hdg_ind_bug),
			props.globals.getNode(DCT.pilot_sb_hdg_ind_bug_mpp)),
#	# Fuel Gauge
			DCT.Translator.new
			(props.globals.getNode(tank_1_level_lbs),
			props.globals.getNode(DCT.pilot_tank_1_level_lbs_mpp)),
			DCT.Translator.new
			(props.globals.getNode(tank_2_level_lbs),
			props.globals.getNode(DCT.pilot_tank_2_level_lbs_mpp)),
			DCT.Translator.new
			(props.globals.getNode(tank_3_level_lbs),
			props.globals.getNode(DCT.pilot_tank_3_level_lbs_mpp)),
			DCT.Translator.new
			(props.globals.getNode(tank_4_level_lbs),
			props.globals.getNode(DCT.pilot_tank_4_level_lbs_mpp)),
			DCT.Translator.new
			(props.globals.getNode(tank_5_level_lbs),
			props.globals.getNode(DCT.pilot_tank_5_level_lbs_mpp)),
			DCT.Translator.new
			(props.globals.getNode(tank_6_level_lbs),
			props.globals.getNode(DCT.pilot_tank_6_level_lbs_mpp)),
			DCT.Translator.new
			(props.globals.getNode(tank_7_level_lbs),
			props.globals.getNode(DCT.pilot_tank_7_level_lbs_mpp)),
			DCT.Translator.new
			(props.globals.getNode(tank_8_level_lbs),
			props.globals.getNode(DCT.pilot_tank_8_level_lbs_mpp)),
#    # HSI indicated heading.
#    DCT.Translator.new
#      (props.globals.getNode(hsi_heading),
#       props.globals.getNode(DCT.pilot_hsi_head_mpp)),
#    # Altimeter setting.
#    DCT.Translator.new
#      (props.globals.getNode(altimeter_setting),
#       props.globals.getNode(DCT.pilot_altimeter_setting_mpp)),
#    # Turn coordinator turn rate.
#    DCT.Translator.new
#      (props.globals.getNode(tc_turn_rate),
#       props.globals.getNode(DCT.pilot_tc_turn_rate)),
#   # Turn coordinator slip skid.
#    DCT.Translator.new
#      (props.globals.getNode(tc_slip_skid),
#       props.globals.getNode(DCT.pilot_tc_slip_skid)),
# Engine egt.
			DCT.Translator.new
			(props.globals.getNode(egt_stbd),
			props.globals.getNode(DCT.pilot_egt_stbd_mpp)),   
			DCT.Translator.new
			(props.globals.getNode(egt_port),
			props.globals.getNode(DCT.pilot_egt_port_mpp)),
#    # Encoding of on/off switches.
#    DCT.SwitchEncoder.new
#      ([props.globals.getNode("controls/anti-ice/engine/carb-heat"),
#        props.globals.getNode("controls/lighting/taxi-light"),
#        props.globals.getNode("controls/anti-ice/pitot-heat"),
#        props.globals.getNode("controls/lighting/nav-lights"),
#        props.globals.getNode("controls/lighting/landing-lights"),
#        props.globals.getNode("controls/lighting/beacon"),
#        props.globals.getNode("controls/lighting/strobe"),
#       ],
#       props.globals.getNode(DCT.pilot_switches_mpp))
	];
}

###############################################################################
# Copilot MP property mappings.

var copilot_in_data = func (pilot) {
	return [
# Map combined throttle cmd for animation.
#    DCT.Translator.new
#      (pilot.getNode(DCT.pilot_throttle_mpp),
#       pilot.getNode("fdm/jsbsim/fcs/throttle-pos-norm")),
#    # Map combined mixture cmd for animation.
#    DCT.Translator.new
#      (pilot.getNode(DCT.pilot_mixture_mpp),
#       pilot.getNode("fdm/jsbsim/fcs/mixture-pos-norm")),
#    # Map elevator trim for animation
#    DCT.Translator.new
#      (pilot.getNode(DCT.pilot_elevator_trim_mpp),
#       pilot.getNode(elevator_trim_cmd)),
#    # Map flap-pos-norm for flap sound.
#    DCT.Translator.new
#      (pilot.getNode(DCT.pilot_flap_mpp),
#       props.globals.getNode("/fdm/jsbsim/fcs/flap-pos-norm", 1)),

#		***** Controls *****
		DCT.Translator.new
			(pilot.getNode(DCT.pilot_dump_valve_mpp),
			pilot.getNode(dump_valve)),

#    # Map airspeed for airspeed indicator. This is cheating!
#     DCT.Translator.new
#      (pilot.getNode("velocities/true-airspeed-kt"),
#       props.globals.getNode("/instrumentation/" ~
#                             "airspeed-indicator/indicated-speed-kt", 1)),
#    # Map altitude for altimeter. This is cheating!
#    DCT.Translator.new
#      (pilot.getNode(DCT.alt_mpp),
#       props.globals.getNode("/instrumentation/" ~
#                             "altimeter/indicated-altitude-ft", 1)),
#    # Map HSI indicated heading.
#    DCT.Translator.new
#      (pilot.getNode(DCT.pilot_hsi_head_mpp),
#       props.globals.getNode(hsi_heading)),
#    # Map altimeter setting
#    DCT.Translator.new
#      (pilot.getNode(DCT.pilot_altimeter_setting_mpp),
#       props.globals.getNode(altimeter_setting)),
#    # Map turn coordinator turn rate.
#    DCT.Translator.new
#      (pilot.getNode(DCT.pilot_tc_turn_rate),
#       props.globals.getNode(tc_turn_rate)),
#    # Map turn coordinator slip skid.
#    DCT.Translator.new
#      (pilot.getNode(DCT.pilot_tc_slip_skid),
#      props.globals.getNode(tc_slip_skid)),
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_sb_hdg_indicator_mpp),
			pilot.getNode(sb_hdg_indicator)),
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_sb_hdg_ind_bug_mpp),
			pilot.getNode(sb_hdg_ind_bug)),
#	# Map engine.egt
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_egt_stbd_mpp),
			pilot.getNode(egt_stbd)), 
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_egt_port_mpp),
			pilot.getNode(egt_port)),
#	# Map Fuel Gauge
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_tank_1_level_lbs_mpp),
			pilot.getNode(tank_1_level_lbs)),
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_tank_2_level_lbs_mpp),
			pilot.getNode(tank_2_level_lbs)),
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_tank_3_level_lbs_mpp),
			pilot.getNode(tank_3_level_lbs)),
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_tank_4_level_lbs_mpp),
			pilot.getNode(tank_4_level_lbs)),
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_tank_5_level_lbs_mpp),
			pilot.getNode(tank_5_level_lbs)),
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_tank_6_level_lbs_mpp),
			pilot.getNode(tank_6_level_lbs)),
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_tank_7_level_lbs_mpp),
			pilot.getNode(tank_7_level_lbs)),
			DCT.Translator.new
			(pilot.getNode(DCT.pilot_tank_8_level_lbs_mpp),
			pilot.getNode(tank_8_level_lbs)),
#    # Map M877 clock properties to pilot 3d model.
#    DCT.Translator.new
#      (props.globals.getNode("instrumentation/clock/m877/mode"),
#       pilot.getNode("instrumentation/clock/m877/mode")),
#    DCT.Translator.new
#      (props.globals.getNode("instrumentation/clock/m877/indicated-hour"),
#       pilot.getNode("instrumentation/clock/m877/indicated-hour")),
#    DCT.Translator.new
#      (props.globals.getNode("instrumentation/clock/m877/indicated-min"),
#       pilot.getNode("instrumentation/clock/m877/indicated-min")),
#    # Decode pilot cockpit switch states.
#    DCT.SwitchDecoder.new
#      (pilot.getNode(DCT.pilot_switches_mpp),
#       [func (b) {
#         pilot.getNode(carb_heat).setValue(b?1:0);
#         props.globals.getNode(carb_heat).setValue(b?1:0);
#        },
#        func (b) {
#         pilot.getNode(taxi_light).setValue(b?1:0);
#         props.globals.getNode(taxi_light).setValue(b?1:0);
#        },
#        func (b) {
#         pilot.getNode(pitot_heat).setValue(b?1:0);
#         props.globals.getNode(pitot_heat).setValue(b?1:0);
#        },
#        func (b) {
#         pilot.getNode(nav_lights).setValue(b?1:0);
#         props.globals.getNode(nav_lights).setValue(b?1:0);
#        },
#        func (b) {
#         pilot.getNode(landing_lights).setValue(b?1:0);
#         props.globals.getNode(landing_lights).setValue(b?1:0);
#        },
#        func (b) {
#         pilot.getNode(beacon_light).setValue(b?1:0);
#         props.globals.getNode(beacon_light).setValue(b?1:0);
#        },
#        func (b) {
#         pilot.getNode(strobe_light).setValue(b?1:0);
#         props.globals.getNode(strobe_light).setValue(b?1:0);
#        },
#      ]),
	];
}

var copilot_out_data = func (pilot) {
	return [ 
# Map copilot flight controls to MP properties.
#    DCT.Translator.new
#      (props.globals.getNode(rudder_cmd),
#       props.globals.getNode(DCT.copilot_rudder_mpp), factor = -1),
#    DCT.Translator.new
#      (props.globals.getNode(elevator_cmd),
#       props.globals.getNode(DCT.copilot_elevator_mpp)),
#    DCT.Translator.new
#      (props.globals.getNode(aileron_cmd),
#       props.globals.getNode(DCT.copilot_aileron_mpp)),
#    DCT.Translator.new
#      (props.globals.getNode(throttle_cmd),
#       props.globals.getNode(DCT.copilot_throttle_mpp)),
#    DCT.Translator.new
#      (props.globals.getNode(mixture_cmd),
#       props.globals.getNode(DCT.copilot_mixture_mpp)),
#    DCT.Translator.new
#      (props.globals.getNode(elevator_trim_cmd),
#       props.globals.getNode(DCT.copilot_elevator_trim_mpp)),
#    DCT.SwitchEncoder.new
#      ([props.globals.getNode(carb_heat),
#        props.globals.getNode(taxi_light),
#       props.globals.getNode(pitot_heat),
#        props.globals.getNode(nav_lights),
#        props.globals.getNode(landing_lights),
#        props.globals.getNode(beacon_light),
#        props.globals.getNode(strobe_light),
#       ],
#     props.globals.getNode(DCT.copilot_switches_mpp))
	];
}

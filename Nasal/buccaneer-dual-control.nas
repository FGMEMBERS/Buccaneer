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

######################################################################
# Pilot/copilot aircraft identifiers.
var pilot_type   = "buccaneer";
var copilot_type = "buccaneer-obs";

# MP enabled properties.
# NOTE: These must exist very early during startup - put them
#       in the -set.xml file.
## MP properties
var lat_mpp							= "position/latitude-deg";
var lon_mpp							= "position/longitude-deg";
var alt_mpp							= "position/altitude-ft";
var heading_mpp						= "orientation/true-heading-deg";
var pitch_mpp						= "orientation/pitch-deg";
var roll_mpp						= "orientation/roll-deg";

var pilot_rudder_mpp				= "surface-positions/rudder-pos-norm";
var pilot_elevator_mpp				= "surface-positions/elevator-pos-norm";
var pilot_aileron_mpp				= "surface-positions/left-aileron-pos-norm";
var pilot_flap_mpp					= "surface-positions/flap-pos-norm";
var pilot_throttle_mpp				= "rotors/main/blade[0]/position-deg";

var	pilot_g_damped_mpp				= "engines/engine[2]/rpm";

#pilot controls
var pilot_dump_valve_mpp			= "rotors/main/blade[1]/position-deg";

#pilot instruments
var pilot_egt_stbd_mpp				= "rotors/main/rpm";
var pilot_egt_port_mpp				= "rotors/tail/rpm";
var pilot_hsi_head_mpp				= "rotors/tail/blade[0]/position-deg";
var pilot_altimeter_setting_mpp		= "rotors/tail/blade[1]/position-deg";
var pilot_tc_turn_rate_mpp			= "rotors/main/blade[3]/position-deg";
var pilot_tc_slip_skid_mpp			= "rotors/main/blade[3]/flap-deg";
var pilot_sb_hdg_indicator_mpp		= "rotors/main/blade[1]/flap-deg";
var pilot_sb_hdg_ind_bug_mpp		= "rotors/main/blade[2]/flap-deg";
#var pilot_tank_1_level_lbs_mpp		= "engines/engine[2]/n1";
#var pilot_tank_2_level_lbs_mpp		= "engines/engine[2]/n2";
#var pilot_tank_3_level_lbs_mpp		= "engines/engine[3]/n1";
#var pilot_tank_4_level_lbs_mpp		= "engines/engine[3]/n2";
#var pilot_tank_5_level_lbs_mpp		= "engines/engine[4]/n1";
#var pilot_tank_6_level_lbs_mpp		= "engines/engine[4]/n2";
#var pilot_tank_7_level_lbs_mpp		= "engines/engine[5]/n1";
#var pilot_tank_8_level_lbs_mpp		= "engines/engine[5]/n2";

#pilot switches
var pilot_switches_mpp				= "engines/engine[3]/rpm";

#pilot slow signal interface
var pilot_TDM1_mpp = "engines/engine[2]/n1";
var pilot_TDM2_mpp = "engines/engine[2]/n2";
var pilot_TDM3_mpp = "engines/engine[3]/n1";
var pilot_TDM4_mpp = "engines/engine[3]/n2";

# ********* copilot ***************

#var copilot_rudder_mpp				= "surface-positions/rudder-pos-norm";
#var copilot_elevator_mpp			= "surface-positions/elevator-pos-norm";
#var copilot_aileron_mpp			= "surface-positions/left-aileron-pos-norm";
#var copilot_flap_mpp				= "surface-positions/flap-pos-norm";
#var copilot_lbrake_mpp				= "surface-positions/right-aileron-pos-norm";
#var copilot_rbrake_mpp				= "surface-positions/speedbrake-pos-norm";
#var copilot_throttle_mpp			= "rotors/main/blade[0]/position-deg";

var	copilot_g_damped_mpp		= "engines/engine[2]/rpm";

#copilot controls
var copilot_dump_valve_mpp			= "rotors/main/blade[1]/position-deg";

#copilot instruments
var copilot_egt_stbd_mpp			= "rotors/main/rpm";
var copilot_egt_port_mpp			= "rotors/tail/rpm";
var copilot_hsi_head_mpp			= "rotors/tail/blade[0]/position-deg";
var copilot_altimeter_setting_mpp	= "rotors/tail/blade[1]/position-deg";
var copilot_sb_hdg_indicator_mpp	= "rotors/main/blade[1]/flap-deg";
var copilot_tc_turn_rate			= "rotors/main/blade[3]/position-deg";
var copilot_tc_slip_skid			= "rotors/main/blade[3]/flap-deg";
var copilot_sb_hdg_ind_bug_mpp		= "rotors/main/blade[2]/flap-deg";


#copilot switches
var copilot_switches_mpp			= "engines/engine[3]/rpm";

#co-pilot slow signal interface
var copilot_TDM1_mpp = "engines/engine[2]/n1";
var copilot_TDM2_mpp = "engines/engine[2]/n2";
var copilot_TDM3_mpp = "engines/engine[3]/n1";
var copilot_TDM4_mpp = "engines/engine[3]/n2";

######################################################################


######################################################################
# Useful instrument related property paths.

# Flight controls
var rudder_cmd			= "controls/flight/rudder";
var elevator_cmd		= "controls/flight/elevator";
var aileron_cmd			= "controls/flight/aileron";
var throttle_cmd		= "controls/engines/engine/throttle";
var mixture_cmd			= "controls/engines/engine/mixture";
var elevator_trim_cmd	= "controls/flight/elevator-trim";

var pilot_g_damped		= "accelerations/pilot-g-damped";

#Controls
var dump_valve			= "controls/fuel/dump-valve-lever-pos";
var panel_lighting		= "controls/lighting/panel-norm";
var engine_smoking_port	= "engines/engine/smoking";
var engine_smoking_stbd	= "engines/engine[1]/smoking";
var dump_rate_port		= "consumables/fuel/tank[8]/dump-rate-lbs-hr";
var dump_rate_stbd		= "consumables/fuel/tank[9]/dump-rate-lbs-hr";
var instrument_lights	= "systems/electrical/outputs/instrument-lighting";

# Instruments
var hsi_heading			= "instrumentation/heading-indicator/indicated-heading-deg";
var altimeter_setting	= "instrumentation/altimeter/setting-inhg";
var tc_turn_rate		= "instrumentation/turn-indicator/indicated-turn-rate";
var tc_slip_skid		= "instrumentation/slip-skid-ball/indicated-slip-skid";
var rpm					= "engines/engine/rpm";
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
var carb_heat			= "controls/anti-ice/engine/carb-heat";
var pitot_heat			= "controls/anti-ice/pitot-heat";
var taxi_light			= "controls/lighting/taxi-light";
var landing_lights		= "controls/lighting/landing-lights";
var beacon_light		= "controls/lighting/beacon";
var strobe_light		= "controls/lighting/strobe";





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


    ##################################################
    # Set up TDM reception of slow state properties.
#    DCT.TDMDecoder.new
#      (copilot.getNode(copilot_TDM1_mpp),
#       copilot.getNode(copilot_TDM2_mpp),
#       [func (v) {
#          props.globals.getNode(nav0_radial).setValue(v);
#        },
#        func (v) {
#          props.globals.getNode(nav1_radial).setValue(v);
#        },
#       ]),
  ];
}

var pilot_out_data = func (copilot) {
  return [
    ##################################################
    # Control settings
#    DCT.Translator.new
#      (props.globals.getNode(l_throttle_pos),
#       props.globals.getNode(pilot_throttle_mpp)),
#    DCT.Translator.new
#      (props.globals.getNode(l_mixture_pos),
#       props.globals.getNode(pilot_mixture_mpp)),
#    DCT.Translator.new
#      (props.globals.getNode(l_elevator_trim_cmd),
#       props.globals.getNode(pilot_elevator_trim_mpp)),
	  DCT.Translator.new
		  (props.globals.getNode(dump_valve),
		  props.globals.getNode(pilot_dump_valve_mpp)),
	  DCT.Translator.new
		  (props.globals.getNode(pilot_g_damped),
		  props.globals.getNode(pilot_g_damped_mpp)),
    ##################################################

# Instrument readings.
# Standby heading indicator
		  DCT.Translator.new
		  (props.globals.getNode(sb_hdg_indicator),
		  props.globals.getNode(pilot_sb_hdg_indicator_mpp)),
#	# Map engine.egt
		  DCT.Translator.new
		  (props.globals.getNode(egt_stbd),
		  props.globals.getNode(pilot_egt_stbd_mpp)), 
		  DCT.Translator.new
		  (props.globals.getNode(egt_port),
		  props.globals.getNode(pilot_egt_port_mpp)),
# HSI indicated heading.
#    DCT.Translator.new
#      (props.globals.getNode(hsi_heading),
#       props.globals.getNode(pilot_hsi_head_mpp)),
#    # Turn coordinator turn rate.
#    DCT.Translator.new
#      (props.globals.getNode(tc_turn_rate),
#       props.globals.getNode(pilot_tc_turn_rate_mpp)),
#    # Turn coordinator slip skid.
#    DCT.Translator.new
#      (props.globals.getNode(tc_slip_skid),
#       props.globals.getNode(pilot_tc_slip_skid_mpp)),
    ##################################################
###
###
    # Encoding of on/off switches.
		  DCT.SwitchEncoder.new
		  ([props.globals.getNode("engines/engine/smoking"),
		  props.globals.getNode("engines/engine[1]/smoking"),
#        props.globals.getNode("controls/anti-ice/pitot-heat"),
#        props.globals.getNode("controls/lighting/nav-lights"),
#        props.globals.getNode("controls/lighting/landing-lights"),
#        props.globals.getNode("controls/lighting/beacon"),
#        props.globals.getNode("controls/lighting/strobe"),
		  ],
		  props.globals.getNode(pilot_switches_mpp)),
##################################################
# Set up TDM transmission of slow state properties.
	  DCT.TDMEncoder.new
	  (
	  [props.globals.getNode(altimeter_setting),
	  props.globals.getNode(sb_hdg_ind_bug),
	  props.globals.getNode(instrument_lights),
	  ],
	  props.globals.getNode(pilot_TDM3_mpp),
	  props.globals.getNode(pilot_TDM4_mpp),
	  ),
# Set up TDM transmission of slow state properties.
	  DCT.TDMEncoder.new
	  (
	  [props.globals.getNode(tank_1_level_lbs),
	  props.globals.getNode(tank_2_level_lbs),
	  props.globals.getNode(tank_3_level_lbs),
	  props.globals.getNode(tank_4_level_lbs),
	  props.globals.getNode(tank_5_level_lbs),
	  props.globals.getNode(tank_6_level_lbs),
	  props.globals.getNode(tank_7_level_lbs),
	  props.globals.getNode(tank_8_level_lbs),
	  props.globals.getNode(dump_rate_port),
	  props.globals.getNode(dump_rate_stbd),
	  ],
	  props.globals.getNode(pilot_TDM1_mpp),
	  props.globals.getNode(pilot_TDM2_mpp),
	  ),	
  ];
}

###############################################################################
# Copilot MP property mappings.

var copilot_in_data = func (pilot) {
  # Initialize Nasal wrappers for copilot pick anaimations.
#   set_copilot_wrappers(pilot);

  return [
    ##################################################
    # Map properties for animation and sound.
    # Map combined throttle cmd for animation.
#    DCT.Translator.new
#      (pilot.getNode(pilot_throttle_mpp),
#       pilot.getNode("fdm/jsbsim/fcs/throttle-pos-norm")),
#    # Map elevator trim for animation
#    DCT.Translator.new
#      (pilot.getNode(pilot_elevator_trim_mpp),
#       pilot.getNode(elevator_trim_cmd)),
#    # Map /engines/engine/rpm for sound and RPM instrument.
#    DCT.Translator.new
#      (pilot.getNode(rpm),
#       props.globals.getNode(rpm)),
##    DCT.Translator.new
#      (pilot.getNode(pilot_flap_mpp),
#       props.globals.getNode("/fdm/jsbsim/fcs/flap-pos-norm", 1)),
#    # Map airspeed for airspeed indicator. This is cheating!
#    DCT.Translator.new
#      (pilot.getNode("velocities/true-airspeed-kt"),
#       props.globals.getNode("/instrumentation/" ~
#                             "airspeed-indicator/indicated-speed-kt", 1)),
	  DCT.Translator.new
		  (pilot.getNode(pilot_dump_valve_mpp),
		  pilot.getNode(dump_valve)),
	   DCT.Translator.new
		  (pilot.getNode(pilot_g_damped_mpp),
		  props.globals.getNode(pilot_g_damped)),

#	***** Instruments *****
#	 # Standby heading indicator
		  DCT.Translator.new
		  (pilot.getNode(pilot_sb_hdg_indicator_mpp),
		  pilot.getNode(sb_hdg_indicator)),
#	# Map engine.egt
		  DCT.Translator.new
		  (pilot.getNode(pilot_egt_stbd_mpp),
		  pilot.getNode(egt_stbd)), 
		  DCT.Translator.new
		  (pilot.getNode(pilot_egt_port_mpp),
		  pilot.getNode(egt_port)),
# Map HSI indicated heading.
		  DCT.Translator.new
		  (pilot.getNode(pilot_hsi_head_mpp),
		  props.globals.getNode(hsi_heading)),
# Map turn coordinator turn rate.
		  DCT.Translator.new
		  (pilot.getNode(pilot_tc_turn_rate_mpp),
		  props.globals.getNode(tc_turn_rate)),
# Map turn coordinator slip skid.
		  DCT.Translator.new
		  (pilot.getNode(pilot_tc_slip_skid_mpp),
		  props.globals.getNode(tc_slip_skid)),


##################################################
# Decode pilot cockpit switch states for animation and control.
		  DCT.SwitchDecoder.new
		  (pilot.getNode(pilot_switches_mpp),
		  [func (b) {
			  pilot.getNode(engine_smoking_port).setBoolValue(b?1:0);
	  },
		  func (b) {
			  pilot.getNode(engine_smoking_stbd).setBoolValue(b?1:0);
	  },
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
		  ]),
##################################################
# Set up 2nd TDM reception of slow state properties.
		  DCT.TDMDecoder.new
		  (pilot.getNode(pilot_TDM3_mpp),
		  pilot.getNode(pilot_TDM4_mpp),
		  [func (v) {
			  pilot.getNode(altimeter_setting).setValue(v);
			  print("altimeter setting: ", v);
		  },
		  func (v) {
			  pilot.getNode(sb_hdg_ind_bug).setValue(v);
			  print("sb_hdg_ind_bug: ", v);
		  },
		  func (v) {
			  pilot.getNode(instrument_lights).setValue(v);
			  print("instrument_lights: ", v);
		  },
		  ],
		  ),
# Set up TDM reception of slow state properties.
		  DCT.TDMDecoder.new
		  (pilot.getNode(pilot_TDM1_mpp),
		  pilot.getNode(pilot_TDM2_mpp),
		  [func (v) {
			  pilot.getNode(tank_1_level_lbs).setValue(v);
			  print("tank 1 level: ", v);
	  },
		  func (v) {
			  pilot.getNode(tank_2_level_lbs).setValue(v);
			  print("tank 2 level: ", v);
	  },
		  func (v) {
			  pilot.getNode(tank_3_level_lbs).setValue(v);
			  print("tank 3 level: ", v);
		  },
		  func (v) {
			  pilot.getNode(tank_4_level_lbs).setValue(v);
			  print("tank 4 level: ", v);
		  },
		  func (v) {
			  pilot.getNode(tank_5_level_lbs).setValue(v);
			  print("tank 5 level: ", v);
		  },
			  func (v) {
			  pilot.getNode(tank_6_level_lbs).setValue(v);
			  print("tank 6 level: ", v);
	  },
		  func (v) {
			  pilot.getNode(tank_7_level_lbs).setValue(v);
			  print("tank 7 level: ", v);
	  },
		  func (v) {
			  pilot.getNode(tank_8_level_lbs).setValue(v);
			  print("tank 8 level: ", v);
	  },
		  func (v) {
			  pilot.getNode(dump_rate_port).setValue(v);
			  print("dump rate port: ", v);
	  },
		  func (v) {
			  pilot.getNode(dump_rate_stbd).setValue(v);
			  print("dump rate stbd: ", v);
	  },
		  ],
		  ),

  ];
}

var copilot_out_data = func (pilot) {
  return [

    ##################################################
    # Encoding of on/off switches.
#    DCT.SwitchEncoder.new
#      ([
#        props.globals.getNode(carb_heat),
#        props.globals.getNode(nav0_freq_incL, 1),
#       ],
#     props.globals.getNode(copilot_switches_mpp)),
    ##################################################
    # Set up TDM transmission of slow state properties.
#    DCT.TDMEncoder.new
#      ([props.globals.getNode(nav0_radial),
#        props.globals.getNode(nav1_radial),
#       ],
#       props.globals.getNode(copilot_TDM1_mpp),
#       props.globals.getNode(copilot_TDM2_mpp),
#      )
  ];
}




###############################################################################
## $Id$
##
## Nasal for dual control of the buccaneer over the multiplayer network.
##
##  Copyright (C) 2009  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license version 2 or later.
##
###############################################################################

# Renaming (almost :)
var DCT = dual_control_tools;

######################################################################
# Pilot/copilot aircraft identifiers. Used by dual_control.
var pilot_type   = "Aircraft/Buccaneer/Models/buccaneer-model.xml";
var copilot_type = "Aircraft/Buccaneer/Models/buccaneer-obs-model.xml";
var copilot_view = "Back Seat View";

props.globals.initNode("/sim/remote/pilot-callsign", "", "STRING");

######################################################################
# MP enabled properties.
# NOTE: These must exist very early during startup - put them
#       in the -set.xml file.


######################################################################
# Useful local property paths.

# Flight controls
# Engines
# Instruments

######################################################################
# Slow state properties for replication.

var fcs = "fdm/jsbsim/fcs";

###############################################################################
# Pilot MP property mappings and specific copilot connect/disconnect actions.

######################################################################
# Used by dual_control to set up the mappings for the pilot.
var pilot_connect_copilot = func (copilot) {
    # Make sure dual-control is activated in the FDM FCS.

    return 
        [
         ######################################################################
         # Process received properties.
         ######################################################################
         ######################################################################
         # Process properties to send.
         ######################################################################
        ];
}

######################################################################
var pilot_disconnect_copilot = func {
    # Reset copilot controls. Slightly dangerous.
}


###############################################################################
# Copilot MP property mappings and specific pilot connect/disconnect actions.

l_flap_up_cmd   = "controls/flight/flaps-up";
l_flap_down_cmd = "controls/flight/flaps-down";
ll_gear_up_cmd   = "controls/flight/gear-up";
l_gear_down_cmd = "controls/flight/gear-down";

######################################################################
# Used by dual_control to set up the mappings for the copilot.
var copilot_connect_pilot = func (pilot) {
    # Initialize Nasal wrappers and aliases for copilot pick anaimations etc.
    set_copilot_wrappers(pilot);

    return
        [
         ######################################################################
         # Process received properties.
         ######################################################################
         ##################################################
         # Map airspeed for airspeed indicator. This is cheating!
         DCT.Translator.new
         (pilot.getNode("velocities/true-airspeed-kt"),
          props.globals.getNode("/instrumentation/" ~
                                "airspeed-indicator/indicated-speed-kt", 1)),

         ######################################################################
         # Process properties to send.
         ######################################################################
        ];
}

######################################################################
var copilot_disconnect_pilot = func {
}

######################################################################
# Copilot Nasal wrappers

var set_copilot_wrappers = func (pilot) {
    #######################################################
    # controls.nas wrapper overrides.

    # Flap control input is -1 for step decrease; 1 for step increase; 0 idle
    controls.flapsDown = func (v) {
        if(v > 0) {
            setprop(l_flap_up_cmd, 1);
            settimer(func { setprop(l_flap_up_cmd, 0); },
                     1.0);
        } elsif(v < 0) {
            setprop(l_flap_down_cmd, 1);
            settimer(func { setprop(l_flap_down_cmd, 0); },
                     1.0);
        } else {
            return;
        }
    }
    # Gear control input is -1 for retract; 1 for extend; 0 idle
    controls.gearDown = func(v) {
        if(v < 0) {
            setprop(l_gear_up_cmd, 1);
            settimer(func { setprop(l_gear_up_cmd, 0); },
                     1.0);
        } elsif(v > 0) {
            setprop(l_gear_down_cmd, 1);
            settimer(func { setprop(l_gear_down_cmd, 0); },
                     1.0);
        } else {
            return;
        }
    }

    #######################################################
    # Set up property aliases for animating the MP/AI model

    var p = "sim/model/buccaneer/config/show-pilot";
    pilot.getNode(p, 1).alias(props.globals.initNode(p, 1, "BOOL"));

    # Map airspeed for airspeed indicator. This is cheating!
    props.globals.
        getNode("instrumentation/airspeed-indicator/indicated-speed-kt", 1).
            alias(pilot.getNode("velocities/true-airspeed-kt"));
    pilot.
        getNode("instrumentation/airspeed-indicator/indicated-speed-kt", 1).
            alias(pilot.getNode("velocities/true-airspeed-kt"));
    
    # Map altimeter to 3d model.
    p = "instrumentation/altimeter/indicated-altitude-ft";
    pilot.getNode(p, 1).alias(props.globals.getNode(p));
}

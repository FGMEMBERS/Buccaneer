###############################################################################
## $Id$
##
## Nasal module for dual control over the multiplayer network.
##
##  Copyright (C) 2007  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license.
##
###############################################################################

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

#pilot controls
var pilot_dump_valve_mpp			= "rotors/main/blade[1]/position-deg";

#pilot instruments
var pilot_egt_stbd_mpp				= "rotors/main/rpm";
var pilot_egt_port_mpp				= "rotors/tail/rpm";
var pilot_hsi_head_mpp				= "rotors/tail/blade[0]/position-deg";
var pilot_altimeter_setting_mpp		= "rotors/tail/blade[1]/position-deg";
var pilot_tc_turn_rate				= "rotors/main/blade[3]/position-deg";
var pilot_tc_slip_skid				= "rotors/main/blade[3]/flap-deg";
var pilot_sb_hdg_indicator_mpp		= "rotors/main/blade[1]/flap-deg";
var pilot_sb_hdg_ind_bug_mpp		= "rotors/main/blade[2]/flap-deg";
var pilot_tank_1_level_lbs_mpp		= "engines/engine[2]/n1";
var pilot_tank_2_level_lbs_mpp		= "engines/engine[2]/n2";
var pilot_tank_3_level_lbs_mpp		= "engines/engine[3]/n1";
var pilot_tank_4_level_lbs_mpp		= "engines/engine[3]/n2";
var pilot_tank_5_level_lbs_mpp		= "engines/engine[4]/n1";
var pilot_tank_6_level_lbs_mpp		= "engines/engine[4]/n2";
var pilot_tank_7_level_lbs_mpp		= "engines/engine[5]/n1";
var pilot_tank_8_level_lbs_mpp		= "engines/engine[5]/n2";
  
#pilot switches
var pilot_switches_mpp				= "sim/model/variant";

# ********* copilot ***************

var copilot_rudder_mpp				= "surface-positions/rudder-pos-norm";
var copilot_elevator_mpp			= "surface-positions/elevator-pos-norm";
var copilot_aileron_mpp				= "surface-positions/left-aileron-pos-norm";
var copilot_flap_mpp				= "surface-positions/flap-pos-norm";
var copilot_lbrake_mpp				= "surface-positions/right-aileron-pos-norm";
var copilot_rbrake_mpp				= "surface-positions/speedbrake-pos-norm";
var copilot_throttle_mpp			= "rotors/main/blade[0]/position-deg";

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
var copilot_tank_1_level_lbs_mpp	= "engines/engine[2]/n1";
var copilot_tank_2_level_lbs_mpp	= "engines/engine[2]/n2";
var copilot_tank_3_level_lbs_mpp	= "engines/engine[3]/n1";
var copilot_tank_4_level_lbs_mpp	= "engines/engine[3]/n2";
var copilot_tank_5_level_lbs_mpp	= "engines/engine[4]/n1";
var copilot_tank_6_level_lbs_mpp	= "engines/engine[4]/n2";
var copilot_tank_7_level_lbs_mpp	= "engines/engine[5]/n1";
var copilot_tank_8_level_lbs_mpp	= "engines/engine[5]/n2";


#copilot switches
var copilot_switches_mpp			= "sim/model/variant";



###############################################################################
# Utility classes

############################################################
# Translate a property into another.
Translator = {};
Translator.new = func (src = nil, dest = nil, factor = 1, offset = 0) {
  obj = { parents   : [Translator],
          src       : src,
          dest      : dest,
          factor    : factor,
          offset    : offset };
  if (obj.src == nil or obj.dest == nil) {
    print("Translator[");
    print("  ", debug.string(obj.src));
    print("  ", debug.string(obj.dest));
    print("]");
  }

  return obj;
}
Translator.update = func () {
  me.dest.setValue(me.factor * me.src.getValue() + me.offset);
}

############################################################
# Detects flanks on two insignals encoded in a property.
# - positive signal up/down flank
# - negative signal up/down flank
EdgeTrigger = {};
EdgeTrigger.new = func (n, on_positive_flank, on_negative_flank) {
  obj = { parents   : [EdgeTrigger],
          old       : 0,
          node      : n, 
          pos_flank : on_positive_flank,
          neg_flank : on_negative_flank };
  if (obj.node == nil) {
    print("EdgeTrigger[");
    print("  ", debug.string(obj.node));
    print("]");
  }
  return obj;
}
EdgeTrigger.update = func {
  # NOTE: float MP properties get interpolated.
  #       This detector relies on that steady state is reached between
  #       flanks.
  var val = me.node.getValue();
  if (me.old == 1) {
    if (val < me.old) {
      me.pos_flank(0);
    }
  } elsif (me.old == 0) {
    if (val > me.old) {
      me.pos_flank(1);
    } elsif (val < me.old) {
      me.neg_flank(1);
    }
  } elsif (me.old == -1) {
    if (val > me.old) {
      me.neg_flank(0);
    }
  }
  me.old = val;
}

############################################################
# Selects the most recent value of two properties.
MostRecentSelector = {};
MostRecentSelector.new = func (src1, src2, dest, threshold) {
  obj = { parents   : [MostRecentSelector],
          old1      : 0,
          old2      : 0,
          src1      : src1,
          src2      : src2,
          dest      : dest,
          thres     : threshold };
  if (obj.src1 == nil or obj.src2 == nil or obj.dest == nil) {
    print("MostRecentSelector[");
    print("  ", debug.string(obj.src1));
    print("  ", debug.string(obj.src2));
    print("  ", debug.string(obj.dest));
    print("]");
  }

  return obj;
}
MostRecentSelector.update = func {
  if (abs (me.src2.getValue() - me.old2) > me.thres) {
    me.old2 = me.src2.getValue();
    me.dest.setValue(me.old2);
  }
  if (abs (me.src1.getValue() - me.old1) > me.thres) {
    me.old1 = me.src1.getValue();
    me.dest.setValue(me.old1);
  }
}

############################################################
# Adds two input properties.
Adder = {};
Adder.new = func (src1, src2, dest) {
  obj = { parents : [DeltaAccumulator],
          src1    : src1,
          src2    : src2,
          dest    : dest };
  if (obj.src1 == nil or obj.src2 == nil or obj.dest == nil) {
    print("Adder[");
    print("  ", debug.string(obj.src1));
    print("  ", debug.string(obj.src2));
    print("  ", debug.string(obj.dest));
    print("]");
  }

  return obj;
}
Adder.update = func () {
  me.dest.setValue(me.src1.getValue() + me.src2.getValue());
}

############################################################
# Adds the delta of src to dest.
DeltaAdder = {};
DeltaAdder.new = func (src, dest) {
  obj = { parents : [DeltaAdder],
          old     : 0,
          src     : src,
          dest    : dest };
  if (obj.src == nil or obj.dest == nil) {
    print("DeltaAdder[", debug.string(obj.src), ", ",
          debug.string(obj.dest), "]");
  }

  return obj;
}
DeltaAdder.update = func () {
  var v = me.src.getValue();
  me.dest.setValue((v - me.old) + me.dest.getValue());
  me.old = v;
}

############################################################
# Switch encoder: Encodes upto 32 boolean properties in one
# int property.
SwitchEncoder = {};
SwitchEncoder.new = func (inputs, dest) {
  obj = { parents : [SwitchEncoder],
          inputs  : inputs,
          dest    : dest };
  # Error checking.
  var bad = (obj.dest == nil);
  foreach (i; inputs) {
    if (i == nil) { bad = 1; }
  }

  if (bad) {
    print("SwitchEncoder[");
    foreach (i; inputs) {
      print("  ", debug.string(i));
    }
    print("  ", debug.string(obj.dest));
    print("]");
  }

  return obj;
}
SwitchEncoder.update = func () {
  var v = 0;
  var b = 1;
  forindex (i; me.inputs) {
    if (me.inputs[i].getBoolValue()) {
      v = v + b;
    }
    b *= 2;
  }
  me.dest.setIntValue(v);
}

############################################################
# Switch decoder: Decodes a bitmask in an int property.
# actions is a list of action functions: func (b) {...}
# Due to interpolation the decoder needs to wait for a
# stable input value.
SwitchDecoder = {};
SwitchDecoder.new = func (src, actions) {
  obj = { parents : [SwitchDecoder],
          reset      : 1,
          old_stable : 0,
          old        : 0,
          stable     : 0,
          src        : src,
          actions    : actions };
  # Error checking.
  var bad = (obj.src == nil);
  foreach (a; obj.actions) {
    if (a == nil) { bad = 1; }
  }
  
  if (bad) {
    print("SwitchDecoder[");
    print("  ", debug.string(obj.src));
    foreach (a; obj.actions) {
      print("  ", debug.string(a));
    }
    print("]");
  }

  return obj;
}
SwitchDecoder.update = func () {
  var ov = me.old_stable;
  var v  = me.src.getValue();
  if (v == nil or ov == nil) return;
  if ((me.old == v) and (me.stable > 5) and (v != ov)) {
    forindex (i; me.actions) {
      var m  = math.mod(v, 2);
      var om = math.mod(ov, 2);
      if ((m != om or me.reset)) { me.actions[i](m?1:0); }
      v  = (v - m)/2;
      ov = (ov - om)/2;
    }
    me.old_stable = me.src.getValue();
    me.reset = 0;
  } elsif (me.old == v) {
    me.stable += 1;
  } else {
    me.stable = 0;
    me.old = me.src.getValue();
  }
}


###############################################################################

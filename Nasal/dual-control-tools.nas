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
var lat_mpp     = "position/latitude-deg";
var lon_mpp     = "position/longitude-deg";
var alt_mpp     = "position/altitude-ft";
var heading_mpp = "orientation/true-heading-deg";
var pitch_mpp   = "orientation/pitch-deg";
var roll_mpp    = "orientation/roll-deg";

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
	var v = me.src.getValue();
	if (num(v) != nil) {
		me.dest.setValue(me.factor * v + me.offset);
	} else {
		me.dest.setValue(v);
	}
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
# Actions are triggered when their input bit change.
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

############################################################
# Time division multiplexing encoder: Transmits a list of
# properties over a pair of MP enabled properties.
#  dest1 - Property#
#  dest2 - Property value.
# Note: TDM can have high latency so it is best used for
# non-time critical properties.
TDMEncoder = {};
TDMEncoder.new = func (inputs, dest1, dest2) {
	obj = { parents   : [TDMEncoder],
inputs    : inputs,
dest1     : dest1,
dest2     : dest2,
MIN_INT   : 0.25,
last_time : 0,
next_item : 0,
old       : [] };
# Error checking.
	var bad = (obj.dest1 == nil) or (obj.dest2 == nil);
	foreach (i; inputs) {
		if (i == nil) { bad = 1; }
	}

	if (bad) {
		print("TDMEncoder[");
		foreach (i; inputs) {
			print("  ", debug.string(i));
		}
		print("  ", debug.string(obj.dest1));
		print("  ", debug.string(obj.dest2));
		print("]");
	}

	setsize(obj.old, size(obj.inputs));

	return obj;
}
TDMEncoder.update = func () {
	var t = getprop("/sim/time/elapsed-sec"); # NOTE: simulated time.
		if (t > me.last_time + me.MIN_INT) {
			var n = size(me.inputs);
			while (1) {
				var v = me.inputs[me.next_item].getValue();

				if ((n <= 0) or (me.old[me.next_item] != v)) {
				# Set the MP properties to send the next item.
					me.dest1.setValue(me.next_item);
					me.dest2.setValue(v);

					me.old[me.next_item] = v;

					me.last_time = t;
					me.next_item += 1;
#					print ("size : ",size(me.inputs)); 
					if (me.next_item >= size(me.inputs)) { me.next_item = 0; }
					return;
				} else {
# Search for changed property.
					n -= 1;
					me.next_item += 1;
					if (me.next_item >= size(me.inputs)) { me.next_item = 0; }
				}         
			}
		}
}

############################################################
# Time division multiplexing decoder: Receives a list of
# properties over a pair of MP enabled properties.
#  src1    - Action#
#  src2    - Arg
#  actions - list of func (arg) { }
# An action is triggered when its value is received.
# Note: TDM can have high latency so it is best used for
# non-time critical properties.
TDMDecoder = {};
TDMDecoder.new = func (src1, src2, actions) {
	obj = { parents   : [TDMDecoder],
src1      : src1,
src2      : src2,
actions   : actions,
old1      : 0,
old2      : 0,
stable    : 0,
done      : 0 };
# Error checking.
	var bad = (obj.src1 == nil) or (obj.src2 == nil);
	foreach (a; actions) {
		if (a == nil) { bad = 1; }
	}

	if (bad) {
		print("TDMDecoder[");
		print("  ", debug.string(obj.src1));
		print("  ", debug.string(obj.src2));
		foreach (a; actions) {
			print("  ", debug.string(a));
		}
		print("]");
	}

	return obj;
}
TDMDecoder.update = func () {
	var v1  = me.src1.getValue();
	var v2  = me.src2.getValue();

	if ((me.old1 == v1) and (me.old2 == v2) and (me.stable > 2) and !me.done) {
# Trigger action.
		me.actions[v1](v2);

		me.done = 1;
	} elsif ((me.old1 == v1) and (me.old2 == v2)) {
		me.stable += 1;
	} else {
		me.stable = 0;
		me.done   = 0;
		me.old1   = me.src1.getValue();
		me.old2   = me.src2.getValue();
	}
}

###############################################################################

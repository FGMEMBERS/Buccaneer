#####################################################################################
#                                                                                   #
#  this script contains a number of utilities for use with the Buccaneer (YASim fdm)    #
#                                                                                   #
#####################################################################################

# ================================ Initalize ====================================== 
# Make sure all needed properties are present and accounted 
# for, and that they have sane default values.

view_number_Node = props.globals.getNode("sim/current-view/view-number",1);
view_number_Node.setDoubleValue(0);

view_name_Node = props.globals.getNode("sim/current-view/name",1);

enabledNode = props.globals.getNode("sim/headshake/enabled", 1);
enabledNode.setBoolValue(1);

n1_node = props.globals.getNode("engines/engine/n1", 1);
smoke_node = props.globals.getNode("engines/engine/smoking", 1);
smoke_node.setBoolValue(1);

fuel_dump_lever_Node = props.globals.getNode("controls/fuel/dump-valve-lever", 1);
fuel_dump_lever_Node.setDoubleValue(0);
fuel_dump_lever_pos_Node = props.globals.getNode("controls/fuel/dump-valve-lever-pos", 1);
fuel_dump_lever_pos_Node.setDoubleValue(0);
fuel_dump_Node = props.globals.getNode("controls/fuel/dump-valve", 1);
fuel_dump_lever_Node.setBoolValue(0);

model_variant_Node = props.globals.getNode("sim/model/variant", 1);
model_variant_Node.setIntValue(0);

model_index_Node = props.globals.getNode("sim/model/index", 1);
model_index_Node.setIntValue(0);

formation_variant_Node = props.globals.getNode("sim/formation/variant", 1);
formation_variant_Node.setIntValue(0); 

formation_index_Node = props.globals.getNode("sim/formation/index", 1);
formation_index_Node.setIntValue(0);

tgt_x_offset_Node = props.globals.getNode("ai/models/wingman/position/tgt-x-offset",1);
tgt_y_offset_Node = props.globals.getNode("ai/models/wingman/position/tgt-y-offset",1);
tgt_z_offset_Node = props.globals.getNode("ai/models/wingman/position/tgt-z-offset",1);
tgt_x_offset_1_Node = props.globals.getNode("ai/models/wingman[1]/position/tgt-x-offset",1);
tgt_y_offset_1_Node = props.globals.getNode("ai/models/wingman[1]/position/tgt-y-offset",1);
tgt_z_offset_1_Node = props.globals.getNode("ai/models/wingman[1]/position/tgt-z-offset",1);
tgt_x_offset_2_Node = props.globals.getNode("ai/models/wingman[2]/position/tgt-x-offset",1);
tgt_y_offset_2_Node = props.globals.getNode("ai/models/wingman[2]/position/tgt-y-offset",1);
tgt_z_offset_2_Node = props.globals.getNode("ai/models/wingman[2]/position/tgt-z-offset",1);

controls.fullBrakeTime = 0;

pilot_g = nil;
pilot_headshake = nil;
observer_headshake = nil;
smoke_0 = nil;
smoke_1 = nil;

var old_n1 = 0;
var time = 0;
var dt = 0;
var last_time = 0.0;

var xDivergence_damp = 0;
var yDivergence_damp = 0;
var zDivergence_damp = 0;

var last_xDivergence = 0;
var last_yDivergence = 0;
var last_zDivergence = 0;

var old_xDivergence_damp = 0;
var old_yDivergence_damp = 0;
var old_zDivergence_damp = 0;


var lever_sum = 0;
var direction = 0 ;

#var dialog = gui.Dialog.new("/sim/gui/dialogs/buccaneer/config/dialog",
#                            "Aircraft/Buccaneer/Dialogs/formation-select.xml");

#var formation["echelon port", "echelon stbd"];
#var data[];

initialize = func {

	print("Initializing Buccaneer utilities ...");
	
	# initialise differential braking
	aircraft.steering.init();

    # initialise dialogs 

	aircraft.formation.init("Aircraft/Buccaneer/Formations",
		"sim/model/formation/variant",
		"sim/model/formation/index"
		);
	
    aircraft.livery.init("Aircraft/Buccaneer/Models/Liveries",
	    "sim/model/livery/variant",
	    "sim/model/livery/index"
	);

	# initialize objects
	pilot_g = PilotG.new();
	pilot_headshake = HeadShake.new("pilot", 0);
	observer_headshake = HeadShake.new("observer", 100);
	smoke_0 = Smoke.new(0);
	smoke_1 = Smoke.new(1);

	#set listeners

#	setlistener("engines/engine/cranking", func {smoke.updateSmoking(); 
#												  });

	setlistener("/sim/formation/variant", func {
	var index = getprop("/sim/formation/variant");
#	print("set formation index ", getprop("/sim/formation/variant"));
	aircraft.formation.set(index);
    },
    1);

    setlistener("/sim/model/formation/variant", func {
		var name = getprop("/sim/model/formation/variant");
		forindex (var i; aircraft.formation.data){
#            print("formation index: ", aircraft.formation.data[i][0]," [1] ",aircraft.formation.data[i][1]);
			
            if(aircraft.formation.data[i][0]== name)
				formation_variant_Node.setIntValue(i);
            

		}
     tgt_x_offset_Node.setDoubleValue(getprop("/sim/model/formation/position/x-offset"));
     tgt_y_offset_Node.setDoubleValue(getprop("/sim/model/formation/position/y-offset"));
     tgt_z_offset_Node.setDoubleValue(getprop("/sim/model/formation/position/z-offset"));
     tgt_x_offset_1_Node.setDoubleValue(getprop("/sim/model/formation/position[1]/x-offset"));
     tgt_y_offset_1_Node.setDoubleValue(getprop("/sim/model/formation/position[1]/y-offset"));
     tgt_z_offset_1_Node.setDoubleValue(getprop("/sim/model/formation/position[1]/z-offset"));
     tgt_x_offset_2_Node.setDoubleValue(getprop("/sim/model/formation/position[2]/x-offset"));
     tgt_y_offset_2_Node.setDoubleValue(getprop("/sim/model/formation/position[2]/y-offset"));
     tgt_z_offset_2_Node.setDoubleValue(getprop("/sim/model/formation/position[2]/z-offset"));
	},
	1);

	setlistener("sim/model/variant", func {
		var index = getprop("sim/model/variant");
		print("set model index", getprop("/sim/model/variant"));
		aircraft.livery.set(index);
	},
	1);
	
	setlistener("/sim/model/livery/variant", func {
		var name = getprop("sim/model/livery/variant");
		forindex (var i; aircraft.livery.data){
            print("variant index: ", aircraft.livery.data[i][0]," [1] ",aircraft.livery.data[i][1]);
			if(aircraft.livery.data[i][0]== name)
    			model_variant_Node.setIntValue(i);
		}
	},
	1);

	# set it running on the next update cycle
	settimer(update, 0);

	print("running Buccaneer utilities");

} # end func

###
# ====================== end Initialization ========================================
###

###
# ==== this is the Main Loop which keeps everything updated ========================
##
var update = func {
    

    pilot_g.update();
    pilot_g.gmeter_update();
    smoke_0.updateSmoking();
    smoke_1.updateSmoking();

	if (enabledNode.getValue() and view_name_Node.getValue() == "Cockpit View" ) { 
		pilot_headshake.update();
#		print ("head shake", view_name_Node.getValue());
	} elsif (enabledNode.getValue() and view_name_Node.getValue() == "Back Seat View") {
		observer_headshake.update(); 
#       print ( view_name_Node.getValue());
	}

	settimer(update, 0); 

}# end main loop func

# ============================== end Main Loop ===============================

# ============================== specify classes ===========================



# =================================== fuel tank stuff ===================================
# Class that specifies fuel cock functions 
# 
FuelCock = {
	new : func (name,
				control,
				initial_pos
				){
		var obj = {parents : [FuelCock] };
		obj.name = name;
		obj.control = props.globals.getNode(control, 1);
		obj.control.setIntValue(initial_pos);
		
		print (obj.name);
		return obj;
	},

	set: func (pos) {# operate fuel cock
		me.control.setValue(pos);
	},
}; #

	
	
# ========================== end fuel tank stuff ======================================


# =============================== Pilot G stuff ================================
# Class that specifies pilot g functions 
# 
PilotG = {
	new : func (name = "pilot-g",
				acceleration = "accelerations",
				pilot_g = "pilot-g",
				g_timeratio = "timeratio", 
				pilot_g_damped = "pilot-g-damped",
				g_min = "pilot-gmin", 
				g_max = "pilot-gmax"
				){
		var obj = {parents : [PilotG] };
		obj.name = name;
		obj.accelerations = props.globals.getNode("accelerations", 1);
		obj.redout = props.globals.getNode("/sim/rendering/redout", 1);
		obj.pilot_g = obj.accelerations.getChild(pilot_g, 0, 1);
		obj.pilot_g_damped = obj.accelerations.getChild(pilot_g_damped, 0, 1);
		obj.g_timeratio = obj.accelerations.getChild(g_timeratio, 0, 1);
		obj.g_min = obj.accelerations.getChild(g_min, 0, 1);
		obj.g_max = obj.accelerations.getChild(g_max, 0, 1);
		obj.pilot_g.setDoubleValue(0);
		obj.pilot_g_damped.setDoubleValue(0); 
		obj.g_timeratio.setDoubleValue(0.0075);
		obj.g_min.setDoubleValue(0);
		obj.g_max.setDoubleValue(0);
#		print (obj.name," ",obj.g_timeratio.getValue());
		return obj;
	},
	update : func () {
		var n = me.g_timeratio.getValue(); 
		var g = me.pilot_g.getValue();
		var g_damp = me.pilot_g_damped.getValue();

		g_damp = (g * n) + (g_damp * (1 - n));
		me.pilot_g_damped.setDoubleValue(g_damp);

#		 print(sprintf("pilot_g_damped in=%0.5f, out=%0.5f, alpha=%0.5f",
#			  g, g_damp, me.redout_alpha.getValue()));
	},
	gmeter_update : func () {
		if(me.pilot_g_damped.getValue() < me.g_min.getValue()){
			me.g_min.setDoubleValue(me.pilot_g_damped.getValue());
		} elsif(me.pilot_g_damped.getValue() > me.g_max.getValue()){
			me.g_max.setDoubleValue(me.pilot_g_damped.getValue());
		}
	},
	get_g_timeratio : func () {
		return me.g_timeratio.getValue();
	},
};	



# Class that specifies head movement functions under the force of gravity
# 
#  - this is a modification of the original work by Josh Babcock

	HeadShake = {
		new : func (name, index){
			var obj = {parents : [HeadShake]};
			var x_accel_fps_sec = "x-accel-fps_sec";
			var y_accel_fps_sec = "y-accel-fps_sec";
			var z_accel_fps_sec = "z-accel-fps_sec";
#			var old_xDivergence_damp = 0;
#			var old_yDivergence_damp = 0;
#			var old_zDivergence_damp = 0;
			x_max_m = "x-max-m";
			x_min_m = "x-min-m";
			y_max_m = "y-max-m";
			y_min_m = "y-min-m";
			z_max_m = "z-max-m";
			z_min_m = "z-min-m";
			x_threshold_g = "x-threshold-g";
			y_threshold_g = "y-threshold-g";
			z_threshold_g = "z-threshold-g";
			x_config = "z-offset-m";
			y_config = "x-offset-m";
			z_config = "y-offset-m";
			time_ratio = "time-ratio";
			obj.name = name ~ " headshake";
			obj.accelerations = props.globals.getNode("accelerations/pilot", 1);
			obj.xAccelNode = obj.accelerations.getChild( x_accel_fps_sec, 0, 1);
		obj.yAccelNode = obj.accelerations.getChild( y_accel_fps_sec, 0, 1);
		obj.zAccelNode = obj.accelerations.getChild( z_accel_fps_sec, 0, 1);
		obj.sim = props.globals.getNode("sim/headshake", 1);
		obj.xMaxNode = obj.sim.getChild(x_max_m, 0, 1);
		obj.xMaxNode.setDoubleValue(0.0375);
		obj.xMinNode = obj.sim.getChild(x_min_m, 0, 1);
		obj.xMinNode.setDoubleValue(-0.015);
		obj.yMaxNode = obj.sim.getChild(y_max_m, 0, 1);
		obj.yMaxNode.setDoubleValue(0.015);
		obj.yMinNode = obj.sim.getChild(y_min_m, 0, 1);
		obj.yMinNode.setDoubleValue(-0.015);
		obj.zMaxNode = obj.sim.getChild(z_max_m, 0, 1);
		obj.zMaxNode.setDoubleValue(0.015);
		obj.zMinNode = obj.sim.getChild(z_min_m, 0, 1);
		obj.zMinNode.setDoubleValue(-0.045);
		obj.xThresholdNode = obj.sim.getChild(x_threshold_g, 0, 1);
		obj.xThresholdNode.setDoubleValue(0.5);
		obj.yThresholdNode = obj.sim.getChild(y_threshold_g, 0, 1);
		obj.yThresholdNode.setDoubleValue(0.5);
		obj.zThresholdNode = obj.sim.getChild(z_threshold_g, 0, 1);
		obj.zThresholdNode.setDoubleValue(0.5);
		obj.time_ratio_Node = obj.sim.getChild(time_ratio , 0, 1);
		obj.time_ratio_Node.setDoubleValue(0.6);
		obj.config = props.globals.getNode("sim/view[" ~ index ~"]/config", 1);
		obj.xConfigNode = obj.config.getChild(x_config, 0, 1);
		obj.yConfigNode = obj.config.getChild(y_config, 0, 1);
		obj.zConfigNode = obj.config.getChild(z_config, 0, 1);
		obj.seat_vertical_adjust_Node = props.globals.getNode("/controls/seat/vertical-adjust", 1);
		obj.seat_vertical_adjust_Node.setDoubleValue(0);
		obj.xViewAxisNode = props.globals.getNode("/sim/current-view/z-offset-m");
		obj.yViewAxisNode = props.globals.getNode("/sim/current-view/x-offset-m");
		obj.zViewAxisNode = props.globals.getNode("/sim/current-view/y-offset-m");
		print (obj.name);
		return obj;
	},
	update : func () {

		# There are two coordinate systems here, one used for accelerations, 
		# and one used for the viewpoint.
		# We will be using the one for accelerations.

		var x_config = "z-offset-m";
		var y_config = "x-offset-m";
		var z_config = "y-offset-m";

#		var xConfig = me.xConfigNode.getValue();
#       var yConfig = me.yConfigNode.getValue();
#		var yConfig = me.xViewAxisNode.getValue();
#		var zConfig = me.zConfigNode.getValue();
		#print ("yConfig ", yConfig);

		var n = pilot_g.get_g_timeratio(); 
		var seat_vertical_adjust = me.seat_vertical_adjust_Node.getValue();

		var xMax = me.xMaxNode.getValue();
		var xMin = me.xMinNode.getValue();
		var yMax = me.yMaxNode.getValue();
		var yMin = me.yMinNode.getValue();
		var zMax = me.zMaxNode.getValue();
		var zMin = me.zMinNode.getValue();

		#work in G, not fps/s
		var xAccel = me.xAccelNode.getValue()/32;
		var yAccel = me.yAccelNode.getValue()/32;
		var zAccel = (me.zAccelNode.getValue() + 32)/32; # We aren't counting gravity
 
		var xThreshold =  me.xThresholdNode.getValue();
		var yThreshold =  me.yThresholdNode.getValue();
		var zThreshold =  me.zThresholdNode.getValue();
		
		# Set viewpoint divergence and clamp
		# Note that each dimension has its own special ratio and +X is clamped at 1cm
		# to simulate a headrest.

		if (xAccel < -1) {
			xDivergence = (((-0.0506 * xAccel) - (0.538)) * xAccel - (0.9915))
										 * xAccel - 0.52;
		} elsif (xAccel > 1) {
			xDivergence = (((-0.0387 * xAccel) + (0.4157)) * xAccel - (0.8448)) 
											* xAccel + 0.475;
		} else {
			xDivergence = 0;
		}

		if (yAccel < -0.5) {
			yDivergence = (((-0.013 * yAccel) - (0.125)) * yAccel - ( 0.1202)) * yAccel - 0.0272;
		} elsif (yAccel > 0.5) {
			yDivergence = (((-0.013 * yAccel) + (0.125)) * yAccel - ( 0.1202)) * yAccel + 0.0272;
		} else {
			yDivergence = 0;
		}

		if (zAccel < -1) {
			zDivergence = (((-0.0506 * zAccel) - (0.538)) 
						* zAccel - (0.9915)) * zAccel - 0.52;
		} elsif (zAccel > 1) {
			zDivergence = (((-0.0387 * zAccel) + (0.4157)) 
						* zAccel - (0.8448)) * zAccel + 0.475;
		} else {
			zDivergence = 0;
		}
		
		xDivergence_total = (xDivergence * 0.25) + (zDivergence * 0.25);
		
		if (xDivergence_total > xMax){xDivergence_total = xMax; }
		if (xDivergence_total < xMin){xDivergence_total = xMin; }
		if (abs(last_xDivergence - xDivergence_total) <= xThreshold){
			xDivergence_damp = (xDivergence_total * n) + (xDivergence_damp * (1 - n));
		#	print ("x low pass");
		} else {
			xDivergence_damp = xDivergence_total;
		#	print ("x high pass");
		}

		last_xDivergence = xDivergence_damp;

#		print (sprintf("x total=%0.5f, x min=%0.5f, x div damped=%0.5f", xDivergence_total,
#		 xMin , xDivergence_damp));	

		yDivergence_total = yDivergence;
		if (yDivergence_total >= yMax){yDivergence_total = yMax; }
		if (yDivergence_total <= yMin){yDivergence_total = yMin; }

		if (abs(last_yDivergence - yDivergence_total) <= yThreshold){
			yDivergence_damp = (yDivergence_total * n) + (yDivergence_damp * (1 - n));
#		 	print ("y low pass");
		} else {
			yDivergence_damp = yDivergence_total;
#			print ("y high pass");
		}

		last_yDivergence = yDivergence_damp;

#		print (sprintf("y=%0.5f, y total=%0.5f, y min=%0.5f, y div damped=%0.5f",
#							yDivergence, yDivergence_total, yMin , yDivergence_damp));
	
		zDivergence_total =  xDivergence + zDivergence;
		if (zDivergence_total >= zMax){zDivergence_total = zMax;}
		if (zDivergence_total <= zMin){zDivergence_total = zMin;}

		if (abs(last_zDivergence - zDivergence_total) <= zThreshold){
			zDivergence_damp = (zDivergence_total * n) + (zDivergence_damp * (1 - n));
#			print ("z low pass");
		} else {
			zDivergence_damp = zDivergence_total;
#			print ("z high pass");
		}
	
		last_zDivergence = zDivergence_damp;
	
#		print (sprintf("z total=%0.5f, z min=%0.5f, z div damped=%0.5f", 
#											zDivergence_total, zMin , zDivergence_damp));
	
# Now apply the divergence to the curent viewpoint
		
		var origin_z = me.xViewAxisNode.getValue() - old_xDivergence_damp;
		var origin_x = me.yViewAxisNode.getValue() - old_yDivergence_damp;
		var origin_y = me.zViewAxisNode.getValue() - old_zDivergence_damp;

		me.xViewAxisNode.setDoubleValue(origin_z + xDivergence_damp );
		me.yViewAxisNode.setDoubleValue(origin_x + yDivergence_damp );
		me.zViewAxisNode.setDoubleValue(origin_y + zDivergence_damp + seat_vertical_adjust );

		old_xDivergence_damp = xDivergence_damp;
		old_yDivergence_damp = yDivergence_damp;
		old_zDivergence_damp = zDivergence_damp + seat_vertical_adjust;
		},
	};


# ============================ end Pilot G stuff ============================

# =========================== smoke stuff ====================================
# Class that specifies smoke functions 
#

Smoke = {
	new : func (number,
				){
		var obj = {parents : [Smoke] };
		obj.name = "smoke " ~ number;
		obj.n1 = props.globals.getNode("engines/engine[" ~ number ~"]/n1", 1);
		obj.smoking = props.globals.getNode("engines/engine[" ~ number ~"]/smoking", 1);
		obj.smoking.setBoolValue(0);
		obj.old_n1 = 0;
#		print (obj.name, " ", number, " ", obj.old_n1);
		return obj;
	},

	updateSmoking: func {    # set the smoke value according to the engine conditions
#	print("updating Smoke ", me.name);
		
		var n1 = me.n1.getValue();
		var smoke = me.smoking.getValue();
		var diff = 0;
		
		diff = math.abs(n1 - me.old_n1);
#		print("diff ", diff);
		
		if (n1 <= 65 or diff > 0.1) {
			smoke = 1;
		} else {
			smoke = 0;
		}
	
		me.smoking.setBoolValue(smoke);
		me.old_n1 = n1;
		
#		print("smoke ", smoke);

	 }, # end function

}; #

# =============================== end smoke stuff ================================



# Fire it up

setlistener("sim/signals/fdm-initialized", initialize);

# end 

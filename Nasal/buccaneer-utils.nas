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
view_internal_Node = props.globals.getNode("sim/current-view/internal",1);
view_internal_Node.setBoolValue(1);

enabledNode = props.globals.getNode("sim/headshake/enabled", 1);
enabledNode.setBoolValue(1);

rainingNode = props.globals.getNode("sim/model/buccaneer/raining", 1);
rainingNode.setValue(0);

precipitationenabledNode = props.globals.getNode("sim/rendering/precipitation-aircraft-enable", 1);
precipitationenabledNode.setBoolValue(0);

precipitationcontrolNode = props.globals.getNode("sim/rendering/precipitation-gui-enable", 1);
precipitationcontrolNode.setBoolValue(0);

n1_node = props.globals.getNode("engines/engine/n1", 1);
smoke_node = props.globals.getNode("engines/engine/smoking", 1);
smoke_node.setBoolValue(1);

fuel_dump_lever_Node = props.globals.getNode("controls/fuel/dump-valve-lever", 1);
fuel_dump_lever_Node.setDoubleValue(0);
fuel_dump_lever_pos_Node = props.globals.getNode("controls/fuel/dump-valve-lever-pos", 1);
fuel_dump_lever_pos_Node.setDoubleValue(0);
fuel_dump_Node = props.globals.getNode("controls/fuel/dump-valve", 1);
fuel_dump_lever_Node.setBoolValue(0);

for(var i = 0; i < 3; i = i + 1){
    setprop("/sim/model/formation/position[" ~ i ~ "]/x-offset", 0);
    setprop("/sim/model/formation/position[" ~ i ~ "]/y-offset", 0);
    setprop("/sim/model/formation/position[" ~ i ~ "]/z-offset", 0);
}

setprop("/controls/autoflight/autopilot/ico", 0);
setprop("sim/alarms/gear-up", 0);
setprop("velocities/mach",0);
setprop("gear/gear[0]/position-norm",0);
setprop("sim/alarms/gear-up-test",0);

model_variant_Node = props.globals.getNode("sim/model/livery/variant", 1);
model_variant_Node.setIntValue(0);

model_index_Node = props.globals.getNode("sim/model/livery/index", 1);
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

props.globals.getNode("/sim/model/formation/position/x-offset",1);

BLC_Node = props.globals.getNode("controls/flight/BLC",1);
BLC_Node.setBoolValue(1);

effectiveness_Node = props.globals.getNode("/controls/flight/flaps-effectiveness",1);
effectiveness_Node.setValue(0);

aileron_droop_Node = props.globals.getNode("controls/flight/aileron-droop",1);
aileron_droop_Node.setValue(0);

wing_blowing_Node = props.globals.getNode("controls/flight/wing-blowing",1);
wing_blowing_Node.setValue(0);

blc_control_valve_Node = props.globals.getNode("controls/pneumatic/BLC",1);
blc_control_valve_Node.setValue(0);

controls.fullBrakeTime = 0;

pilot_g = nil;
pilot_headshake = nil;
observer_headshake = nil;
smoke_0 = nil;
smoke_1 = nil;
wing_blow = nil;
#tyresmoke_0 = nil;
#tyresmoke_1 = nil;
#tyresmoke_2 = nil;
flow = nil;


var old_n1 = 0;
var time = 0;
var dt = 0;
var last_time = 0.0;
var raining = 0;
var mach = 0;
var gear = 0;

var run_tyresmoke0 = 0;
var run_tyresmoke1 = 0;
var run_tyresmoke2 = 0;

var tyresmoke_0 = aircraft.tyresmoke.new(0);
var tyresmoke_1 = aircraft.tyresmoke.new(1);
var tyresmoke_2 = aircraft.tyresmoke.new(2);

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

var formation_dialog = nil;

var wiper = nil;

initialize = func {

	print("Initializing Buccaneer utilities ...");
	
	# initialise differential braking
	aircraft.steering.init();

	# initialise dialogs 
#aircraft.data.add("sim/model/formation/variant");
#	formation_dialog = gui.OverlaySelector.new("Select Formation",
#		"Aircraft/Buccaneer/Formations",
#		"sim/model/formation/variant", nil, func(no) {
#			formation_variant_Node.setIntValue(no);
#			tgt_x_offset_Node.setDoubleValue(getprop("/sim/model/formation/position/x-offset"));
#			tgt_y_offset_Node.setDoubleValue(getprop("/sim/model/formation/position/y-offset"));
#			tgt_z_offset_Node.setDoubleValue(getprop("/sim/model/formation/position/z-offset"));
#			tgt_x_offset_1_Node.setDoubleValue(getprop("/sim/model/formation/position[1]/x-offset"));
#			tgt_y_offset_1_Node.setDoubleValue(getprop("/sim/model/formation/position[1]/y-offset"));
#			tgt_z_offset_1_Node.setDoubleValue(getprop("/sim/model/formation/position[1]/z-offset"));
#			tgt_x_offset_2_Node.setDoubleValue(getprop("/sim/model/formation/position[2]/x-offset"));
#			tgt_y_offset_2_Node.setDoubleValue(getprop("/sim/model/formation/position[2]/y-offset"));
#			tgt_z_offset_2_Node.setDoubleValue(getprop("/sim/model/formation/position[2]/z-offset"));
#		}
#	);
	
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
	wing_blow = WingBlow.new();
	tyresmoke_0 = aircraft.tyresmoke.new(0);
	tyresmoke_1 = aircraft.tyresmoke.new(1);
	tyresmoke_2 = aircraft.tyresmoke.new(2);
	flow = Flow.new();
	var lp = aircraft.lowpass.new(5);

	wiper = aircraft.door.new("sim/model/buccaneer/wiper", 2);

	print ("wiper init ", wiper.getpos());
	#set listeners

#	setlistener("engines/engine/cranking", func {smoke.updateSmoking(); 
#												  });

	setlistener("/sim/signals/fdm-initialized", func {
	dynamic_view.view_manager.calculate = dynamic_view.view_manager.default_plane; 
	});
	
#	setlistener("/sim/model/formation/variant", func {
#		print("formation listener: ", getprop("/sim/model/formation/position/x-offset"));
#		if (tgt_x_offset_Node != nil){
#			print("formation listener getting", getprop("/sim/model/formation/position/x-offset"));
#			tgt_x_offset_Node.setDoubleValue(getprop("/sim/model/formation/position/x-offset"));
#			tgt_y_offset_Node.setDoubleValue(getprop("/sim/model/formation/position/y-offset"));
#			tgt_z_offset_Node.setDoubleValue(getprop("/sim/model/formation/position/z-offset"));
#		}
#		if (tgt_x_offset_1_Node != nil){
#			tgt_x_offset_1_Node.setDoubleValue(getprop("/sim/model/formation/position[1]/x-offset"));
#			tgt_y_offset_1_Node.setDoubleValue(getprop("/sim/model/formation/position[1]/y-offset"));
#			tgt_z_offset_1_Node.setDoubleValue(getprop("/sim/model/formation/position[1]/z-offset"));
#		}
#		if (tgt_x_offset_2_Node != nil){
#			tgt_x_offset_2_Node.setDoubleValue(getprop("/sim/model/formation/position[2]/x-offset"));
#			tgt_y_offset_2_Node.setDoubleValue(getprop("/sim/model/formation/position[2]/y-offset"));
#			tgt_z_offset_2_Node.setDoubleValue(getprop("/sim/model/formation/position[2]/z-offset"));
#		}
#		},
#	0,
#	1);

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

	setlistener("controls/flight/aileron-droop", func {
		var blc = getprop("controls/flight/BLC");
		var droop = getprop("controls/flight/aileron-droop");
	#	static = 0;
		
		if ( blc and droop != 0 ){ 
			blc_control_valve_Node.setValue(1);
		#	effectiveness_Node.setValue(1.8);
			wing_blowing_Node.setValue(1);
		} else {
			blc_control_valve_Node.setValue(0);
			wing_blowing_Node.setValue(0);
			effectiveness_Node.setValue(1);
		}
		
	},
	1);

	setlistener("controls/flight/BLC", func {
		var blc = getprop("controls/flight/BLC");
	#		static = 0;

		if ( !blc  ){ 
			# effectiveness_Node.setValue(1);
			wing_blowing_Node.setValue(0);
			blc_control_valve_Node.setValue(0);
		} else {
			# effectiveness_Node.setValue(2);
			wing_blowing_Node.setValue(1.8);
			blc_control_valve_Node.setValue(1)
		}

	},
	1);

	setlistener("gear/gear[0]/position-norm", func {
		var gear = getprop("gear/gear[0]/position-norm");
		
		if (gear == 1 ){
			run_tyresmoke0 = 1;
		}else{
			run_tyresmoke0 = 0;
		}

		},
		1,
		0);

	setlistener("gear/gear[1]/position-norm", func {
		var gear = getprop("gear/gear[1]/position-norm");
		
		if (gear == 1 ){
			run_tyresmoke1 = 1;
		}else{
			run_tyresmoke1 = 0;
		}

		},
		1,
		0);

	setlistener("gear/gear[2]/position-norm", func {
		var gear = getprop("gear/gear[2]/position-norm");
		
		if (gear == 1 ){
			run_tyresmoke2 = 1;
		}else{
			run_tyresmoke2 = 0;
		}

		},
		1,
		0);

	setlistener("environment/metar/rain-norm", func (n){
		var rain = n.getValue();
		var enabled = precipitationcontrolNode.getValue();
		print("rain metar", rain, " gui enabled ", enabled);
		if(enabled){
			rainingNode.setValue(rain);
		} else {
			rainingNode.setValue(0);
			print("rain metar 2", rain, " gui enabled ", enabled, " rain ",rainingNode.getValue());
		}
	},
	1,
	0);

	setlistener("sim/rendering/precipitation-gui-enable", func (n){
		var enabled = n.getValue();
		var rain = getprop("environment/metar/rain-norm");
		var internal = view_internal_Node.getValue();
		print("rain gui ", rain, " gui enabled ", enabled );
		if(enabled and internal){
			rainingNode.setValue(rain);
			precipitationenabledNode.setBoolValue(0);
		} elsif (enabled){
			rainingNode.setValue(rain);
			precipitationenabledNode.setBoolValue(1);
		} else {
			rainingNode.setValue(0);
			precipitationenabledNode.setBoolValue(0);
		}

	},
	1,
	0);

	setlistener("sim/current-view/internal", func (n){
		var internal = n.getValue();
		enabled = precipitationcontrolNode.getValue();
		var rain = getprop("environment/metar/rain-norm");
		print("precipitation-control-gui-internal",enabled, " internal ", internal, " rain ",rain );
		if(internal){
			precipitationenabledNode.setBoolValue(0);
		} elsif(enabled) {
			precipitationenabledNode.setBoolValue(1);
			rainingNode.setValue(rain);
		}

	},
	1,
	0);

setlistener("/controls/gear/brake-left", func (n){
		var brake = n.getValue();
		var wow1 = getprop("/gear/gear[1]/wow");
        var wow2 = getprop("/gear/gear[2]/wow");

        if (!wow1 and !wow2 and brake != 0){
            setprop("/controls/autoflight/autopilot/ico", 1);
            print ("/controls/autoflight/autopilot/ico", 1);
        } else {
            print ("/controls/autoflight/autopilot/ico", 0);
        }

	},
	1,
	0);

    setlistener("/controls/gear/brake-right", func (n){
		var brake = n.getValue();
		var wow1 = getprop("/gear/gear[1]/wow");
        var wow2 = getprop("/gear/gear[2]/wow");

        if (!wow1 and !wow2 and brake != 0){
            setprop("/controls/autoflight/autopilot/ico", 1);
            print ("/controls/autoflight/autopilot/ico", 1);
        } else {
            print ("/controls/autoflight/autopilot/ico", 0);
        }

	},
	1,
	0);


    setlistener("autopilot/locks/altitude", func (n){
        var lock1 = "altitude-hold-baro";
        var lock2 = "altitude-hold-radio";
        var lock3 = "mach-climb";
        var ico = getprop("/controls/autoflight/autopilot/ico");

        pitchloopid += 1;

        if (n.getValue() == lock1 or n.getValue() == lock2 or n.getValue() == lock3 
            and ico == 0){
            print("utils pitch loopid lock", pitchloopid);
            pitchloop(pitchloopid);
        } else {
            print("utils pitch loopid unlock", pitchloopid);
            pitchloopid = 0;
        }

    },
        1,
        0);

    setlistener("/autopilot/locks/heading", func (n){
        var lock = "dg-heading-hold";
        var ico = getprop("/controls/autoflight/autopilot/ico");

        rollloopid += 1;

        if (n.getValue() == lock and ico == 0){
            print("utils loopid lock", rollloopid);
            rollloop(rollloopid);
        } else {
            print("utils loopid unlock", rollloopid);
            rollloopid = 0;
        }

    },
        1,
        0);

    setlistener("/controls/autoflight/autopilot/ico", func (n){
        var lock = getprop("/autopilot/locks/heading");
        var lock1 = getprop("/autopilot/locks/altitude");
        rollloopid += 1;
        pitchloopid += 1;

        if (n.getValue() == 1 ){
            print("utils ico unlock", rollloopid);
            rollloopid = 0;
            pitchloopid = 0;
        } else {

            if(lock == "dg-heading-hold"){
                print("utils ico lock", rollloopid);
            rollloop(rollloopid);
            }

            if(lock1 == "altitude-hold-baro" or lock1 == "altitude-hold-radio"
            or lock1 == "mach-climb"){
                pitchloop(pitchloopid);
            }
        }

    },
        1,
        0);

	# set it running on the next update cycle
	settimer(update, 0);
wiper.open();
	print("running Buccaneer utilities");

} # end func

###
# ====================== end Initialization ========================================
###

###
# ==== this is the Main Loop which keeps everything updated ========================
##
var update = func {

	var time = getprop("sim/time/elapsed-sec");
	dt = time - last_time;
	last_time = time;


	pilot_g.update();
	pilot_g.gmeter_update();
	smoke_0.updateSmoking();
	smoke_1.updateSmoking();
	wing_blow.update();
	var ias = flow.updateFlow(dt);

	if(rainingNode.getValue() and ias < 300){
		if(wiper.getpos() == 1 or wiper.getpos() == 0){
			wiper.toggle();
		}
	} else {
		wiper.close();
	}

    mach = getprop("velocities/mach");
    gear = getprop("gear/gear[0]/position-norm");
    test = getprop("sim/alarms/gear-up-test");

    if ( (mach < 0.25 and gear == 0) or test == 1)
        setprop("sim/alarms/gear-up", 1);
    else
        setprop("sim/alarms/gear-up", 0);

#print ("run_tyresmoke ",run_tyresmoke);
	
	if (run_tyresmoke0)
		tyresmoke_0.update();

	if (run_tyresmoke1)
		tyresmoke_1.update();

	if (run_tyresmoke2)
		tyresmoke_2.update();

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
# Class that updates wing blowing functions 
# 
WingBlow = {
	new : func(name = "wing blowing"){
		var obj = {parents : [WingBlow] };
		obj.flap_effect = props.globals.getNode("controls/flight/flaps-effectiveness",1);
		obj.pressure = 
			props.globals.getNode("systems/air-bleed/outputs/main-plane-blowing-stbd",1);

		obj.name = name;
		print (obj.name);
		return obj;
	},
	update: func (){
		var pressure = me.pressure.getValue();

		if (pressure == nil) return;
		var pressure_norm = pressure/75;

#		Sinusoidal Fit: y=a+b*cos(cx+d)
#		Coefficient Data:

		var a =	1.4866614;
		var b =	0.51255151;
		var c =	2.5363622;
		var d =	3.1629237;

		var effect = a + b*math.cos(c*pressure_norm + d);

		if (effect > 2) {
			me.flap_effect.setValue(2);
		} elsif (effect < 1) { 
			me.flap_effect.setValue(1);
		} else {
			me.flap_effect.setValue(effect);
		}

#		print("update: ", me.flap_effect.getValue());
	},

};


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

# =========================== tyre smoke stuff ====================================
# Class that specifies tyre smoke functions 
#

var TyreSmoke = {
	new : func (number,
				){
		var obj = {parents : [TyreSmoke] };
		obj.name = "tyre-smoke " ~ number;
		obj.wow = props.globals.getNode("gear/gear[" ~ number ~"]/wow", 1);
		obj.tyresmoke = props.globals.getNode("gear/gear[" ~ number ~"]/tyre-smoke", 1);
		obj.tyresmoke.setBoolValue(0);
		obj.vertical_speed = props.globals.getNode("velocities/vertical-speed-fps", 1);
		obj.speed = props.globals.getNode("velocities/groundspeed-kt", 1);
		obj.friction_factor = props.globals.getNode("gear/gear[" ~ number ~"]/ground-friction-factor", 1);
		obj.friction_factor.setValue(1);
		obj.rollspeed = props.globals.getNode("gear/gear["~ number ~"]/rollspeed-ms", 1);
		obj.rollspeed.setValue(0);
		obj.lp = aircraft.lowpass.new(2);

#		print (obj.name, " ", number, " ", obj.tyresmoke.getValue()," ",obj.old_rollspeed);
		return obj;
	},

	update: func {    # set the smoke value according to the conditions

		var vert_speed = me.vertical_speed.getValue();
		var groundspeed = me.speed.getValue();
		var friction_factor = me.friction_factor.getValue();
		var wow = me.wow.getValue();
		var rollspeed = me.rollspeed.getValue();
		var filtered_rollspeed = me.lp.filter(me.rollspeed.getValue());
		
		var diff_norm = 0;

#       print (me.name, " rollspeed ", rollspeed, " filtered_rollspeed ",filtered_rollspeed);

		diff = math.abs(rollspeed - filtered_rollspeed);

		if (diff > 0)
			diff_norm = diff/rollspeed;
		else
			diff_norm = 0;

		if (wow == nil or diff_norm == nil or rollspeed == nil)
			return;

		if (wow and vert_speed < -0.05 and diff_norm > 0.05 
				and friction_factor > 0.7 and groundspeed > 50){
			me.tyresmoke.setValue(1);
		}
		else{
			me.tyresmoke.setValue(0);
		}

#		print("updating ", me.name, " diff ", diff,
#			 " diff_norm ", diff_norm, " ", me.tyresmoke.getValue());

	 }, # end function

}; #

# =============================== end tyre smoke stuff ================================
# Class that specifies raindrop flow rate functions
#

Flow = {
	new : func ()
	{
		var obj = {parents : [Flow] };
		obj.name = "flow";
		obj.ias = props.globals.getNode("velocities/airspeed-kt", 1);
		obj.elapsed_time = props.globals.getNode("sim/time/elapsed-sec", 1);
		obj.flow = props.globals.getNode("sim/model/buccaneer/flow", 1);
		obj.precipation_level = props.globals.getNode("environment/params/precipitation-level-ft", 1);
		obj.altitude = props.globals.getNode("position/altitude-ft", 1);
		obj.rain = props.globals.getNode("environment/metar/rain-norm", 1);
		obj.flow.setDoubleValue(0);
#		print (obj.name, " ", number, " ", obj.old_n1);
		return obj;
	},

	updateFlow: func (dt){
#		print("updating: ", me.name," dt ",dt );
		
		var ias = me.ias.getValue();
		var elapsed_time = me.elapsed_time.getValue();
		var altitude = me.altitude.getValue();
		var precipation_level = me.precipation_level.getValue();
		var rain = me.rain.getValue();
		var enabled = precipitationcontrolNode.getValue();

		if (ias < 15){
			me.flow.setDoubleValue(0);
		} else {
			me.flow.setDoubleValue((elapsed_time * 0.5) + (ias * 1852 * dt/(60*60)));
		}
		
		if (altitude > precipation_level or !enabled){
			rainingNode.setValue(0);
		} else {
			rainingNode.setValue(rain);
		}
#		print("updating: ", me.name," dt ",dt, " flow ", me.flow.getValue() );
		return ias;

	 }, # end function

}; #

# =============================== end rain stuff ================================
# ===== functions which keep the ailerons/elevators zeroised ====================
#

var rollloopid = 0;

     var rollloop = func(id) {
         id != rollloopid and return;
         setprop("/controls/flight/aileron", 0);
         settimer(func { rollloop(id) }, 0);
     }

     var pitchloopid = 0;

     var pitchloop = func(id) {
         id != pitchloopid and return;
         setprop("/controls/flight/elevator", 0);
         settimer(func { pitchloop(id) }, 0);
     }

# Fire it up

setlistener("sim/signals/fdm-initialized", initialize);

# end 

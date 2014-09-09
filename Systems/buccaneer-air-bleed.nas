##
# Buccaneer air-bleed system.
# From the Pilot's Notes; 
##

# If you want to modify this system, you can specify additional or 
# modify suppliers, buses, and outputs in the "Initialize the air-bleed system" 
# section below. You shouldn't need to modify the follwing script sections

# Limitations:
# 

###
# Initialize internal values
##

#suppliers
engine_port = nil;
engine_stbd = nil;

#reducers
reducer_port=nil;
reducer_stbd=nil;

#services
blc = nil;
general = nil;

#non return valves
nrv_blc_port = nil;
nrv_blc_stbd = nil;
nrv_gen_port = nil;
nrv_gen_stbd = nil;

#variables
var time = 0;
var dt = 0;
var last_time = 0.0;

##
# Initialize the air-bleed system
#

init_air_bleed = func {
	print("Initializing Air-Bleed System");


###
# suppliers ("name", "rpm source", "output", max pressure)

	engine_port = Supplier.new("engine-port",
					"engines/engine[0]/n1",
					"engines/engine[0]/bleed-air-pressure-psi",
					"engines/engine[0]/bleed-air-pressure-norm",
					90
					);
	engine_stbd = Supplier.new("engine-stbd",
					"engines/engine[1]/n1",
					"engines/engine[1]/bleed-air-pressure-psi",
					"engines/engine[1]/bleed-air-pressure-norm",
					90
					);

###
# reducers ("name", "source", "output", output pressure)

	reducer_port = Reducer.new("reducer-port",
					"engines/engine[0]/bleed-air-pressure-psi",
					"systems/air-bleed/reducers/reducer[0]/pressure-psi",
					50
					);
	reducer_stbd = Reducer.new("reducer-stbd",
					"engines/engine[1]/bleed-air-pressure-psi",
					"systems/air-bleed/reducers/reducer[1]/pressure-psi",
					50
					);

###
#  shut off valves ("name", "source", "output", "control", initial status, operating time) 
##
	blc_port = ShutOffValve.new("blc-port",
					"engines/engine[0]/bleed-air-pressure-psi",
					"systems/air-bleed/shut-off-valves/shut-off-valve[0]/pressure-psi",
					"controls/pneumatic/BLC",
					"systems/air-bleed/shut-off-valves/shut-off-valve[0]/pos-norm",
					0,
					5);
	blc_stbd = ShutOffValve.new("blc-stbd",
					"engines/engine[1]/bleed-air-pressure-psi",
					"systems/air-bleed/shut-off-valves/shut-off-valve[1]/pressure-psi",
					"controls/pneumatic/BLC",
					"systems/air-bleed/shut-off-valves/shut-off-valve[1]/pos-norm",
					0,
					5
					);
	blc_tail = ShutOffValve.new("blc-tail",
					"systems/air-bleed/services/service[1]/pressure-psi",
					"systems/air-bleed/shut-off-valves/shut-off-valve[2]/pressure-psi",
					"controls/pneumatic/BLC",
					"systems/air-bleed/shut-off-valves/shut-off-valve[2]/pos-norm",
					0,
					5
					);

###
# non-return valves ("name", "source1", "source2", "output", "position",
#					initial status, operating time) 
##
	nrv_blc_port = NonReturnValve.new("nrv-blc-port",
					"systems/air-bleed/shut-off-valves/shut-off-valve[0]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[1]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[0]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[0]/pos-norm",
					0,
					0.5
					);
	nrv_blc_stbd = NonReturnValve.new("nrv-blc-stbd",
					"systems/air-bleed/shut-off-valves/shut-off-valve[1]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[0]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[1]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[1]/pos-norm",
					0,
					0.5
					);
	nrv_gen_port = NonReturnValve.new("nrv-gen-port",
					"systems/air-bleed/reducers/reducer[0]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[3]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[2]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[2]/pos-norm",
					0,
					0.5
					);
	nrv_gen_stbd = NonReturnValve.new("nrv-gen-stbd",
					"systems/air-bleed/reducers/reducer[1]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[2]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[3]/pressure-psi",
					"systems/air-bleed/non-return-valves/non-return-valve[3]/pos-norm",
					0,
					0.5
					);

###
# services ("name", "source1", "source2","output") 
##
	blc = Service.new		("BLC",
							"systems/air-bleed/non-return-valves/non-return-valve[0]/pressure-psi",
							"systems/air-bleed/non-return-valves/non-return-valve[1]/pressure-psi",
							"systems/air-bleed/services/service[0]/pressure-psi",
							);
	general = Service.new	("General",
							"systems/air-bleed/non-return-valves/non-return-valve[2]/pressure-psi",
							"systems/air-bleed/non-return-valves/non-return-valve[3]/pressure-psi",
							"systems/air-bleed/services/service[1]/pressure-psi",
							);

###
# outputs
# ("name", "source ")
##

	main_plane_blowing_port = Output.new("main-plane-blowing-port",
										"systems/air-bleed/services/service[0]/pressure-psi",
										);

	main_plane_blowing_stbd = Output.new("main-plane-blowing-stbd",
										"systems/air-bleed/services/service[0]/pressure-psi",
										);

	main_plane_blowing_tail = Output.new("main-plane-blowing-tail",
										"systems/air-bleed/shut-off-valves/shut-off-valve[2]/pressure-psi",
										);


# Request that the update fuction be called next frame
	settimer(update_air_bleed, 0);
}

#####################################################################################
# Specify classes - this section should not require modification
#####################################################################################

##
# Supplier model class.

Supplier = {
	 new : func(name, source, output_pressure, output_pressure_norm, max_pressure) {
		var obj = { parents : [ Supplier ] };
		obj.name = name;
		print ("name ", name);
		obj.rpm_source = props.globals.getNode( source, 1 );
		obj.rpm_source.setDoubleValue(0);
		obj.output_pressure = props.globals.getNode( output_pressure, 1 );
		obj.output_pressure_norm = props.globals.getNode(output_pressure_norm, 1 );
		obj.max_pressure = max_pressure;
		append(Supplier.list, obj); 
		return obj;
	},
	update : func {
		var n1 = me.rpm_source.getValue();
		var max_pressure = me.max_pressure;

		#	Non linear relationship between n1 and output pressure
		#	is approximated by the following function
		#	5th Degree Polynomial:  ...
		#	Coefficient Data:

		var a =	-0.0005201961;
		var b =	-0.0119416970;
		var c =	0.0012091783;
		var d =	-0.0000334129;
		var e =	0.0000003733;
		var f =	-0.0000000014;

		var output_pressure_norm = a + (b * n1) + (c * math.pow(n1,2)) 
			+ (d * math.pow(n1,3)) + (e * math.pow(n1,4)) + (f * math.pow(n1,5));
		me.output_pressure.setValue(output_pressure_norm * max_pressure);
		me.output_pressure_norm.setValue(output_pressure_norm);
	},
	get_output_pressure : func {
		return me.output_pressure;
	},
	set_props : func {
		me.props_node.setDoubleValue(me.output_volts);
	},
	list : [],
};

##
# air-bleed output class
#

Output = {
	 new : func (name, source) {
		var obj = { parents : [Output] };
		obj.output = props.globals.getNode("systems/air-bleed/outputs", 1).getChild(name,0,1);
		obj.output.setValue(0);
		obj.source = props.globals.getNode(source,1);
		append(Output.list, obj); 
		return obj;
	},
	update : func () {
		var pressure = me.source.getValue();
		me.set_prop(pressure);
	},
	get_source : func () {
		return me.source;
	},
	set_prop : func (pressure){
		if(pressure==nil)return;
		me.output.setDoubleValue(pressure);
	},
	list : [],
};


##
# reducer class
#
Reducer = {
	new : func (name, source, output, max_pressure) {
		var obj = { parents : [Reducer] };
		obj.name = name;
		print ("name ", name);
		obj.source = props.globals.getNode( source, 1 );
		obj.output_pressure = props.globals.getNode( output, 1 );
		obj.output_pressure.setValue(0);
		obj.max_pressure = max_pressure;
		append( Reducer.list, obj );
		return obj;
	},
	update : func {
		var input_pressure = me.source.getValue();
		var max_pressure = me.max_pressure;

		if ( input_pressure == nil )return;

		if ( input_pressure <= max_pressure ){
				me.output_pressure.setValue(input_pressure);
			} else {
				me.output_pressure.setValue(max_pressure);
			}

		return;
	},
	get_output_pressure : func {
		return me.output_pressure;
	},
	get_name : func {
		return me.name;
	},
	list : [],
};

##
# shut off valve class
#
ShutOffValve = {
	new : func (name, source, output, control, position,
				initial_status, operating_time) {
		var obj = { parents : [ShutOffValve] };
		obj.name = name;
		print ("name ", name);
		obj.input_pressure = props.globals.getNode( source, 1 );
		obj.output_pressure = props.globals.getNode( output, 1 );
		obj.output_pressure.setValue(0);
		obj.control = props.globals.getNode( control, 1 );
		obj.position = props.globals.getNode( position, 1 );
		obj.position.setValue(initial_status);
		obj.operating_time = operating_time;
		append( ShutOffValve.list, obj );
		return obj;
	},
	update :  func () {
		var control = me.control.getValue();
		var position = me.getpos();
		if (control != position and control == 1){
			me.open();
		} elsif (control != position and control == 0){
			me.close();
		}
		me.setpressure(position);
	},
	setpressure : func (position){
		var pressure = me.input_pressure.getValue();
		if(position==nil or pressure==nil)return;
		me.output_pressure.setValue(pressure * position);
	},
	close : func { me.move(me.target = 0);
	},
	open : func { me.move(me.target = 1);
	},
	getpos : func { me.position.getValue();
	},
	move : func(target) {
		var pos = me.getpos();
		if (pos != target) {
			var time = abs(pos - target) * me.operating_time;
			interpolate(me.position, target, time);
		}
		me.target = !me.target;
	},
	list : [],
};

##
# non return valve class
#
NonReturnValve = {
	new : func (name, source1, source2, output, position,
				initial_status, operating_time) {
		var obj = { parents : [NonReturnValve] };
		obj.name = name;
		print ("non-return valve ", name);
		obj.opening_pressure = props.globals.getNode( source1, 1 );
		obj.closing_pressure = props.globals.getNode( source2, 1 );
		obj.output_pressure = props.globals.getNode( output, 1 );
		obj.output_pressure.setValue(0);
		obj.position = props.globals.getNode( position, 1 );
		obj.position.setValue(initial_status);
		obj.operating_time = operating_time;
		append( NonReturnValve.list, obj );
		return obj;
	},
	update :  func () {
		var opening_pressure = me.opening_pressure.getValue();
		var closing_pressure = me.closing_pressure.getValue();
		var position = me.getpos();

		if (closing_pressure > opening_pressure){
			me.close();
		} else {
			me.open();
		}

		me.setpressure(position);
	},
	setpressure : func (position){
		me.output_pressure.setValue(me.opening_pressure.getValue() * position);
	},
	close : func { me.move(me.target = 0);
	},
	open : func { me.move(me.target = 1);
	},
	getpos : func { me.position.getValue();
	},
	move : func(target) {
		var pos = me.getpos();
		if (pos != target) {
			var time = abs(pos - target) * me.operating_time;
			interpolate(me.position, target, time);
		}
		me.target = !me.target;
	},
	list : [],
};


##
# Services class
#
Service = {
	new : func (name, source1, source2, output) {
		var obj = { parents : [Service] };
		obj.name = name;
		print ("service ", name);
		obj.input_pressure1 = props.globals.getNode( source1, 1 );
		obj.input_pressure2 = props.globals.getNode( source2, 1 );
		obj.output_pressure = props.globals.getNode( output, 1 );
		append(Service.list, obj);
		return obj;
	},
	update : func (){
		var input_pressure1 = me.input_pressure1.getValue();
		var input_pressure2 = me.input_pressure2.getValue();

		if (input_pressure1 >= input_pressure2){
			me.set_pressure(input_pressure1);
		} else {
			me.set_pressure(input_pressure2);;
		}

	},
	set_pressure : func (pressure){
		me.output_pressure.setValue(pressure);
	},
	list : [],
};
		
###
# This is the main loop which keeps eveything updated
#
update_air_bleed = func {
	time = props.globals.getNode("/sim/time/elapsed-sec", 1).getValue();
	dt = time - last_time;
	last_time = time;

		foreach (var s; Supplier.list) {
			s.update();	
		}	

		foreach ( var r; Reducer.list) {
			r.update();	
		}

		foreach ( var o; ShutOffValve.list) {
			o.update();	
		}	

		foreach ( var n; NonReturnValve.list) {
			n.update();	
		}

		foreach ( var s; Service.list) {
			s.update();	
		}	

		foreach (var o; Output.list) {
			o.update();
		}		
		

#		bus_controller.update(dt);
#		inverter_controller.update();
		
#		foreach (var b; Bus.list) {
#			b.update(dt);
#		}		
		
# Request that the update fuction be called again 
		settimer(update_air_bleed, 0.3 );
}

###
# Setup a timer based call to initialized the electrical system as
# soon as possible.
settimer(init_air_bleed, 0);



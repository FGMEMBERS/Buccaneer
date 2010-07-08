# This is a replacement for fuel.nas for the particlar fuel 
# system of the Buccaneer

# Properties under /consumables/fuel/tank[n]:
# + level-gal_us    - Current fuel load.  Can be set by user code.
# + level-lbs       - OUTPUT ONLY property, do not try to set
# + selected        - boolean indicating tank selection.
# + density-ppg     - Fuel density, in lbs/gallon.
# + capacity-gal_us - Tank capacity 
#
# Properties under /engines/engine[n]:
# + fuel-consumed-lbs - Output from the FDM, zeroed by this script
# + out-of-fuel       - boolean, set by this code.


# ==================================== fuel tank stuff ===================================
# replace the generic fuel updater
fuel.update = func{};

###
# Initialize internal values
##
tank_1 = nil;
tank_2 = nil;
tank_3 = nil;
tank_4 = nil;
tank_5 = nil;
tank_6 = nil;
tank_7 = nil;
tank_8 = nil;
proportioner_port = nil;
proportioner_stbd = nil;
recuperator_port = nil;
recuperator_stbd = nil;
neg_g = nil;
valve_1 = nil;
valve_2 = nil; 
valve_3 = nil;
valve_4 = nil;
valve_5 = nil;
valve_6 = nil; 
valve_7 = nil;
valve_8 = nil;
valve_9 = nil;
valve_10 = nil;

PortEngine		= props.globals.getNode("engines").getChild("engine", 0);
StbdEngine		= props.globals.getNode("engines").getChild("engine", 1);
PortFuel		= PortEngine.getNode("fuel-consumed-lbs", 1);
StbdFuel		= StbdEngine.getNode("fuel-consumed-lbs", 1);
DumpValve		= props.globals.getNode("controls/fuel/dump-valve", 1);
CrossConnect	= props.globals.getNode("controls/fuel/cross-connect", 1);
TransferFwd		= props.globals.getNode("controls/fuel/TX-fwd", 1);
TransferAft		= props.globals.getNode("controls/fuel/TX-aft", 1);
TotalFuelLbs	= props.globals.getNode("consumables/fuel/total-fuel-lbs", 1);
TotalFuelGals	= props.globals.getNode("consumables/fuel/total-fuel-gals", 1);
TotalFuelNorm	= props.globals.getNode("consumables/fuel/total-fuel-norm", 1);

PortEngine.getNode("out-of-fuel", 1);
StbdEngine.getNode("out-of-fuel", 1); 

#variables 
var amount_stbd = amount_port = 0;
var amount_2 = amount_6 = 0;
var amount_3 = amount_5 = 0;
var total_cap_port = total_cap_stbd = 0;
var prop_2 = prop_3 = prop_5 = prop_6 = 0;

var dumprate_lbs_hr = 620 * 60; #1240 lbs / min total
var flowrate_lbs_hr = dumprate_lbs_hr * 1.1;

var time = 0;
var dt = 0;
var last_time = 0.0;
var total = 0;
var dump_valve = 0;
var cross_connect = 0;
var LP_port = 0;
var LP_stbd = 0;
var TX_fwd = 0;
var TX_aft = 0;
var FNA_2 = 0;
var FNA_3 = 0;
var FNA_5 = 0;
var FNA_6 = 0;
var lever_sum = 0;

##
# Initialize the fuel system
#

var init_fuel_system = func {
	print("Initializing Buccaneer fuel system ...");

	# set initial values
#CrossConnect.setBoolValue(1);
	TotalFuelLbs.setDoubleValue(0.01);
	TotalFuelGals.setDoubleValue(0.01);
	PortEngine.setBoolValue(0);
	StbdEngine.setBoolValue(0);

	###
	#tanks ("name", number, initial connection status)
	###
		tank_1				= Tank.new("tank_No1", 0, 0);
		tank_2				= Tank.new("tank_No2", 1, 0);
		tank_3				= Tank.new("tank_No3", 2, 0);
		tank_4				= Tank.new("tank_No4", 3, 0);
		tank_5				= Tank.new("tank_No5", 4, 0);
		tank_6				= Tank.new("tank_No6", 5, 0);
		tank_7				= Tank.new("tank_No7", 6, 0);
		tank_8				= Tank.new("tank_No8", 7, 0);

	###
	#proportioners ("name", number, initial connection status, operational status)
	###
		proportioner_port	= Prop.new("prop_port", 8, 1, 1);
		proportioner_stbd	= Prop.new("prop_stbd", 9, 1, 1);
	###

	#recuperators ("name", number, initial connection status)
	###
		recuperator_port = Recup.new("recup_port", 10, 0);
		recuperator_stbd = Recup.new("recup_stbd", 11, 0);

	###
	#switches (intitial status)
	##
		neg_g = Neg_g.new(0);

	###
	#valves ("name",property, intitial status)
	##
		valve_1 = Valve.new("dump_valve","controls/fuel/dump-valve",0);
		valve_2 = Valve.new("cross_connect_valve","controls/fuel/cross-connect",0);
		valve_3 = Valve.new("LP_valve_port","controls/fuel/LP-port",1);
		valve_4 = Valve.new("LP_valve_stbd","controls/fuel/LP-stbd",1);
		valve_5 = Valve.new("TX_valve_fwd","controls/fuel/TX-fwd",0);
		valve_6 = Valve.new("TX_valve_aft","controls/fuel/TX-aft",0);
		valve_7 = Valve.new("FNA_2","controls/fuel/FNA-2",1);
		valve_8 = Valve.new("FNA_3","controls/fuel/FNA-3",1);
		valve_9 = Valve.new("FNA_5","controls/fuel/FNA-5",1);
		valve_10 = Valve.new("FNA_6","controls/fuel/FNA-6",1);

	#calculate the proportions, based on the total capacity of tanks port and stbd

	total_cap_port = tank_2.get_capacity() + tank_4.get_capacity() + tank_6.get_capacity() + tank_8.get_capacity();
	prop_2 = (tank_2.get_capacity() + tank_4.get_capacity())/total_cap_port;
	# print ("proportion 2: ", prop_2, " total cap port: ", total_cap_port);
	prop_6 = (tank_6.get_capacity() + tank_8.get_capacity())/total_cap_port;
	# print ("proportion 6: ", prop_6, " sum ", prop_2 + prop_6);

	total_cap_stbd = tank_1.get_capacity() + tank_3.get_capacity() + tank_5.get_capacity() + tank_7.get_capacity();
	prop_3 = (tank_1.get_capacity() + tank_3.get_capacity())/total_cap_stbd;
	# print ("proportion 3: ", prop_3, " total cap stbd: ", total_cap_stbd);
	prop_5 = (tank_5.get_capacity() + tank_7.get_capacity())/total_cap_stbd;
	# print ("proportion 5: ", prop_5, " sum ", prop_3 + prop_5);

	# initialise listeners
	setlistener("controls/fuel/dump-valve", func {
		dump_valve = DumpValve.getValue();
		#print("dump_valve ", dump_valve);
		}
	);

	setlistener("controls/fuel/cross-connect", func {
		cross_connect = CrossConnect.getValue();
		#print("cross_connect ", cross_connect);
		}
	);

	setlistener("controls/fuel/LP-port", func {
		LP_port = Valve.get("LP_valve_port");
		#print("LP_port ", LP_port);
		},
	1
	);

	setlistener("controls/fuel/LP-stbd", func {
		LP_stbd = Valve.get("LP_valve_stbd");
		#print("LP_stbd ", LP_stbd);
		},
	1
	);

	setlistener("controls/fuel/TX-fwd", func {
		TX_fwd = Valve.get("TX_valve_fwd");
		print("TX_fwd ", TX_fwd);
		},
	1
	);

	setlistener("controls/fuel/TX-aft", func {
		TX_aft = Valve.get("TX_valve_aft");
		print("TX_aft ", TX_aft);
		},
	1
	);

	setlistener("controls/fuel/FNA-2", func {
		FNA_2 = Valve.get("FNA_2");
		print("FNA_2 ", FNA_2);
		},
	1
	);

	setlistener("controls/fuel/FNA-3", func {
		FNA_3 = Valve.get("FNA_3");
		print("FNA_3 ", FNA_3);
		},
	1
	);

	setlistener("controls/fuel/FNA-5", func {
		FNA_5 = Valve.get("FNA_5");
		print("FNA_5 ", FNA_5);
		},
	1
	);

	setlistener("controls/fuel/FNA-6", func {
		FNA_6 = Valve.get("FNA_6");
		print("FNA_6 ", FNA_6);
		},
	1
	);

	setlistener("controls/fuel/dump-valve-lever", func {
		var lever = fuel_dump_lever_Node.getValue();
		if(lever_sum >=2) direction = -1;
		if(lever_sum <=0) direction = 1;
		lever_sum += lever * direction;
#		print("total_lever ", lever_sum);
		fuel_dump_lever_pos_Node.setDoubleValue(lever_sum);

		if(lever_sum == 2) {
			Valve.set("dump_valve",1);
#			print("valve ", fuel_dump_Node.getBoolValue());
		} else {
			Valve.set("dump_valve",0);
#			print("valve ", fuel_dump_Node.getBoolValue());
		}
	}
	,1);

	#run the main loop
	settimer(fuel_update,0);

	print ("All Done ... Running Buccaneer fuel system");

} # end intitialization


###
# This is the main loop which keeps everything updated
##

var fuel_update = func {

	# if fuel consumption is frozen, skip it
	if(getprop("/sim/freeze/fuel")) { return settimer(mainLoop, 0); }

	#calculate dt
	time = props.globals.getNode("/sim/time/elapsed-sec", 1).getValue();
	dt = time - last_time;
	#print("dt " , dt);
	last_time = time;

	#calculate total fuel in tanks (not including small amount in proportioners)
	total_gals = total_lbs = 0;

	foreach (var t; Tank.list) {
		total_gals = total_gals + t.get_level();
		total_lbs = total_lbs + t.get_level_lbs();
	}

	TotalFuelLbs.setValue(total_lbs);
	TotalFuelGals.setValue(total_gals);
	TotalFuelNorm.setValue(total_gals / (total_cap_port + total_cap_stbd));

	# if total fuel is less than 4000 lbs, close the dunp valve
	if(TotalFuelLbs.getValue() < 4000) {
		DumpValve.setBoolValue(0);
	}

	neg_g.update();

	# these are the rules governing fuel transfer
	
	# transfer 1 to 3
	if(tank_3.get_ullage() > 0 and tank_1.get_level() > 0){ 
		tank_1.set_transfer_tank(dt, "tank_No3");
	}

	# transfer 4 to 2
	if(tank_2.get_ullage() > 0 and tank_4.get_level() > 0){
		tank_4.set_transfer_tank(dt, "tank_No2");
	}

	# transfer 7 to 5
	if(tank_5.get_ullage() > 0 and tank_7.get_level() > 0){ 
		tank_7.set_transfer_tank(dt, "tank_No5");
	}

	# transfer 8 to 6
	if(tank_6.get_ullage() > 0 and tank_8.get_level() > 0){
		tank_8.set_transfer_tank(dt, "tank_No6");
	}

	# inter-tank tranfer
	#  transfer 2 and 3
	if(TX_fwd) {
		if(tank_2.get_level_lbs() > tank_3.get_level_lbs() 
			and tank_3.get_ullage() > 0 and FNA_2){
			tank_2.set_transfer_tank(dt, "tank_No3");
		} elsif (tank_3.get_level_lbs() > tank_2.get_level_lbs() 
			and tank_2.get_ullage() > 0 and FNA_3){
			tank_3.set_transfer_tank(dt, "tank_No2");
		}
	}
	#  transfer 5 and 6
	if(TX_aft) {
		if(tank_5.get_level_lbs() > tank_6.get_level_lbs() 
			and tank_6.get_ullage() > 0 and FNA_5){
			tank_5.set_transfer_tank(dt, "tank_No6");
		} elsif (tank_6.get_level_lbs() > tank_5.get_level_lbs() 
			and tank_5.get_ullage() > 0 and FNA_6){
			tank_6.set_transfer_tank(dt, "tank_No5");
		}
	}

	# jettison fuel
	if(dump_valve) {
		proportioner_port.jettisonFuel(dt);
		proportioner_stbd.jettisonFuel(dt);
	} else {
		proportioner_port.set_dumprate(0);
		proportioner_stbd.set_dumprate(0);
	}

	# transfer to port proportioner
	if(proportioner_port.get_ullage() > 0){
		amount_port = proportioner_port.get_ullage();
		# print ("amount to port prop: ", amount_port);
		# if there is any fuel in No2 transfer the correct proportion
		if(tank_2.get_level() > 0 and FNA_2){
			amount_2 = amount_port * prop_2;
			if(amount_2 > tank_2.get_level()) {
			amount_2 = tank_2.get_level();
			}
#	print("Amount 2 (from tank 2: " , amount_2);
		tank_2.set_level(tank_2.get_level() - amount_2);
		proportioner_port.set_level(proportioner_port.get_level() + amount_2);
		}
		# if there is any fuel in No6 transfer the correct proportion
		if(tank_6.get_level() > 0 and FNA_6){
			amount_6 = amount_port * prop_6;
			if(amount_6 > tank_6.get_level()) {
				amount_6 = tank_6.get_level();
			}
#	print("Amount 6: ", amount_6);
			tank_6.set_level(tank_6.get_level() - amount_6);
			proportioner_port.set_level(proportioner_port.get_level() + amount_6);
		}
		# TX valve is open we substitute tank 3 for tank 2
		# if there is any fuel in No3 transfer the correct proportion
		if(tank_3.get_level() > 0 and FNA_3 and !FNA_2 and TX_fwd){
			amount_2 = amount_port * prop_2;
			if(amount_2 > tank_3.get_level()) {
			amount_2 = tank_3.get_level();
			}
#	print("Amount 2 (from tank 3: " , amount_2);
		tank_3.set_level(tank_3.get_level() - amount_2);
		proportioner_port.set_level(proportioner_port.get_level() + amount_2);
		}
	}

	# transfer to stbd proportioner
	if(proportioner_stbd.get_ullage() > 0){
		amount_stbd = proportioner_stbd.get_ullage();
#print ("amount to stbd prop: ", amount_stbd);
# if there is any fuel in No3 transfer the correct proportion
		if(tank_3.get_level() > 0 and FNA_3){
			amount_3 = amount_stbd * prop_3;
			if(amount_3 > tank_3.get_level()) {
				amount_3 = tank_3.get_level();
			}
# print("Amount 3: " , amount_3);
			tank_3.set_level(tank_3.get_level() - amount_3);
			proportioner_stbd.set_level(proportioner_stbd.get_level() + amount_3);
		}
# if there is any fuel in No5 transfer the correct proportion
		if(tank_5.get_level() > 0 and FNA_5){
			amount_5 = amount_stbd * prop_5;
			if(amount_5 > tank_5.get_level()) {
				amount_5 = tank_5.get_level();
			}
# print("Amount 5 (from tank 5: ", amount_5);
			tank_5.set_level(tank_5.get_level() - amount_5);
			proportioner_stbd.set_level(proportioner_stbd.get_level() + amount_5);
		}
# TX_aft is open we sustitute 6 for 5
# if there is any fuel in No6 transfer the correct proportion
		if(tank_6.get_level() > 0 and FNA_6 and !FNA_5 and TX_aft){
			amount_5 = amount_stbd * prop_5;
			if(amount_5 > tank_6.get_level()) {
				amount_5 = tank_6.get_level();
			}
# print("Amount 5 (from tank 6: ", amount_5);
			tank_6.set_level(tank_6.get_level() - amount_5);
			proportioner_stbd.set_level(proportioner_stbd.get_level() + amount_5);
		}
	}
	# transfer proportioners to recuperators
	if(!cross_connect) {
		if(recuperator_port.get_ullage() > 0 and proportioner_port.get_level() > 0){
			proportioner_port.set_transfer_tank(dt, "recup_port");
		}
		if(recuperator_stbd.get_ullage() > 0 and proportioner_stbd.get_level() > 0){
			proportioner_stbd.set_transfer_tank(dt, "recup_stbd");
		}
	} elsif (recuperator_port.get_ullage() > 0  or recuperator_stbd.get_ullage() > 0){
		if(proportioner_port.get_level() > 0 or proportioner_stbd.get_level() > 0){
			# print("cross-connected");
			proportioner_port.set_transfer_tank(dt, "recup_port");
			proportioner_stbd.set_transfer_tank(dt, "recup_port");
			proportioner_port.set_transfer_tank(dt, "recup_stbd");
			proportioner_stbd.set_transfer_tank(dt, "recup_stbd");
		}
	}	

	# transfer from the proportioners to the engines
	var port_fuel_consumed = PortFuel.getValue();
	var stbd_fuel_consumed = StbdFuel.getValue();
	if(port_fuel_consumed == nil) port_fuel_consumed = 0;
	if(stbd_fuel_consumed == nil) stbd_fuel_consumed = 0;
	#print ( "port_fuel consumed", PortFuel.getValue() );
	#print ( "stbd_fuel consumed", StbdFuel.getValue() );

	if (cross_connect){
		var num_prop_running = 0;
		foreach (var p; Prop.list) {
			# print(p.get_name());
			if (p.get_running()) num_prop_running += 1;
		}
	#print("num_prop_running ", num_prop_running);

		total = port_fuel_consumed + stbd_fuel_consumed;
		port_outOfFuel = proportioner_port.update(total/num_prop_running);
		stbd_outOfFuel = proportioner_stbd.update(total/num_prop_running);
		
		if(port_outOfFuel and stbd_outOfFuel) {
			port_outOfFuel = recuperator_port.update(total/2);
			stbd_outOfFuel = recuperator_stbd.update(total/2);
		}

		if(port_outOfFuel and stbd_outOfFuel) {
			port_outOfFuel = stbd_outOfFuel = 1;
		} else {
			port_outOfFuel = stbd_outOfFuel = 0;
		}

	} else {
		port_outOfFuel = proportioner_port.update(port_fuel_consumed);
		if(port_outOfFuel) port_outOfFuel = recuperator_port.update(port_fuel_consumed);
		
		stbd_outOfFuel = proportioner_stbd.update(stbd_fuel_consumed);
		if(stbd_outOfFuel) stbd_outOfFuel = recuperator_stbd.update(stbd_fuel_consumed);
	}

	#reset the fuel consumed
	PortFuel.setDoubleValue(0);
	StbdFuel.setDoubleValue(0);

	#set engines
	if(LP_port) {
		PortEngine.getNode("out-of-fuel").setBoolValue(port_outOfFuel);
	} else {
		PortEngine.getNode("out-of-fuel").setBoolValue(1);
	}
	if(LP_stbd) {
		StbdEngine.getNode("out-of-fuel").setBoolValue(stbd_outOfFuel);
	} else {
		StbdEngine.getNode("out-of-fuel").setBoolValue(1);
	}

	settimer(fuel_update, 0.3);

} # end funtion mainLoop    


###
# Specify Classes
##

##
# This class defines a tank
#
Tank = {
	new : func (name, number, connect) {
		var obj = { parents : [Tank]};
		obj.prop = props.globals.getNode("consumables/fuel").getChild ("tank", number , 1);
		obj.name = obj.prop.getNode("name", 1);
		obj.prop.getChild("name", 0, 1).setValue(name);
		obj.capacity = obj.prop.getNode("capacity-gal_us", 1);
		obj.ppg = obj.prop.getNode("density-ppg", 1);
		obj.level_gal_us = obj.prop.getNode("level-gal_us", 1);
		obj.level_lbs = obj.prop.getNode("level-lbs", 1);
		obj.transfering = obj.prop.getNode("transfering", 1);
		#obj.dumprate = obj.prop.getNode("dump-rate-lbs-hr", 1);
		obj.prop.getChild("selected", 0, 1).setBoolValue(connect);
		obj.prop.getChild("transfering", 0, 1).setBoolValue(0);
		obj.ppg.setDoubleValue(6.3);

		append(Tank.list, obj);
		print ("tank ", obj.name.getValue()); 

		return obj;
	},
	get_capacity : func {
		return me.capacity.getValue(); 
	},
	get_level : func {
		return me.level_gal_us.getValue();	
	},	
	get_level_lbs : func {
		return me.level_lbs.getValue();	
	},
	set_level : func (gals_us){
		if(gals_us < 0) gals_us = 0;
		me.level_gal_us.setDoubleValue(gals_us);
		me.level_lbs.setDoubleValue(gals_us * me.ppg.getValue());
	},
	set_transfering : func (transfering){
		me.transfering.setBoolValue(transfering);
	},
#	set_dumprate : func (dumprate){
#		me.dumprate.setDoubleValue(dumprate);
#	},
	get_amount : func (dt, ullage) {
		var amount = (flowrate_lbs_hr / (me.ppg.getValue() * 60 * 60)) * dt * 1 ;
		if(amount > me.level_gal_us.getValue()) {
			amount = me.level_gal_us.getValue();
		} 
		if(amount > ullage) {
			amount = ullage;
		} 
		var flowrate_lbs = ((amount/dt) * 60 * 60) * me.ppg.getValue();
		#print ("flowrate_lbsph_actual ", me.name, " ", flowrate_lbs);
		return amount
	},
	get_ullage : func () {
		return me.get_capacity() - me.get_level()
	},
	get_name : func () {
		return me.name.getValue();
	},
	set_transfer_tank : func (dt, tank) {
	# print (me.name.getValue(), " transfer ");
		foreach (var t; Tank.list) {
			if(t.get_name() == tank)  {
				transfer = me.get_amount(dt, t.get_ullage());
				#print (me.name.getValue(), " transfer ", transfer, " ", t.get_name());
				me.set_level(me.get_level() - transfer);
				t.set_level(t.get_level() + transfer);
			} 
		}
	},
	list : [],
};

##
# This class defines a proportioner
#

Prop = {
	new : func (name, number, connect, running) {
		var obj = { parents : [Prop]};
		obj.prop = props.globals.getNode("consumables/fuel").getChild ("tank", number , 1);
		obj.name = obj.prop.getNode("name", 1);
		obj.prop.getChild("name", 0, 1).setValue(name);
		obj.capacity = obj.prop.getNode("capacity-gal_us", 1);
		obj.ppg = obj.prop.getNode("density-ppg", 1);
		obj.level_gal_us = obj.prop.getNode("level-gal_us", 1);
		obj.level_lbs = obj.prop.getNode("level-lbs", 1);
		obj.dumprate = obj.prop.getNode("dump-rate-lbs-hr", 1);
		obj.running = obj.prop.getNode("running", 1);
		obj.running.setBoolValue(running);
		obj.prop.getChild("selected", 0, 1).setBoolValue(connect);
		obj.prop.getChild("dump-rate-lbs-hr", 0, 1).setDoubleValue(0);
		obj.ppg.setDoubleValue(6.3);
		append(Prop.list, obj);
		print ("Proportioner ", obj.name.getValue(), " running ", obj.running.getValue() ); 
		return obj;
	},
	
	set_level : func (gals_us){
		if(gals_us < 0) gals_us = 0;
		me.level_gal_us.setDoubleValue(gals_us);
		me.level_lbs.setDoubleValue(gals_us * me.ppg.getValue());
	},
	set_dumprate : func (dumprate){
		me.dumprate.setDoubleValue(dumprate);
	},
	get_capacity : func {
		return me.capacity.getValue();
	},
	get_level : func {
		return me.level_gal_us.getValue();
	},
	get_running : func {
		return me.running.getValue();
	},
	get_ullage : func () {
		return me.get_capacity() - me.get_level();
	},
	get_name : func () {
		return me.name.getValue();
	},
	get_lbs : func () {
		return me.level_lbs.getValue();
	},
	update : func (amount_lbs) {
		# var servicable = me.get_servicable();
		var neg_g = neg_g.get_neg_g();
		var ppg = me.ppg.getValue();
		var level = me.get_lbs();

		# print("updating prop ", me.name.getValue(),"amount ", amount_lbs, 
		#" level ", level, " ppg ", me.ppg.getValue());
		if (neg_g or level == 0) {
			me.prop.getChild("selected").setBoolValue(0);
			me.running.setBoolValue(0);
			return 1;
		} else {
			me.prop.getChild("selected").setBoolValue(1);
			me.running.setBoolValue(1);
			level = level - amount_lbs ;
			if(level <= 0) level = 0;
			me.set_level(level/ppg);
			return 0;
		}
	},
	get_amount : func (dt, ullage) {
		var amount = (dumprate_lbs_hr / (me.ppg.getValue() * 60 * 60)) * dt * 1 ;
		if(amount > me.level_gal_us.getValue()) {
			amount = me.level_gal_us.getValue();
		}
		if(amount > ullage) {
			amount = ullage;
		}
		var dumprate_lbs = ((amount/dt) * 60 * 60) * me.ppg.getValue();
		# print ("flowrate_lbsph_actual ", me.name, " ", dumprate_lbs);
		return amount
	},
	set_transfer_tank : func (dt, tank) {
	# print (me.name.getValue(), " transfer to ", tank, "running ", me.get_running());
		foreach (var r; Recup.list) {
			if(r.get_name() == tank and me.get_running()) {
				transfer = me.get_amount(dt, r.get_ullage());
				#print (me.name.getValue(), " transfering ", transfer, " ", r.get_name());
				me.set_level(me.get_level() - transfer);
				r.set_level(r.get_level() + transfer);
			}
		}
	},
	jettisonFuel : func (dt) {
		var amount = 0;
		#print("jettisoning fuel ",me.name.getValue()," ", dt, " ", me.get_level() );
		if(me.get_level() > 0 and me.get_running()) {
			amount = (dumprate_lbs_hr / (me.ppg.getValue() * 60 * 60)) * dt * 1 ;
			if(amount > me.level_gal_us.getValue()) {
				amount = me.level_gal_us.getValue();
			}
		}
		var dumprate_lbs = ((amount/dt) * 60) * me.ppg.getValue();
		#print ("dumprate_lbspm_actual ", me.name, " ", dumprate_lbs);
		me.set_dumprate(dumprate_lbs);
		me.set_level(me.get_level() - amount);
	},
	list : [],
};

##
# This class defines a recuperator
#
Recup = {
	new : func (name, number, connect) {
		var obj = { parents : [Recup]};
		obj.prop = props.globals.getNode("consumables/fuel").getChild ("tank", number , 1);
		obj.name = obj.prop.getNode("name", 1);
		obj.prop.getChild("name", 0, 1).setValue(name);
		obj.capacity = obj.prop.getNode("capacity-gal_us", 1);
		obj.ppg = obj.prop.getNode("density-ppg", 1);
		obj.level_gal_us = obj.prop.getNode("level-gal_us", 1);
		obj.level_lbs = obj.prop.getNode("level-lbs", 1);
		obj.prop.getChild("selected", 0, 1).setBoolValue(connect);
		obj.ppg.setDoubleValue(6.3);
		obj.level_gal_us.setDoubleValue(0);
		obj.level_lbs.setDoubleValue(0);
		append(Recup.list, obj);
		print ("Recuperator ", obj.name.getValue()); 
		return obj;
	},
	
	set_level : func (gals_us){
		if(gals_us < 0) gals_us = 0;
		me.level_gal_us.setDoubleValue(gals_us);
		me.level_lbs.setDoubleValue(gals_us * me.ppg.getValue());
	},
#	set_dumprate : func (dumprate){
#		me.dumprate.setDoubleValue(dumprate);
#	},
	get_capacity : func {
		return me.capacity.getValue(); 
	},
	get_level : func {
		return me.level_gal_us.getValue();	
	},
	get_running : func {
		return me.running.getValue();	
	},
	get_ullage : func () {
		return me.get_capacity() - me.get_level();
	},
	get_name : func () {
		return me.name.getValue();
	},
	get_lbs : func () {
		return me.level_lbs.getValue();
	},
	update : func (amount_lbs) {
		# var servicable = me.get_servicable();
		var ppg = me.ppg.getValue();
		var level = me.get_lbs();

		# print("updating recup ", me.name.getValue(), "amount ", amount_lbs, " level ",
		#level, " ppg ", me.ppg.getValue());
		level = level - amount_lbs ;

		if (level <= 0) {
			level = 0;
			me.prop.getChild("selected").setBoolValue(0);
			#me.prop.getChild("running").setBoolValue(0);
			me.set_level(level/ppg);
			return 1;
		} else {
			me.prop.getChild("selected").setBoolValue(1);
			#me.prop.getChild("running").setBoolValue(1);
			me.set_level(level/ppg);
			return 0;
		}

	},
#	get_amount : func (dt, ullage) {
#		var amount = (flowrate_lbs_hr / (me.ppg.getValue() * 60 * 60)) * dt * 1 ;
#		if(amount > me.level_gal_us.getValue()) {
#			amount = me.level_gal_us.getValue();
#		} 
#		if(amount > ullage) {
#			amount = ullage;
#		} 
#		var flowrate_lbs = ((amount/dt) * 60 * 60) * me.ppg.getValue();
#		#print ("flowrate_lbsph_actual ", me.name, " ", flowrate_lbs);
#		return amount
#	},
#	set_transfer_tank : func (dt, tank) {
#	#print (me.name.getValue(), " transfer ");
#		foreach (var t; Tank.list) {
#			if(t.get_name() == tank)  {
#				transfer = me.get_amount(dt, t.get_ullage());
#				#print (me.name.getValue(), " transfer ", transfer, " ", t.get_name());
#				me.set_level(me.get_level() - transfer);
#				t.set_level(t.get_level() + transfer);
#			} 
#		}
#	},
#	jettisonFuel : func (dt) {
#		var amount = 0;
#		#print("jettisoning fuel ",me.name.getValue()," ", dt, " ", me.get_level() );
#		if(me.get_level() > 0 and me.get_running()) {
#			amount = (dumprate_lbs_hr / (me.ppg.getValue() * 60 * 60)) * dt * 1 ;
#			if(amount > me.level_gal_us.getValue()) {
#				amount = me.level_gal_us.getValue();
#			}
#		}
#		var dumprate_lbs = ((amount/dt) * 60) * me.ppg.getValue();
#		#print ("dumprate_lbspm_actual ", me.name, " ", dumprate_lbs);
#		me.set_dumprate(dumprate_lbs);
#		me.set_level(me.get_level() - amount);
#	},
	list : [],
};

###
# this class specifies the negative g switch
##
Neg_g = {
	new : func(switch) {
		var obj = { parents : [Neg_g]};
		obj.prop = props.globals.getNode("controls/fuel/neg-g",1);
		obj.switch = switch;
		obj.prop.setBoolValue(switch);
		obj.acceleration = props.globals.getNode("accelerations/pilot-g", 1);
		obj.check = props.globals.getNode("controls/fuel/recuperator-check", 1);
		print ("Neg-G ", switch); 
		return obj;
	},
	update : func() {
		var acc = me.acceleration.getValue();
		var check = me.check.getValue();
#       print("accleration ",acc );
		if (acc < 0 or check ) {
			me.prop.setBoolValue(1);
		} else {
			me.prop.setBoolValue(0);
		}
	},
	get_neg_g : func() {
		return me.prop.getValue();
	},
};	

###
# this class specifies fuel valves
##

Valve = {
	new : func (name,
				prop,
				initial_pos
				){
		var obj = {parents : [Valve] };
		obj.prop = props.globals.getNode(prop, 1);
		obj.name = name;
		obj.prop.setBoolValue(initial_pos);
		print (obj.name, " ", initial_pos);
		append(Valve.list, obj);
		return obj;
	},
	set : func (valve, pos) {	# operate valve
		foreach (var v; Valve.list) {
			if(v.get_name() == valve) {
#				print("valve ",v.get_name()," ", pos);
				v.prop.setValue(pos);
			}
		}
		
	},
	get : func (valve) {	# valve	position
		var pos = 0;
		foreach (var v; Valve.list) {
			if(v.get_name() == valve) {
#				print("valve ",v.get_name()," ", v.prop.getValue());
				pos = v.prop.getValue();
			}
		}
		return pos;
	},
	get_name : func () {
		return me.name;
	},
	list : [],
}; #
	
# end specify classes
	
##### 
# fire it up
#####
	
	setlistener("sim/signals/fdm-initialized", init_fuel_system);

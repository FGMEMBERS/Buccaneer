# ==============================================================================
# TSR2 canvas HUD.nas
# ==============================================================================
print("TSR2 canvas HUD.nas");
# ==============================================================================
# Head up display
# ==============================================================================
#
# From TSR2 Navigation & Attack System Supplementary Brochure, Appendix 1. (BAC 1964)
#  Also see http://www.flightglobal.com/pdfarchive/view/1964/1964%20-%202714.html
# and http://www.dtic.mil/cgi-bin/GetTRDoc?AD=ADA088554


var pow2 = func(x) { return x * x; };
var vec_length = func(x, y) { return math.sqrt(pow2(x) + pow2(y)); };
var round0 = func(x) { return math.abs(x) > 0.01 ? x : 0; };

var HUD = {
	canvas_settings: {
		"name": "HUD",
		"size": [1024, 1024],
		"view": [1024, 1024],
		"mipmapping": 1
		},
	new: func(placement)
		{
		var m = {
		parents: [HUD],
	canvas: canvas.new(HUD.canvas_settings),
	text_style: {
#       'font': "LiberationFonts/LiberationMono-Regular.ttf",
			'font': "LiberationFonts/LiberationSerif-Regular.ttf",
			'character-size': 18,
			'character-aspect-ration': 0.9
				}
			};

		m.canvas.addPlacement(placement);
		m.canvas.setColorBackground(0.36, 1, 0.3, 0.02);
		m.root = m.canvas.createGroup();
		m.root.setScale(1, 1/math.cos(25 * math.pi/180));
		m.root.setTranslation(512, 512);


# Airspeed
# 100-220 kts scale
		m.airspeed_scale = m.root.createChild("path")
			.moveTo(-240,-290)
			.vert(10)
			.moveTo(-160,-290)
			.vert(4)
			.moveTo(-80,-290)
			.vert(4)
			.moveTo(0,-290)
			.vert(4)
			.moveTo(80,-290)
			.vert(4)
			.moveTo(160,-290)
			.vert(4)					 
			.moveTo(240,-290)
			.vert(4)
			.setStrokeLineWidth(4)
			.setColor(0,1,0, 0.65);
# 100 kts	
		m.airspeed_100 = m.root.createChild("text")
			.setText(sprintf("%d", 1))
			.setFontSize(50, 0.9)
			.setColor(0.36, 1, 0.3)
			.setAlignment("right-center")
			.setTranslation(-160,-320);
# 200 kts				 
		m.airspeed_200 = m.root.createChild("text")
			.setText(sprintf("%d", 2))
			.setFontSize(50, 0.9)
			.setColor(0.36, 1, 0.3)
			.setAlignment("right-center")
			.setTranslation(240,-320);


		m.airspeed_group = m.root.createChild("group");
		m.a_trans = m.airspeed_group.createTransform();
		m.airspeed_pointer = m.airspeed_group.createChild("path")
			.moveTo(-640,-250)
			.vert(20)
			.setStrokeLineWidth(3)
			.setColor(0,1,0, 0.65);

		m.Vr_group = m.root.createChild("group");
		m.Vr_trans = m.Vr_group.createTransform();
		m.Vr_pointer = m.Vr_group.createChild("path")
			.moveTo(-640,-290)
			.vert(20)
			.setStrokeLineWidth(3)
			.setColor(0,1,0, 0.65);



# Altitude
# 0 - 1600 ft scale
		m.alt_scale=m.root.createChild("path")
			.moveTo(-410,240)
			.horiz(5)
			.moveTo(-410,170)
			.horiz(5)
			.moveTo(-410,110)
			.horiz(5)
			.moveTo(-410,40)
			.horiz(5)
			.moveTo(-410,-30)
			.horiz(5)					 
			.moveTo(-410,-100)
			.horiz(5)
			.moveTo(-410,-180)
			.horiz(5)					 
			.moveTo(-410,-240)
			.horiz(5)
			.setStrokeLineWidth(5)
			.setColor(0,1,0, 0.65);
# 0 ft	
		m.alt_0 = m.root.createChild("text")
			.setText(sprintf("%d", 0))
			.setFontSize(50, 0.9)
			.setColor(0.36, 1, 0.3)
			.setAlignment("right-center")
			.setTranslation(-280,250);
# 1000 ft				 
		m.alt_1000 = m.root.createChild("text")
			.setText(sprintf("%d", 10))
			.setFontSize(50, 0.9)
			.setColor(0.36, 1, 0.3)
			.setAlignment("right-center")
			.setTranslation(-230,-100);

		m.altitude_group = m.root.createChild("group");
		m.alt_trans = m.altitude_group.createTransform();
		m.alt_pointer = m.altitude_group.createChild("path")
			.moveTo(-460,240)
			.horiz(40)
			.setStrokeLineWidth(3)
			.setColor(0,1,0, 0.65);

# A/C Bore sight symbol
		m.boresight=
			m.root.createChild("path")
			.moveTo(30, 0)
			.arcSmallCCW(30, 30, 0, -60, 0)
			.arcSmallCCW(30, 30, 0,  60, 0)
			.close()
			.moveTo(-30, 0)
			.horiz(-30)
			.moveTo(30, 0)
			.horiz(30)
			.setStrokeLineWidth(2)
			.setColor(0,1,0, 0.65);

# Horizon
		m.horizon_group = m.root.createChild("group");
		m.h_trans = m.horizon_group.createTransform();
		m.h_rot   = m.horizon_group.createTransform();

# Horizon line
		m.horizon_line = 
			m.horizon_group.createChild("path")
			.moveTo(125, 0)
			.horiz(200)
			.moveTo(-125, 0)
			.horiz(-200)
			.setStrokeLineWidth(2)
			.setColor(0,1,0, 0.65);
# Zenith Star
		m.horizon_zenith =
			m.horizon_group.createChild("path")
			.moveTo(0,-1012)
			.vert(-160)
			.moveTo(-22,-1125)
			.horiz(44)
			.setStrokeLineWidth(2)
			.setColor(0,1,0, 0.65);
# Nadir Star
		m.horizon_nadir =
			m.horizon_group.createChild("path")
			.moveTo(0,1012)
			.vert(160)
			.moveTo(-22,1125)
			.horiz(44)
			.moveTo(-27.5,1150)
			.horiz(55)
			.setStrokeLineWidth(2)
			.setColor(0,1,0, 0.65);

# Flight Director
		m.director_group = m.root.createChild("group");
		m.d_trans = m.director_group.createTransform();
		m.d_rot   = m.director_group.createTransform();

# flight director bars
		m.director_datum = m.director_group.createChild("path")
			.moveTo(2, 0)
			.arcSmallCCW(2, 2, 0, -4, 0)
			.arcSmallCCW(2, 2, 0,  4, 0)
			.setStrokeLineWidth(2)
			.setColor(0,1,0, 0.65);	
		m.d0_trans   = m.director_datum.createTransform();			
		m.director_bar1 = m.director_group.createChild("path")
			.moveTo(-37.5,40)
			.horiz(75)
			.setStrokeLineWidth(2)
			.setColor(0,1,0, 0.65);	
		m.d1_trans   = m.director_bar1.createTransform();	
		m.director_bar2 = m.director_group.createChild("path")
			.moveTo(-110,120)
			.horiz(220)
			.setStrokeLineWidth(2)
			.setColor(0,1,0, 0.65);	
		m.d2_trans   = m.director_bar2.createTransform();				
		m.director_bar3 = m.director_group.createChild("path")
			.moveTo(-220,240)
			.horiz(440)
			.setStrokeLineWidth(2)
			.setColor(0,1,0, 0.65);	
		m.d3_trans   = m.director_bar3.createTransform();	
		m.director_bar4 = m.director_group.createChild("path")
			.moveTo(-280,400)
			.horiz(560)
			.setStrokeLineWidth(2)
			.setColor(0,1,0, 0.65);	
		m.d4_trans   = m.director_bar4.createTransform();	

		m.input = {
			pitch:    "/orientation/pitch-deg",
			roll:     "/orientation/roll-deg",
			hdg:      "/orientation/heading-deg",
			##     pitch:    "/instrumentation/master-reference-gyro/indicated-pitch-deg",
			##     roll:     "/instrumentation/master-reference-gyro/indicated-roll-deg",
			##     hdg:      "/instrumentation/master-reference-gyro/indicated-hdg-deg",	  	  
			speed_n:  "/velocities/speed-north-fps",
			speed_e:  "/velocities/speed-east-fps",
			speed_d:  "/velocities/speed-down-fps",
			alpha:    "/orientation/alpha-deg",
			beta:     "/orientation/side-slip-deg",
			ias:      "/velocities/airspeed-kt",
			gs:       "/velocities/groundspeed-kt",
			vs:       "/velocities/vertical-speed-fps",
			##      rad_alt:  "instrumentation/radar-altimeter/radar-altitude-ft",
			rad_alt:  "/position/altitude-agl-ft",
			wow_nlg:  "/gear/gear[4]/wow",
			Vr:       "/controls/switches/HUD_rotation_speed",
			Bright:   "/controls/switches/HUD_brightness",
			Dir_sw: "/controls/switches/HUD_director", 
			H_sw:   "/controls/switches/HUD_height", 
			Speed_sw:    "/controls/switches/HUD_speed", 
			Test_sw:     "/controls/switches/HUD_test",
			fdpitch:     "/autopilot/settings/fd-pitch-deg",
			fdroll:      "/autopilot/settings/fd-roll-deg",
			fdspeed:     "/autopilot/settings/target-speed-kt"	  

			}; 

		foreach(var name; keys(m.input))
			m.input[name] = props.globals.getNode(m.input[name], 1);

		return m;
		},
	update: func()
			{
#			print("hud updating");
			var pitchfd = me.input.fdpitch.getValue() or 0;
			var rollfd = me.input.fdroll.getValue() or 0;
			me.d_trans.setTranslation(0,-12.5 * pitchfd);
			me.d0_trans.setTranslation(5 * rollfd,0);
			me.d1_trans.setTranslation(4.5 * rollfd,0);
			me.d2_trans.setTranslation(3 * rollfd,0);
			me.d3_trans.setTranslation(2 * rollfd,0);
			me.d4_trans.setTranslation(0 * rollfd,0);
			var in_ias = me.input.ias.getValue() or 0;
			me.a_trans.setTranslation(4 * in_ias,0);
			var in_Vr = me.input.Vr.getValue() or 0;
			me.Vr_trans.setTranslation(4 * in_Vr,0);

#   me.alt_trans.setTranslation(0, -0.1 *getprop("/instrumentation/radar-altimeter/radar-altitude-ft"));
			var radalt = me.input.rad_alt.getValue() or 0;
			me.alt_trans.setTranslation(0, -0.35 * radalt);
			
			var in_pitch = me.input.pitch.getValue() or 0;
			me.h_trans.setTranslation(0, 12.5 * in_pitch);

			var in_rot = -me.input.roll.getValue() or 0;
			var rot = in_rot * math.pi / 180.0;
			me.h_rot.setRotation(rot);
			me.d_rot.setRotation(rot);

			var bright = me.input.Bright.getValue() or 0;
			var sw_d = me.input.Dir_sw.getValue() or 0;	
			var sw_h = me.input.H_sw.getValue() or 0;
			var sw_s = me.input.Speed_sw.getValue() or 0;	
			var sw_t = me.input.Test_sw.getValue() or 0;

			var G = bright;
			var A = 0.65 * bright;
			var Gd = bright * sw_d;
			var Ad = 0.65 * bright * sw_d;
			var Gh = bright * sw_h;
			var Ah = 0.65 * bright * sw_h;
			var Gs = bright * sw_s;
			var As = 0.65 * bright * sw_s;	

			me.airspeed_scale.setColor(0.0,Gs,0.0,As);	
			me.airspeed_100.setColor(0.0,Gs,0.0,As);	
			me.airspeed_200.setColor(0.0,Gs,0.0,As);		
			me.airspeed_pointer.setColor(0.0,Gs,0.0,As);	
			me.Vr_pointer.setColor(0.0,Gs,0.0,As);		
			me.alt_scale.setColor(0.0,Gh,0.0,Ah);	
			me.alt_0.setColor(0.0,Gh,0.0,Ah);	
			me.alt_1000.setColor(0.0,Gh,0.0,Ah);		
			me.alt_pointer.setColor(0.0,Gh,0.0,Ah);	
			me.boresight.setColor(0.0,G,0.0,A);
			me.horizon_line.setColor(0.0,G,0.0,A);
#   me.horizon_pitch.setColor(0.0,G,0.0,A);
			me.horizon_zenith.setColor(0.0,G,0.0,A);	
			me.horizon_nadir.setColor(0.0,G,0.0,A);	
			me.director_datum.setColor(0.0,Gd,0.0,Ad);
			me.director_bar1.setColor(0.0,Gd,0.0,Ad);	
			me.director_bar2.setColor(0.0,Gd,0.0,Ad);
			me.director_bar3.setColor(0.0,Gd,0.0,Ad);
			me.director_bar4 .setColor(0.0,Gd,0.0,Ad);

# flight path vector (FPV)
			var vel_gx = me.input.speed_n.getValue();
			var vel_gy = me.input.speed_e.getValue();
			var vel_gz = me.input.speed_d.getValue();

			var yaw = me.input.hdg.getValue() * math.pi / 180.0;
			var roll = me.input.roll.getValue() * math.pi / 180.0;
			var pitch = me.input.pitch.getValue() * math.pi / 180.0;

			var sy = math.sin(yaw);   var cy = math.cos(yaw);
			var sr = math.sin(roll);  var cr = math.cos(roll);
			var sp = math.sin(pitch); var cp = math.cos(pitch);

			var vel_bx = vel_gx * cy * cp
				+ vel_gy * sy * cp
				+ vel_gz * -sp;
			var vel_by = vel_gx * (cy * sp * sr - sy * cr)
				+ vel_gy * (sy * sp * sr + cy * cr)
				+ vel_gz * cp * sr;
			var vel_bz = vel_gx * (cy * sp * cr + sy * sr)
				+ vel_gy * (sy * sp * cr - cy * sr)
				+ vel_gz * cp * cr;

			var dir_y = math.atan2(round0(vel_bz), math.max(vel_bx, 0.01)) * 180.0 / math.pi;
			var dir_x  = math.atan2(round0(vel_by), math.max(vel_bx, 0.01)) * 180.0 / math.pi;

#####me.vec_vel.setTranslation(dir_x * 18, dir_y * 18);

			settimer(func me.update(), 0);
			}
	};

var init = setlistener("/sim/signals/fdm-initialized", func() {
	removelistener(init); # only call once
		var hud_pilot = HUD.new({"node": "HUD-canvas"});
	hud_pilot.update();
#  var hud_copilot = HUD.new({"node": "HUD-canvas.001"});
#  hud_copilot.update();
	});

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

#does what it says on the tin
var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }
var pow2 = func(x) { return x * x; };
var vec_length = func(x, y) { return math.sqrt(pow2(x) + pow2(y)); };
var round0 = func(x) { return math.abs(x) > 0.01 ? x : 0; };
var deg2rads = math.pi/180;

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

		var w = 6;
		var r = 0.0;
		var g = 1.0;
		var b = 0.0;
		var a = 0.65;

# Airspeed
# 300-600 kts scale
		var p = 230;
		var h = 6;
		m.airspeed_scale = m.root.createChild("path")
			.moveTo(-90, p)
			.vert(h)
			.moveTo(-30, p)
			.vert(h)
			.moveTo(30, p)
			.vert(h)
			.moveTo(90, p)
			.vert(h)
			.setStrokeLineWidth(w)
			.setStrokeLineCap("round")
			.setColor(r, g, b, a);

		m.airspeed_group = m.root.createChild("group");
		m.a_trans = m.airspeed_group.createTransform();
		m.airspeed_pointer = m.airspeed_group.createChild("path")
			.moveTo(-90, p + 2 * h)
			.vert(h)
			.setStrokeLineWidth(w)
			.setStrokeLineCap("round")
			.setColor(r, g, b, a);

		m.Vr_group = m.root.createChild("group");
		m.Vr_trans = m.Vr_group.createTransform();
		m.Vr_pointer = m.Vr_group.createChild("path")
			.moveTo(-640,-290)
			.vert(20)
			.setStrokeLineWidth(w)
			.setStrokeLineCap("round")
			.setColor(r, g, b, a);


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
			.setStrokeLineWidth(w)
			.setStrokeLineCap("round")
			.setColor(r, g, b, a);

# Quadrantal symbols
		var k = 14;
		var j = 120;
		m.quadrantal=
			m.root.createChild("path")
			.moveTo(j, 0)
			.horiz(k)
			.moveTo(-j, 0)
			.horiz(-k)
			.moveTo(0, j)
			.vert(k)
			.moveTo(0, -j)
			.vert(-k)
			.setStrokeLineWidth(w)
			.setStrokeLineCap("round")
			.setColor(r, g, b, a);

# Target Spot
		m.target_group = m.root.createChild("group");
		m.h_trans = m.target_group.createTransform();
		m.v_trans = m.target_group.createTransform();

# Spot
		m.target_spot = 
			m.target_group.createChild("path")
			.moveTo(10, 0)
			.arcSmallCCW(10, 10, 0, -20, 0)
			.arcSmallCCW(10, 10, 0,  20, 0)
			.close()
			.setStrokeLineWidth(w)
			.setColorFill(r, g, b, a)
			.setColor(r, g, b, a);

# Range Marker
		m.range_group = m.root.createChild("group");
		m.h_trans = m.range_group.createTransform();
		m.v_trans = m.range_group.createTransform();

# Marker
		m.range_marker = 
			m.range_group.createChild("path")
			.moveTo(0, 0)
			.arcLargeCW(j, j, 0, 2 * j, 1.5)
			.setRotation(90 * deg2rads, 0, 0)
			.setTranslation(0,-j)
#			.arcSmallCW(j, j, 0, -2 * j, 0)
#			.close()
			.setStrokeLineWidth(w)
			.setColor(r, g, b, a);

# Marker
		m.range_marker2 = 
			m.range_group.createChild("path")
			.moveTo(0, -j)
			.arcLargeCW(j, j, 0, 2 * j, 0.1)
			.moveTo(j, -j)
			.setRotation(-90 * deg2rads, j, 0)
			.setTranslation(j,j)
#			.arcSmallCW(j, j, 0, -2 * j, 0)
#			.close()
			.setStrokeLineWidth(w)
			.setColor(r, g, b, a);

# Horizon
		m.horizon_group = m.root.createChild("group");
		m.h_trans = m.horizon_group.createTransform();
		m.h_rot   = m.horizon_group.createTransform();

# Horizon line
		var l = 150;
		m.horizon_line = 
			m.horizon_group.createChild("path")
			.moveTo(125, 0)
			.horiz(l)
			.moveTo(-125, 0)
			.horiz(-l)
			.setStrokeLineWidth(w)
			.setStrokeLineCap("round")
			.setColor(r, g, b, a);

# Zenith Star
		m.horizon_zenith =
			m.horizon_group.createChild("path")
			.moveTo(0,-1012)
			.vert(-160)
			.moveTo(-22,-1125)
			.horiz(44)
			.setStrokeLineWidth(w)
			.setColor(r, g, b, a);

# Nadir Star
		m.horizon_nadir =
			m.horizon_group.createChild("path")
			.moveTo(0,1012)
			.vert(160)
			.moveTo(-22,1125)
			.horiz(44)
			.moveTo(-27.5,1150)
			.horiz(55)
			.setStrokeLineWidth(w)
			.setColor(r, g, b, a);

#  input properties
		m.input = {
			## pitch:    "/orientation/pitch-deg",
			##roll:     "/orientation/roll-deg",
			##hdg:      "/orientation/heading-deg",
			pitch:    "/instrumentation/master-reference-gyro/indicated-pitch-deg",
			roll:     "/instrumentation/master-reference-gyro/indicated-roll-deg",
			hdg:      "/instrumentation/master-reference-gyro/indicated-hdg-deg",
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
			wow_nlg:  "/gear/gear[0]/wow",
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
#			me.d_trans.setTranslation(0,-12.5 * pitchfd);
#			me.d0_trans.setTranslation(5 * rollfd,0);
#			me.d1_trans.setTranslation(4.5 * rollfd,0);
#			me.d2_trans.setTranslation(3 * rollfd,0);
#			me.d3_trans.setTranslation(2 * rollfd,0);
#			me.d4_trans.setTranslation(0 * rollfd,0);
			var in_ias = me.input.ias.getValue() or 0;
			in_ias = clamp(in_ias, 300, 600);
			me.a_trans.setTranslation(0.6 * (in_ias - 300), 0);
			var in_Vr = me.input.Vr.getValue() or 0;
			me.Vr_trans.setTranslation(4 * in_Vr,0);

#   me.alt_trans.setTranslation(0, -0.1 *getprop("/instrumentation/radar-altimeter/radar-altitude-ft"));
#			var radalt = me.input.rad_alt.getValue() or 0;
#			me.alt_trans.setTranslation(0, -0.35 * radalt);
#			
			var in_pitch = me.input.pitch.getValue() or 0;
			me.h_trans.setTranslation(0, 12.5 * in_pitch);

#			var in_rot = -me.input.roll.getValue() or 0;
#			var rot = in_rot * math.pi / 180.0;
#			me.h_rot.setRotation(rot);
#			me.d_rot.setRotation(rot);

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
#			me.airspeed_100.setColor(0.0,Gs,0.0,As);	
#			me.airspeed_200.setColor(0.0,Gs,0.0,As);		
			me.airspeed_pointer.setColor(0.0,Gs,0.0,As);	
			me.Vr_pointer.setColor(0.0,Gs,0.0,As);		
#			me.alt_scale.setColor(0.0,Gh,0.0,Ah);	
#			me.alt_0.setColor(0.0,Gh,0.0,Ah);	
#			me.alt_1000.setColor(0.0,Gh,0.0,Ah);		
#			me.alt_pointer.setColor(0.0,Gh,0.0,Ah);	
#			me.boresight.setColor(0.0,G,0.0,A);
#			me.horizon_line.setColor(0.0,G,0.0,A);
#   me.horizon_pitch.setColor(0.0,G,0.0,A);
#			me.horizon_zenith.setColor(0.0,G,0.0,A);	
#			me.horizon_nadir.setColor(0.0,G,0.0,A);	
#			me.director_datum.setColor(0.0,Gd,0.0,Ad);
#			me.director_bar1.setColor(0.0,Gd,0.0,Ad);	
#			me.director_bar2.setColor(0.0,Gd,0.0,Ad);
#			me.director_bar3.setColor(0.0,Gd,0.0,Ad);
#			me.director_bar4 .setColor(0.0,Gd,0.0,Ad);

# flight path vector (FPV)
#			var vel_gx = me.input.speed_n.getValue();
#			var vel_gy = me.input.speed_e.getValue();
#			var vel_gz = me.input.speed_d.getValue();

#			var yaw = me.input.hdg.getValue() * math.pi / 180.0;
#			var roll = me.input.roll.getValue() * math.pi / 180.0;
#			var pitch = me.input.pitch.getValue() * math.pi / 180.0;

#			var sy = math.sin(yaw);   var cy = math.cos(yaw);
#			var sr = math.sin(roll);  var cr = math.cos(roll);
#			var sp = math.sin(pitch); var cp = math.cos(pitch);

#			var vel_bx = vel_gx * cy * cp
#				+ vel_gy * sy * cp
#				+ vel_gz * -sp;
#			var vel_by = vel_gx * (cy * sp * sr - sy * cr)
#				+ vel_gy * (sy * sp * sr + cy * cr)
#				+ vel_gz * cp * sr;
#			var vel_bz = vel_gx * (cy * sp * cr + sy * sr)
#				+ vel_gy * (sy * sp * cr - cy * sr)
#				+ vel_gz * cp * cr;

#			var dir_y = math.atan2(round0(vel_bz), math.max(vel_bx, 0.01)) * 180.0 / math.pi;
#			var dir_x  = math.atan2(round0(vel_by), math.max(vel_bx, 0.01)) * 180.0 / math.pi;

#			me.range_marker.setRotation(90 * deg2rads, 10, -10);

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

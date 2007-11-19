var model_view_handler = {
init : func {
	me.models = {};
	me.list = [];
	me.current = 0;
	me.active = 0;
	   },
start : func {
	   me.models = {};
	   var ai = props.globals.getNode("/ai/models", 1);
	   foreach (var m; [props.globals]
		   ~ ai.getChildren("multiplayer"))
		   me.models[m.getPath()] = m;

	   me.lnr = [];
	   append(me.lnr, setlistener("/ai/models/model-added", func(n) {
		   var m = props.globals.getNode(n.getValue(), 1);
		   me.models[m.getPath()] = m;
	   }));
	   append(me.lnr, setlistener("/ai/models/model-removed", func(n) {
		   var m = props.globals.getNode(n.getValue(), 1);
		   delete(me.models, m.getPath());
	   }));
	   append(me.lnr, setlistener("/devices/status/mice/mouse/mode", func(n) {
		   me.mouse_mode = n.getValue();
	   }, 1));
	   append(me.lnr, setlistener("/devices/status/mice/mouse/button", func(n) {
		   me.mouse_button = n.getValue();
		   if (me.mouse_button == 1)
			   me.mouse_start = me.mouse_y;
	   }, 1));
	   append(me.lnr, setlistener("/devices/status/mice/mouse/y", func(n) {
		   me.mouse_y = n.getValue();
	   }, 1));
	   me.offs = 0;
	   me.active = 1;
	   me.reset();
	   },
update : func {
	   if (me.mouse_mode == 0 and me.mouse_button) {
		   var curr = getprop("/sim/current-view/z-offset-m") - me.offs;
		   me.offs += me.mouse_y - me.mouse_start;
		   var new = curr + me.offs;
		   if (new < 1)
			   new = 1;
		   setprop("/sim/current-view/z-offset-m", new);
		   me.mouse_start = me.mouse_y;
	   }
	   return 0;
	   },
stop : func {
	   me.active = 0;
	   foreach (var listener; me.lnr)
		   removelistener(listener);
	   },
reset : func {
	   me.next(me.current = 0);
	   },
next : func(v) {
	   if (!me.active or !size(me.models))
		   return;
	   if (v)
		   me.current += v;
	   else
		   me.current = 0;

	   me.list = sort(keys(me.models), cmp);
	   if (me.current < 0)
		   me.current = size(me.list) - 1;
	   elsif (me.current >= size(me.list))
		   me.current = 0;

	   var c = me.list[me.current];
	   var s = "/sim/view[98]/config";
	   setprop(s, "eye-lat-deg-path", c ~ "/position/latitude-deg");
	   setprop(s, "eye-lon-deg-path", c ~ "/position/longitude-deg");
	   setprop(s, "eye-alt-ft-path", c ~ "/position/altitude-ft");
	   setprop(s, "eye-heading-deg-path", c ~ "/orientation/true-heading-deg");
	   setprop(s, "eye-pitch-deg-path", c ~ "/orientation/pitch-deg");
	   setprop(s, "eye-roll-deg-path", c ~ "/orientation/roll-deg");

	   var n = me.models[me.list[me.current]];
	   var type = n.getName();
	   var name = nil;

	   if (type == "") {
		   var z = getprop("/sim/chase-distance-m");
		   if (name = getprop("/sim/multiplay/callsign"))
			   name = 'callsign "' ~ name ~ '"';
	   } else {
		   if ((name = n.getNode("name")) != nil and (name = name.getValue()))
			   name = n.getName() ~ ' "' ~ name ~ '"';
	   }

	   var color = {};
	   if (type != "multiplayer")
		   color = { text: { color: { red: 0.5, green: 0.8, blue: 0.5 }}};
	   if (getprop("/sim/current-view/view-number") == 98)
		   setprop("/sim/current-view/z-offset-m", me.offs = z);
	   if (name)
		   gui.popupTip(name, 2, color);
	   },
};

setlistener("/sim/signals/fdm-initialized", func {
	view.manager.register("Model View", model_view_handler);
	view.manager.register("Copilot View", model_view_handler);
});
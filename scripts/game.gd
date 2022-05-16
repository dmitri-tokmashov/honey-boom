extends Node;

var current = 0;
var honeyneed = 0;
var honeyneed_max = 100;
var bees = [];
var shells = [];
var honeypots = [0, 0, 0, 0, 0];
var circle = OS.get_ticks_msec();
var reload = OS.get_ticks_msec();
onready var balloon = $world/balloon;
onready var pooh = $world/balloon/pooh;
#[96, 144][832, 112][832, 280]

func _ready():
	for number in [1, 3, 4]:
		get_node("world/beehive_" + str(number)).connect("draw", self, "_draw_beehive", [number]);
	for count in range(5):
		var bee = $world/bee.duplicate();
		$world.add_child(bee);
		bees.append(bee);
		bee.mode = RigidBody2D.MODE_RIGID;
		bee.collision_layer = 1;
		bee.collision_mask = 1;
		bee.position = Vector2(768 + rand_range(- 32, 32), 112 + rand_range(- 32, 32));
		bee.visible = true;

func _process(delta):
	for number in [1, 3, 4]:
		get_node("world/beehive_" + str(number)).update();
	$interface.update();
	for number in range(5):
		var honeypot = get_node("world/honeypot_" + ["brown", "green", "purple", "blue", "red"][number]);
		if honeypot.monitorable:
			if honeypot.get_node("sprite").scale < Vector2(0.1, 0.1):
				honeypot.get_node("sprite").scale += Vector2.ONE * delta;
			else:
				honeypot.get_node("sprite").scale = Vector2.ONE * (0.1125 + 0.0125 * sin(fmod((OS.get_ticks_msec() * 0.0048), PI * 2)));
		elif honeypot.get_node("sprite").scale > Vector2(0.008, 0.008):
			honeypot.get_node("sprite").scale -= Vector2.ONE * delta;
		elif honeypot.get_node("sprite").visible:
			honeypot.get_node("sprite").visible = false;
			$world/arrow.visible = true;
			$world/storage.monitorable = true;
			if pooh.global_position.distance_to(Vector2(832, 112)) < 128:
				_add_bee(3);
			elif pooh.global_position.distance_to(Vector2(832, 280)) < 128:
				_add_bee(4);
			elif pooh.global_position.distance_to(Vector2(96, 144)) < 128:
				_add_bee(1);
	$world/piglet/boomstick.rotation_degrees = 35 * sin(fmod((OS.get_ticks_msec() * 0.001), PI * 2)) - 30;
	honeyneed += delta;
	if honeyneed >= honeyneed_max:
		honeyneed = honeyneed_max - 0.01;
		if pooh.get_parent() == balloon:
			var _position = pooh.global_position;
			var _rotation = pooh.global_rotation;
			balloon.remove_child(pooh);
			$world/balloon/joint_balloon.queue_free();
			$world/balloon/joint_pooh.queue_free();
			$world/balloon/rope.queue_free();
			balloon.mass = 8;
			balloon.collision_layer = 2;
			balloon.collision_mask = 2;
			balloon.z_index = 2;
			$world.add_child(pooh);
			pooh.position = _position;
			pooh.rotation = _rotation;
			pooh.gravity_scale = 4;
	if pooh.get_node("circle").visible:
		if pooh.get_node("circle").scale.x < 0.25:
			pooh.get_node("circle").scale += Vector2.ONE * delta / 2;
			pooh.get_node("circle").rotation += delta * 8;
		else:
			pooh.get_node("circle").scale = Vector2.ZERO;
			pooh.get_node("circle").rotation = 0;
			pooh.get_node("circle").visible = false;
	var _distance = 0;
	for bee in bees:
		_distance += pooh.global_position.distance_to(bee.position);
	if $world/cloud_left.position.x < 1024:
		$world/cloud_left.position.x += delta * 48;
		$world/cloud_right.position.x -= delta * 48;
	else:
		$world/cloud_left.position.x = - 64;
		$world/cloud_right.position.x = 1024;
	$audio/buzz.volume_db = - 8 - _distance / bees.size() / 16;

func _physics_process(delta):
	var _force;
	if is_instance_valid(balloon):
		_force = Vector2(0, - 784);
		if Input.is_action_pressed("pooh_up"):
			_force.y -= 4096 * pooh.mass * delta;
		if Input.is_action_pressed("pooh_down") and balloon.position.y < 420:
			_force.y += 4096 * pooh.mass * delta;
		if Input.is_action_pressed("pooh_left"):
			_force.x -= 4096 * pooh.mass * delta;
		if Input.is_action_pressed("pooh_right"):
			_force.x += 4096 * pooh.mass * delta;
		balloon.set_applied_force(_force);
	for number in range(5):
		var honeypot = get_node("world/honeypot_" + ["brown", "green", "purple", "blue", "red"][number]);
		if honeypot.monitorable and honeypot.overlaps_body(pooh):
			honeypot.monitorable = false;
			if number != 0:
				for string in ["green", "purple", "blue", "red"]:
					if get_node("world/honeypot_" + string).monitorable:
						get_node("world/honeypot_" + string).monitorable = false;
			if honeyneed > 40:
				honeyneed -= 40;
			else:
				honeyneed = 0;
			current = number + 1;
	if $world/storage.monitorable and $world/storage.overlaps_body(pooh):
		var _honeypots = [];
		if (honeypots[0] + honeypots[1] + honeypots[2] + honeypots[3] + honeypots[4] + 1) % 4 < 3:
			_honeypots = [$world/honeypot_brown];
		else:
			while true:
				_honeypots = [[$world/honeypot_green, $world/honeypot_purple, $world/honeypot_blue, $world/honeypot_red][randi()%4], [$world/honeypot_green, $world/honeypot_purple, $world/honeypot_blue, $world/honeypot_red][randi()%4]];
				if _honeypots[0] != _honeypots[1]:
					break;
		var _position = [Vector2(96, 144), Vector2(832, 112), Vector2(832, 280)];
		for honeypot in _honeypots:
			honeypot.monitorable = true;
			honeypot.position = _position[randi()%_position.size()];
			honeypot.get_node("sprite").visible = true;
			honeypot.get_node("sprite").scale = Vector2.ZERO;
			_position.erase(honeypot.position);
		$world/arrow.visible = false;
		$world/storage.monitorable = false;
		if honeypots[current - 1] == 0:
			$interface/honeypots.get_node(["brown", "green", "purple", "blue", "red"][current - 1]).visible = true;
		honeypots[current - 1] += 1;
		if current == 2:
			honeyneed_max += 10;
		elif current == 4:
			balloon.get_node("sprite").scale = Vector2.ONE * 0.0125 * (10 + honeypots[3]);
			balloon.get_node("sprite").position.y -= 2.2;
			balloon.get_node("shape").scale = balloon.get_node("sprite").scale;
			balloon.get_node("shape").position.y -= 2.2;
		$interface/honeypots/.get_node(["brown", "green", "purple", "blue", "red"][current - 1] + "/number").text = str(honeypots[current - 1]);
		if honeypots[0] > 2:
			_add_bee(1);
		if honeypots[0] > 5:
			_add_bee(3);
		if honeypots[0] > 8:
			_add_bee(4);
	for bee in bees:
		_force = Vector2(rand_range(- 48, 48), - 98 + rand_range(- 8, 8));
		if bee.collision_layer == 1:
			if ((bee.get_node("yellow").visible and bee.position.distance_to(pooh.global_position) < 240) or (bee.get_node("red").visible and bee.position.distance_to(pooh.global_position) < 360)) and not ($world/cloud_left.overlaps_body(pooh) or $world/cloud_right.overlaps_body(pooh)):
				if bee.position.x > pooh.global_position.x:
					_force.x -= 2048 * delta;
					if bee.get_node("yellow").visible and bee.get_node("yellow").flip_v:
						bee.get_node("yellow").flip_v = false;
					elif bee.get_node("red").visible and bee.get_node("red").flip_v:
						bee.get_node("red").flip_v = false;
				elif bee.position.x < pooh.global_position.x:
					_force.x += 2048 * delta;
					if bee.get_node("yellow").visible and not bee.get_node("yellow").flip_v:
						bee.get_node("yellow").flip_v = true;
					elif bee.get_node("red").visible and not bee.get_node("red").flip_v:
						bee.get_node("red").flip_v = true;
				if bee.position.y > pooh.global_position.y:
					_force.y -= 2048 * delta;
				elif bee.position.y < pooh.global_position.y:
					_force.y += 2048 * delta;
				if bee.get_node("red").visible:
					_force *= 1.5;
			else:
				if bee.position.y > 420:
					_force.y -= 2048 * delta;
				elif bee.position.y < 32:
					_force.y += 2048 * delta;
			if pooh in bee.get_colliding_bodies():
				if bee.get_node("yellow").visible:
					honeyneed += 4 * delta;
				else:
					honeyneed += 8 * delta;
				if honeypots[2] != 0 and OS.get_ticks_msec() - circle > 5000:
					circle = OS.get_ticks_msec();
					pooh.get_node("circle").visible = true;
		elif bee.position.distance_to(get_node("world/beehive_" + str(bee.collision_layer - 1)).position) < 56:
			_force.x = get_node("world/beehive_" + str(bee.collision_layer - 1)).scale.x * - 480 * delta;
		else:
			bee.collision_layer = 1;
			bee.collision_mask = 1;
		if pooh.get_node("circle").visible and pooh.global_position.distance_to(bee.position) < 16 * (honeypots[2] + 1):
			_force = Vector2(- 8192 * delta, 0).rotated(pooh.global_position.angle_to_point(bee.position));
		elif (bee.get_node("yellow").visible and not bee.get_node("yellow").playing) or (bee.get_node("red").visible and not bee.get_node("red").playing):
			_force.y += 512 * delta;
			if bee.modulate.a > 0.008:
				bee.modulate.a -= delta;
			else:
				bees.erase(bee);
				bee.queue_free();
		bee.set_applied_force(_force);
		bee.rotation = bee.position.angle_to_point(pooh.global_position);
	for shell in shells:
		if is_instance_valid(balloon) and shell.overlaps_body(balloon):
			if honeypots[3] == 0:
				balloon.visible = false;
				var _position = pooh.global_position;
				var _rotation = pooh.global_rotation;
				balloon.remove_child(pooh);
				$world.add_child(pooh);
				$world/balloon/joint_balloon.queue_free();
				$world/balloon/joint_pooh.queue_free();
				$world/balloon/rope.queue_free();
				pooh.position = _position;
				pooh.rotation = _rotation;
				pooh.gravity_scale = 4;
				balloon.queue_free();
				$audio/balloon.play();
			else:
				honeypots[3] -= 1;
				balloon.get_node("sprite").scale = Vector2.ONE * 0.0125 * (10 + honeypots[3]);
				balloon.get_node("sprite").position.y += 2.2;
				balloon.get_node("shape").scale = balloon.get_node("sprite").scale;
				balloon.get_node("shape").position.y += 2.2;
				$interface/honeypots/blue/number.text = str(honeypots[3]);
				shells.erase(shell);
				shell.queue_free();
				$audio/balloon.play();
				break;
		if shell.monitorable and (shell.overlaps_body($world/tree_right) or shell.overlaps_body($world/beehive_3) or shell.overlaps_body($world/beehive_4)):
			shell.rotation_degrees = 180 - shell.rotation_degrees;
			shell.monitorable = false;
		for bee in bees:
			if shell.overlaps_body(bee):
				if bee.get_node("yellow").visible:
					bee.get_node("yellow").playing = false;
				else:
					bee.get_node("red").playing = false;
				bee.gravity_scale = 2;
				$audio/bee.play();
				shells.erase(shell);
				shell.queue_free();
				break;
		if shell.position.distance_to($world/piglet.position) < 1024:
			shell.position.x = shell.position.x + 960 * delta * cos(shell.rotation);
			shell.position.y = shell.position.y + 960 * delta * sin(shell.rotation);
		else:
			shells.erase(shell);
			shell.queue_free();

func _input(event):
	if event is InputEventMouseButton and event.pressed and OS.get_ticks_msec() - reload > 3000:
		reload = OS.get_ticks_msec();
		for number in range(honeypots[4] + 1):
			var shell = $world/piglet/boomstick/shell.duplicate();
			shell.visible = true;
			shell.position = $world/piglet/boomstick/shell.global_position;
			shell.rotation_degrees = $world/piglet/boomstick.rotation_degrees - 24;
			if honeypots[4] > 0:
				shell.rotation_degrees -= 10 - 20.0 / honeypots[4] * number;
			shells.append(shell);
			$world.add_child(shell);
		get_node("audio/pop_" + str(randi()%3 + 1)).play();

func _draw_beehive(number):
	get_node("world/beehive_" + str(number)).draw_rect(Rect2(- 12, 38, 16, 16), Color8(32, 32, 0), true);

func _add_bee(number):
	var bee = $world/bee.duplicate();
	if rand_range(0, honeypots[0]) > 3:
		bee.get_node("yellow").visible = false;
		bee.get_node("red").visible = true;
	$world.add_child(bee);
	bees.append(bee);
	bee.mode = RigidBody2D.MODE_RIGID;
	bee.collision_layer = number + 1;
	bee.collision_mask = bee.collision_layer;
	bee.position = get_node("world/beehive_" + str(number)).to_global(get_node("world/beehive_" + str(number) + "/sprite").position + Vector2(4, 46).rotated(get_node("world/beehive_" + str(number)).rotation));
	bee.visible = true;

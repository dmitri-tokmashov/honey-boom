extends Control

onready var balloon = $"../world/balloon";
onready var pooh = $"../world/balloon/pooh";

func _draw():
	if is_instance_valid(balloon) and pooh.get_parent() == balloon:
		draw_line(balloon.position + Vector2(- 1, 22).rotated(balloon.rotation), pooh.global_position + Vector2(0, - 10).rotated(pooh.global_rotation), Color8(16, 16, 0), 0.8, true);

func _process(delta):
	if $tutorial/arrow.visible and get_parent().current != 0:
		$tutorial/arrow.visible = false;
		$tutorial/text.text = "Оставляй горшочки\nу Пятачка";
		$tutorial/text.anchor_left = 0.186;
		$tutorial/text.anchor_top = 0.761;
		$tutorial/text.anchor_right = 0.47;
		$tutorial/text.anchor_bottom = 0.869;
	elif $tutorial/text.visible and get_parent().honeypots[0] != 0:
		$tutorial/text.visible = false;
	#$honeyneed.text = "Медохотелка:\n" + ["Хочется совсем чуть-чуть", "Хочется немножко", "Мысли о меде плотно засели в опилках", "Всюду мерещятся горшочки", "Жить не могу без меда"][floor(get_parent().honeyneed / 20)];
	$honeyneed.text = "Медохотелка:\n" + str(round(get_parent().honeyneed)) + " из " + str(get_parent().honeyneed_max);
	$honeyneed.add_color_override("font_color", [Color8(96, 224, 96), Color8(192, 224, 32), Color8(224, 192, 16), Color8(255, 96, 0), Color8(192, 0, 0)][floor(get_parent().honeyneed / (get_parent().honeyneed_max / 5))]);
	if pooh.get_parent() != balloon and not $game_over.visible:
		$tutorial.visible = false;
		$honeyneed.visible = false;
		$game_over.visible = true;

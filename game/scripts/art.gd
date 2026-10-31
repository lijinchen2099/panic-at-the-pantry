extends Node2D
## Vector illustration helpers. Artwork is resolution independent and original.

const INK = Color("29342f")
const CREAM = Color("fff1d0")
const GOLD = Color("efb94b")
const RED = Color("cf5946")
const GREEN = Color("315e50")
var display_font: SystemFont
var body_font: SystemFont
var _box_styles: Dictionary = {}

func _init() -> void:
	display_font = SystemFont.new()
	display_font.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	display_font.font_weight = 800
	body_font = SystemFont.new()
	body_font.font_names = PackedStringArray(["Avenir Next", "Arial"])
	body_font.font_weight = 600

func box(r: Rect2, color: Color, radius: float = 12.0, border: float = 0.0, edge: Color = INK) -> void:
	var key = [color, edge, int(radius), int(border)]
	var style: StyleBoxFlat = _box_styles.get(key)
	if style == null:
		style = StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(int(radius))
		style.set_border_width_all(int(border))
		style.border_color = edge
		if _box_styles.size() >= 512:
			_box_styles.clear()
		_box_styles[key] = style
	draw_style_box(style, r)

func oval(p: Vector2, size: Vector2, color: Color, border: float = 0.0) -> void:
	# Native ellipses avoid rebuilding and triangulating 49 vertices per oval.
	draw_ellipse(p, size.x, size.y, color)
	if border > 0:
		draw_ellipse(p, size.x, size.y, INK, false, border, true)

func line(points: Array, color: Color = INK, width: float = 5.0) -> void:
	draw_polyline(PackedVector2Array(points), color, width, true)
	for p in [points.front(), points.back()]:
		draw_circle(p, width * 0.5, color)

func label_at(words: String, p: Vector2, size: int = 24, color: Color = INK, display: bool = false) -> void:
	draw_string(display_font if display else body_font, p, words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func center(words: String, y: float, size: int = 24, color: Color = INK, display: bool = false, x: float = 800.0) -> void:
	var font = display_font if display else body_font
	var width = font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(x - width * 0.5, y), words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func star(p: Vector2, radius: float, color: Color = GOLD, rotation: float = 0) -> void:
	var points = PackedVector2Array()
	for i in range(10):
		var a = i * TAU / 10.0 + rotation - PI * 0.5
		points.append(p + Vector2(cos(a), sin(a)) * radius * (1.0 if i % 2 == 0 else 0.45))
	draw_colored_polygon(points, color)

func heart(p: Vector2, color: Color = RED, s: float = 1.0) -> void:
	draw_set_transform(p, 0, Vector2.ONE * s)
	draw_circle(Vector2(-8, -5), 10, color)
	draw_circle(Vector2(8, -5), 10, color)
	draw_colored_polygon(PackedVector2Array([Vector2(-17, 0), Vector2(17, 0), Vector2(0, 21)]), color)
	draw_set_transform(Vector2.ZERO)

func toast(p: Vector2, scale_value: float = 1.0, rotation: float = 0.0, burnt: bool = false) -> void:
	draw_set_transform(p, rotation, Vector2.ONE * scale_value)
	box(Rect2(-29, -27, 58, 61), Color("b66b39"), 9, 4)
	oval(Vector2(0, -26), Vector2(37, 18), Color("b66b39"), 4)
	box(Rect2(-22, -23, 44, 49), Color("764b32") if burnt else Color("edca82"), 7)
	oval(Vector2(0, -25), Vector2(28, 11), Color("764b32") if burnt else Color("edca82"))
	oval(Vector2(-9, -6), Vector2(3, 6), INK)
	oval(Vector2(9, -6), Vector2(3, 6), INK)
	line([Vector2(-8, 11), Vector2(0, 7), Vector2(8, 11)], INK, 3)
	draw_set_transform(Vector2.ZERO)

func egg(p: Vector2, t: float, running: bool, airborne: bool, facing: float = 1.0, invincible: bool = false, dash: bool = false) -> void:
	if invincible and int(t * 16) % 2 == 0:
		return
	var step = sin(t * 21) * 12 if running and not airborne else 0.0
	draw_set_transform(p, -0.13 * facing if dash else 0.0, Vector2(facing, 1))
	# Rubber-hose legs and oversized boots.
	line([Vector2(-15, -24), Vector2(-18 - step, -7), Vector2(-26 - step, -5)], INK, 8)
	line([Vector2(13, -24), Vector2(18 + step, -9), Vector2(28 + step, -5)], INK, 8)
	oval(Vector2(-29 - step, -4), Vector2(21, 10), INK)
	oval(Vector2(29 + step, -4), Vector2(21, 10), INK)
	line([Vector2(-39 - step, -8), Vector2(-21 - step, -8)], CREAM, 3)
	line([Vector2(20 + step, -8), Vector2(37 + step, -8)], CREAM, 3)
	# Asymmetric egg silhouette.
	var shell = PackedVector2Array()
	for i in range(49):
		var a = TAU * i / 48.0
		shell.append(Vector2(cos(a) * (32 + sin(a) * 5), -65 + sin(a) * 47))
	draw_colored_polygon(shell, CREAM)
	draw_polyline(shell, INK, 4, true)
	oval(Vector2(1, -58), Vector2(24, 25), GOLD, 3)
	oval(Vector2(-7, -65), Vector2(3, 6), INK)
	oval(Vector2(10, -65), Vector2(3, 6), INK)
	line([Vector2(-3, -49), Vector2(4, -45), Vector2(12, -50)], INK, 3)
	draw_circle(Vector2(-15, -54), 4, Color("e68a61"))
	# A finger-gun glove, always pointing in the direction of travel.
	line([Vector2(29, -62), Vector2(41, -49), Vector2(52, -58)], INK, 7)
	box(Rect2(44, -71, 23, 20), CREAM, 7, 3)
	box(Rect2(56, -77, 24, 9), CREAM, 4, 3)
	line([Vector2(-29, -63), Vector2(-43, -49), Vector2(-40, -37)], INK, 7)
	oval(Vector2(-40, -34), Vector2(9, 11), CREAM, 3)
	# Tiny chef's beret.
	oval(Vector2(-8, -111), Vector2(29, 10), RED, 3)
	line([Vector2(-10, -119), Vector2(-5, -126)], INK, 4)
	draw_set_transform(Vector2.ZERO)

func toaster(p: Vector2, t: float, phase: int = 1, windup: bool = false, hurt: bool = false, defeated: bool = false, s: float = 1.0) -> void:
	var bob = sin(t * 3.4) * 5
	draw_set_transform(p + Vector2(0, bob), sin(t * 2) * 0.015, Vector2.ONE * s)
	# Coiled arms and white gloves.
	line([Vector2(-123, -141), Vector2(-160, -150), Vector2(-180, -110), Vector2(-201, -130)], INK, 11)
	oval(Vector2(-204, -135), Vector2(24, 27), CREAM, 4)
	for i in range(3):
		line([Vector2(-220 + i * 10, -148), Vector2(-218 + i * 10, -137)], INK, 2)
	line([Vector2(128, -143), Vector2(164, -165), Vector2(177, -117), Vector2(196, -132)], INK, 11)
	oval(Vector2(199, -140), Vector2(25, 28), CREAM, 4)
	# Feet.
	line([Vector2(-80, -26), Vector2(-90, 4)], INK, 16)
	line([Vector2(80, -26), Vector2(90, 4)], INK, 16)
	oval(Vector2(-104, 11), Vector2(47, 18), INK)
	oval(Vector2(102, 11), Vector2(47, 18), INK)
	line([Vector2(-130, 5), Vector2(-91, 5)], CREAM, 4)
	line([Vector2(91, 5), Vector2(129, 5)], CREAM, 4)
	# Top and toasted passengers.
	box(Rect2(-133, -274, 266, 71), Color("748878"), 30, 5)
	box(Rect2(-103, -267, 206, 25), INK, 12)
	draw_set_transform(Vector2.ZERO)
	toast(p + Vector2(-52, -286 + bob) * s, 0.85 * s, -0.12 + sin(t * 2) * 0.05, phase == 2)
	toast(p + Vector2(54, -296 + bob) * s, 0.85 * s, 0.13 + sin(t * 2.2) * 0.05, phase == 2)
	draw_set_transform(p + Vector2(0, bob), sin(t * 2) * 0.015, Vector2.ONE * s)
	box(Rect2(-141, -247, 282, 215), Color("fff2d0") if hurt else (Color("d65b43") if phase == 1 else Color("ad4438")), 39, 6)
	box(Rect2(-122, -226, 244, 174), Color("e36d52") if phase == 1 else Color("c6513c"), 28)
	line([Vector2(-107, -203), Vector2(-107, -113)], Color("ed9b76"), 7)
	box(Rect2(-132, -69, 264, 34), Color("c4b78e"), 12, 4)
	for i in range(9):
		line([Vector2(-72 + i * 18, -56), Vector2(-65 + i * 18, -56)], INK, 3)
	# Eyes / murderous eyebrows / smug smile.
	for eye_x in [-49, 49]:
		oval(Vector2(eye_x, -172), Vector2(27, 35), CREAM, 4)
		if defeated:
			line([Vector2(eye_x - 10, -182), Vector2(eye_x + 10, -162)], INK, 4)
			line([Vector2(eye_x + 10, -182), Vector2(eye_x - 10, -162)], INK, 4)
		else:
			oval(Vector2(eye_x - 6, -169), Vector2(7, 15), INK)
	line([Vector2(-79, -211), Vector2(-26, -195)], INK, 9)
	line([Vector2(25, -195), Vector2(78, -212)], INK, 9)
	if windup:
		oval(Vector2(0, -108), Vector2(23, 25), INK)
	else:
		box(Rect2(-52, -123, 104, 36), INK, 17)
		box(Rect2(-44, -121, 88, 15), CREAM, 5)
		for x in [-22, 0, 22]:
			draw_line(Vector2(x, -121), Vector2(x, -106), INK, 2)
	oval(Vector2(0, -145), Vector2(16, 10), Color("b94737"), 3)
	# Lever and thermostat.
	box(Rect2(128, -194, 28, 95), Color("c4b78e"), 7, 4)
	box(Rect2(125, -183 if not windup else -129, 43, 22), INK, 7)
	draw_circle(Vector2(94, -85), 15, INK)
	draw_circle(Vector2(94, -85), 10, GOLD)
	draw_line(Vector2(94, -85), Vector2(98, -93), INK, 3)
	draw_set_transform(Vector2.ZERO)

func banana(p: Vector2, rotation: float = 0.0, s: float = 1.0) -> void:
	draw_set_transform(p, rotation, Vector2.ONE * s)
	var skin = PackedVector2Array([Vector2(-34, -20), Vector2(-24, -7), Vector2(-9, 3), Vector2(9, 5), Vector2(29, -3), Vector2(39, -20), Vector2(35, 4), Vector2(22, 22), Vector2(1, 29), Vector2(-20, 22), Vector2(-32, 4), Vector2(-34, -20)])
	draw_colored_polygon(skin, GOLD)
	draw_polyline(skin, INK, 4, true)
	line([Vector2(-22, 1), Vector2(-9, 13), Vector2(9, 17), Vector2(25, 8)], Color("fff1a0"), 4)
	line([Vector2(-34, -21), Vector2(-39, -28)], INK, 6)
	line([Vector2(37, -19), Vector2(43, -23)], INK, 5)
	draw_set_transform(Vector2.ZERO)

func blender(p: Vector2, t: float, phase: int = 1, windup: bool = false, hurt: bool = false, defeated: bool = false, s: float = 1.0) -> void:
	var bob = sin(t * (4.0 if phase == 1 else 14.0)) * (4 if phase == 1 else 7)
	var rotation = sin(t * 3.0) * 0.025
	draw_set_transform(p + Vector2(0, bob), rotation, Vector2.ONE * s)
	# A very aristocratic appliance, complete with crown, moustache, and spats.
	line([Vector2(-110, -186), Vector2(-156, -160), Vector2(-180, -193)], INK, 10)
	oval(Vector2(-184, -201), Vector2(25, 28), CREAM, 4)
	line([Vector2(-198, -213), Vector2(-196, -202)], INK, 3)
	line([Vector2(-187, -218), Vector2(-185, -205)], INK, 3)
	line([Vector2(115, -137), Vector2(174, -119), Vector2(194, -153)], INK, 10)
	oval(Vector2(196, -164), Vector2(25, 27), CREAM, 4)
	line([Vector2(202, -181), Vector2(203, -202)], CREAM, 13)
	line([Vector2(-67, -26), Vector2(-80, 5)], INK, 15)
	line([Vector2(65, -26), Vector2(78, 5)], INK, 15)
	oval(Vector2(-97, 12), Vector2(45, 18), INK)
	oval(Vector2(95, 12), Vector2(45, 18), INK)
	box(Rect2(-96, -3, 30, 19), CREAM, 4, 2)
	box(Rect2(65, -3, 30, 19), CREAM, 4, 2)
	# Pitcher handle sits behind the translucent jug.
	oval(Vector2(128, -240), Vector2(62, 91), INK)
	oval(Vector2(128, -240), Vector2(53, 81), Color("67a799"))
	oval(Vector2(132, -240), Vector2(33, 59), Color("f0ddbf"), 3)
	var glass = PackedVector2Array([Vector2(-135, -347), Vector2(115, -347), Vector2(99, -117), Vector2(-94, -117), Vector2(-115, -302), Vector2(-135, -318), Vector2(-135, -347)])
	draw_colored_polygon(glass, Color("e0ecda") if not hurt else CREAM)
	draw_polyline(glass, INK, 5, true)
	var liquid_color = Color("db8b83") if phase == 1 else Color("b96f9c")
	var liquid = PackedVector2Array([Vector2(-109, -269 + sin(t * 5) * 7), Vector2(-47, -278 + cos(t * 5) * 9), Vector2(25, -263 + sin(t * 5 + 1) * 10), Vector2(106, -277 + cos(t * 5) * 7), Vector2(95, -123), Vector2(-90, -123)])
	draw_colored_polygon(liquid, liquid_color)
	for i in range(4):
		var a = t * (2.0 if phase == 1 else 6.0) + i * TAU / 4
		oval(Vector2(cos(a) * 65, -170 + sin(a) * 17), Vector2(12, 7), [GOLD, CREAM, Color("ca4b55"), Color("f6c7ac")][i])
	for i in range(3):
		var y = -160 - i * 36
		line([Vector2(61, y), Vector2(82, y)], Color("829c88"), 2)
	line([Vector2(-94, -317), Vector2(-80, -158)], Color("fff8e2"), 7)
	# The blades spin much faster after the Duke hits TURBO.
	var blade_angle = t * (12 if phase == 1 else 30)
	for i in range(4):
		var a = blade_angle + i * PI * 0.5
		line([Vector2(0, -139), Vector2(cos(a) * 55, -139 + sin(a) * 11)], Color("e1dfb8"), 7)
	draw_circle(Vector2(0, -139), 8, INK)
	# Expressive eyes and a magnificently unnecessary moustache.
	for x in [-43, 38]:
		oval(Vector2(x, -242), Vector2(27, 33), CREAM, 4)
		if defeated:
			line([Vector2(x - 10, -251), Vector2(x + 10, -232)], INK, 4)
			line([Vector2(x + 10, -251), Vector2(x - 10, -232)], INK, 4)
		else:
			oval(Vector2(x - 7, -240), Vector2(7, 14), INK)
	line([Vector2(-73, -283), Vector2(-22, -272)], INK, 7)
	line([Vector2(15, -272), Vector2(65, -288)], INK, 7)
	oval(Vector2(-5, -210), Vector2(14, 10), Color("ba5b65"), 3)
	oval(Vector2(-28, -197), Vector2(30, 10), INK)
	oval(Vector2(25, -197), Vector2(30, 10), INK)
	line([Vector2(-52, -197), Vector2(-64, -208)], INK, 7)
	line([Vector2(49, -197), Vector2(61, -208)], INK, 7)
	if windup:
		oval(Vector2(-3, -173), Vector2(13, 16), INK)
	else:
		line([Vector2(-19, -179), Vector2(-2, -170), Vector2(17, -180)], INK, 4)
	# Lift-off lid and a fruit-sized crown.
	var lid_y = -363 - (absf(sin(t * 11)) * 10 if phase == 2 else 0.0)
	box(Rect2(-131, lid_y, 262, 30), Color("315f58"), 12, 5)
	box(Rect2(-39, lid_y - 18, 78, 22), Color("67a799"), 9, 4)
	var crown = PackedVector2Array([Vector2(-36, lid_y - 24), Vector2(-42, lid_y - 54), Vector2(-18, lid_y - 42), Vector2(0, lid_y - 68), Vector2(19, lid_y - 42), Vector2(42, lid_y - 54), Vector2(35, lid_y - 24), Vector2(-36, lid_y - 24)])
	draw_colored_polygon(crown, GOLD)
	draw_polyline(crown, INK, 3, true)
	draw_circle(Vector2(0, lid_y - 37), 5, RED)
	# Motor housing: the part Sunny's straight shots hit from the counter.
	box(Rect2(-125, -112, 250, 85), CREAM if hurt else (Color("4f9484") if phase == 1 else Color("805c83")), 28, 5)
	box(Rect2(-109, -95, 218, 48), Color("e7dfbc"), 16, 3)
	draw_circle(Vector2(-58, -71), 16, INK)
	draw_circle(Vector2(-58, -71), 11, GOLD)
	draw_line(Vector2(-58, -71), Vector2(-51, -80), INK, 3)
	for i in range(3):
		draw_circle(Vector2(-13 + i * 29, -71), 8, RED if i == 2 and phase == 2 else Color("6a9986"))
	box(Rect2(-62, -35, 124, 23), Color("315f58"), 8, 3)
	center("TURBO!" if phase == 2 else "PULSE", -19, 12, CREAM, false, 0)
	draw_set_transform(Vector2.ZERO)

func smoothie_stage() -> void:
	draw_rect(Rect2(0, 0, 1600, 900), Color("f0ddbf"))
	for x in range(0, 1600, 80):
		draw_line(Vector2(x, 142), Vector2(x, 679), Color("e4c6a7"), 2)
	# Arched juice-bar window and striped awning.
	box(Rect2(62, 191, 401, 348), Color("bd9870"), 90, 5)
	box(Rect2(77, 206, 371, 312), Color("b9d5b6"), 78, 4)
	draw_circle(Vector2(334, 279), 48, Color("f7cf80"))
	oval(Vector2(182, 356), Vector2(68, 19), CREAM)
	draw_line(Vector2(261, 210), Vector2(261, 516), Color("fff0cc"), 13)
	draw_line(Vector2(79, 376), Vector2(445, 376), Color("fff0cc"), 13)
	for i in range(10):
		box(Rect2(62 + i * 40, 179, 40, 58), Color("5e9d8b") if i % 2 == 0 else CREAM, 12)
	box(Rect2(47, 515, 430, 26), CREAM, 8, 4)
	# A pictorial menu keeps the background quiet during combat.
	box(Rect2(553, 215, 444, 348), Color("b18159"), 20, 5)
	box(Rect2(567, 229, 416, 320), Color("365e53"), 12, 3)
	center("THE DAILY BLEND", 278, 27, CREAM, true, 775)
	line([Vector2(600, 301), Vector2(949, 301)], Color("91b59a"), 2)
	banana(Vector2(775, 416), -0.2, 2.4)
	star(Vector2(615, 455), 12, GOLD)
	star(Vector2(939, 455), 12, GOLD)
	# Hanging plant and a scalloped display shelf.
	line([Vector2(1142, 145), Vector2(1106, 255), Vector2(1178, 255), Vector2(1142, 145)], INK, 3)
	box(Rect2(1108, 245, 70, 51), Color("ce8970"), 13, 4)
	for i in range(6):
		var p = Vector2(1142 + sin(i * 2.5) * 45, 291 + i * 20)
		line([Vector2(1142, 278), p], GREEN, 4)
		oval(p, Vector2(19, 10), Color("719f7e"), 2)
	box(Rect2(1268, 270, 296, 20), Color("b18159"), 5, 4)
	for i in range(3):
		var x = 1311 + i * 86
		box(Rect2(x, 207, 57, 62), [Color("b96f9c"), Color("efb94b"), Color("6e9e8e")][i], 12, 3)
		line([Vector2(x + 34, 222), Vector2(x + 43, 185)], INK, 4)
	# A fruit display and a seriously unimpressed orange spectator.
	box(Rect2(67, 610, 383, 68), Color("b18159"), 10, 4)
	for i in range(7):
		draw_circle(Vector2(105 + i * 46, 600 - (i % 2) * 17), 27, INK)
		draw_circle(Vector2(105 + i * 46, 600 - (i % 2) * 17), 23, Color("de9754"))
		oval(Vector2(109 + i * 46, 572 - (i % 2) * 17), Vector2(12, 5), GREEN)
	oval(Vector2(196, 584), Vector2(3, 5), INK)
	oval(Vector2(212, 584), Vector2(3, 5), INK)
	line([Vector2(198, 599), Vector2(211, 599)], INK, 3)
	# Pink terrazzo counter and a distinct terracotta checkerboard.
	box(Rect2(-10, 684, 1620, 60), Color("bb7e71"), 4, 5)
	box(Rect2(-10, 679, 1620, 24), Color("f2c8ad"), 3, 4)
	for i in range(48):
		var x = fmod(i * 137.0, 1600)
		star(Vector2(x, 715 + (i % 3) * 7), 3, Color("e6b69c"), i)
	draw_rect(Rect2(0, 744, 1600, 156), Color("bb8f81"))
	for row in range(3):
		for col in range(-1, 18):
			var x = col * 100 + row * 22
			if (row + col) % 2 == 0:
				draw_colored_polygon(PackedVector2Array([Vector2(x, 744 + row * 58), Vector2(x + 100, 744 + row * 58), Vector2(x + 122, 802 + row * 58), Vector2(x + 22, 802 + row * 58)]), Color("e3bea0"))
	box(Rect2(0, 868, 1600, 32), GREEN, 0)

func kettle(p: Vector2, t: float, phase: int = 1, windup: bool = false, hurt: bool = false, defeated: bool = false, s: float = 1.0) -> void:
	var bob = sin(t * (3.0 if phase == 1 else 8.0)) * 4
	draw_set_transform(p + Vector2(0, bob), sin(t * 2.5) * 0.02, Vector2.ONE * s)
	# A copper handle, a flowered bonnet, and an operatic temperament.
	draw_arc(Vector2(0, -210), 151, PI, TAU, 48, INK, 22, true)
	draw_arc(Vector2(0, -210), 151, PI, TAU, 48, Color("c99970"), 12, true)
	line([Vector2(-70, -30), Vector2(-81, 4)], INK, 14)
	line([Vector2(72, -30), Vector2(82, 4)], INK, 14)
	oval(Vector2(-100, 12), Vector2(45, 18), Color("71485c"), 4)
	oval(Vector2(99, 12), Vector2(45, 18), Color("71485c"), 4)
	for x in [-83, 82]:
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x - 16, -8), Vector2(x - 15, 10), Vector2(x, 2), Vector2(x + 16, 11), Vector2(x + 15, -8)]), CREAM)
	# Teapot spout: this is where the arcing tea leaves the kettle.
	var spout = PackedVector2Array([Vector2(-103, -132), Vector2(-159, -153), Vector2(-201, -198), Vector2(-222, -245), Vector2(-201, -253), Vector2(-177, -213), Vector2(-139, -209), Vector2(-104, -211), Vector2(-103, -132)])
	draw_colored_polygon(spout, Color("dba780"))
	draw_polyline(spout, INK, 5, true)
	oval(Vector2(-210, -249), Vector2(17, 7), INK)
	line([Vector2(-123, -127), Vector2(-160, -99), Vector2(-180, -110)], INK, 10)
	oval(Vector2(-184, -114), Vector2(24, 26), CREAM, 4)
	line([Vector2(124, -142), Vector2(167, -102), Vector2(187, -132)], INK, 10)
	# A teaspoon serves as her conductor's baton.
	line([Vector2(190, -107), Vector2(210, -225)], Color("a9b7a2"), 8)
	oval(Vector2(215, -244), Vector2(15, 27), Color("cbd4bd"), 4)
	oval(Vector2(186, -136), Vector2(23, 27), CREAM, 4)
	# Porcelain belly, copper trim, and a rosy boiling-point transformation.
	oval(Vector2(0, -155), Vector2(140, 128), CREAM if hurt else (Color("e5bd95") if phase == 1 else Color("d98178")), 6)
	oval(Vector2(-5, -162), Vector2(118, 108), Color("f1d7ad") if phase == 1 else Color("e89e8d"))
	line([Vector2(-100, -207), Vector2(-109, -173), Vector2(-107, -142)], CREAM, 7)
	box(Rect2(-112, -54, 224, 29), Color("a87559"), 12, 4)
	for i in range(9):
		var a = 0.3 + i * 0.32
		draw_circle(Vector2(-3 + cos(a) * 90, -115 + sin(a) * 49), 6, CREAM)
	for x in [-47, 44]:
		oval(Vector2(x, -182), Vector2(27, 33), CREAM, 4)
		if defeated:
			line([Vector2(x - 10, -192), Vector2(x + 10, -173)], INK, 4)
			line([Vector2(x + 10, -192), Vector2(x - 10, -173)], INK, 4)
		else:
			oval(Vector2(x - 7, -179), Vector2(7, 14), INK)
		line([Vector2(x - 25, -195), Vector2(x - 33, -205)], INK, 4)
		line([Vector2(x - 15, -210), Vector2(x - 20, -223)], INK, 4)
	line([Vector2(-76, -226), Vector2(-24, -216)], INK, 7)
	line([Vector2(20, -216), Vector2(71, -230)], INK, 7)
	oval(Vector2(-79, -146), Vector2(17, 10), Color("d7837d"))
	oval(Vector2(77, -146), Vector2(17, 10), Color("d7837d"))
	oval(Vector2(-3, -151), Vector2(13, 9), Color("bb7469"), 3)
	if windup:
		oval(Vector2(0, -113), Vector2(21, 27), INK)
		oval(Vector2(1, -98), Vector2(12, 7), Color("e5a0a2"))
	else:
		box(Rect2(-32, -126, 64, 29), Color("8c465d"), 14, 3)
		line([Vector2(-19, -122), Vector2(18, -122)], CREAM, 5)
	# The bonnet starts rattling once Madame reaches boiling point.
	var lid_y = -292 - (absf(sin(t * 12)) * 15 if phase == 2 else 0.0)
	box(Rect2(-123, lid_y, 246, 30), Color("729383"), 14, 5)
	oval(Vector2(0, lid_y - 9), Vector2(83, 28), Color("91ad8f"), 4)
	box(Rect2(-15, lid_y - 46, 30, 27), Color("c99970"), 10, 4)
	for i in range(6):
		var a = i * TAU / 6
		draw_circle(Vector2(-35, lid_y - 30) + Vector2(cos(a), sin(a)) * 15, 12, CREAM)
	draw_circle(Vector2(-35, lid_y - 30), 11, GOLD)
	# Tiny pressure gauge and floral brooch.
	draw_circle(Vector2(86, -88), 17, INK)
	draw_circle(Vector2(86, -88), 13, CREAM)
	draw_line(Vector2(86, -88), Vector2(96 if phase == 2 else 78, -96), RED, 4)
	star(Vector2(0, -69), 17, GREEN, t * 0.1)
	draw_circle(Vector2(0, -69), 8, GOLD)
	draw_set_transform(Vector2.ZERO)

func biscuit(p: Vector2, rotation: float = 0.0, pink: bool = false) -> void:
	draw_set_transform(p, rotation)
	var edge = PackedVector2Array()
	for i in range(49):
		var a = i * TAU / 48.0
		var radius = 26 + (2 if i % 4 < 2 else -1)
		edge.append(Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(edge, Color("f1b5c1") if pink else Color("c28a53"))
	draw_polyline(edge, INK, 3, true)
	draw_circle(Vector2.ZERO, 19, Color("fad6c1") if pink else Color("e9c58b"))
	for offset in [Vector2(-10, -7), Vector2(9, -11), Vector2(5, 7), Vector2(-11, 10)]:
		draw_circle(offset, 4, Color("815640"))
	draw_set_transform(Vector2.ZERO)

func tea_stage() -> void:
	draw_rect(Rect2(0, 0, 1600, 900), Color("e0d9cd"))
	# Floral wallpaper and a proper little tea-room sign.
	for x in range(25, 1600, 100):
		for y in range(168, 680, 95):
			for i in range(4):
				var a = i * TAU / 4
				oval(Vector2(x, y) + Vector2(cos(a), sin(a)) * 8, Vector2(7, 4), Color("c1c6b2"))
			draw_circle(Vector2(x, y), 3, Color("d2b98c"))
	box(Rect2(580, 168, 438, 55), Color("786273"), 20, 4)
	center("THE STEEP END", 205, 27, CREAM, true)
	# Tall arched window, with lilac curtains and a bright morning outside.
	box(Rect2(586, 244, 426, 340), Color("b59b7a"), 84, 5)
	box(Rect2(601, 259, 396, 310), Color("a7c6bd"), 75, 4)
	draw_circle(Vector2(894, 333), 43, Color("f4d78e"))
	oval(Vector2(702, 372), Vector2(63, 16), CREAM)
	oval(Vector2(920, 462), Vector2(62, 16), Color("dfe6cb"))
	draw_line(Vector2(800, 260), Vector2(800, 570), CREAM, 13)
	draw_line(Vector2(602, 414), Vector2(997, 414), CREAM, 13)
	for side in [0, 1]:
		for i in range(4):
			box(Rect2(584 + side * 335 + i * 25, 241, 27, 151 - i * 22 if side == 0 else 85 + i * 22), Color("a08499") if i % 2 == 0 else Color("bea1ae"), 10)
	box(Rect2(563, 568, 472, 25), CREAM, 8, 4)
	# Tea tins and an extremely serious house motto.
	box(Rect2(55, 349, 398, 19), Color("a67e5e"), 5, 4)
	for i in range(3):
		var x = 92 + i * 115
		box(Rect2(x, 243, 83, 105), [Color("849d88"), Color("b48696"), Color("d2b377")][i], 15, 3)
		box(Rect2(x - 3, 237, 89, 17), CREAM, 5, 3)
		box(Rect2(x + 10, 277, 63, 42), CREAM, 5)
		star(Vector2(x + 41, 297), 12, GREEN, i)
	box(Rect2(93, 402, 320, 150), Color("786273"), 20, 4)
	center("TEA TIME", 443, 27, CREAM, true, 253)
	oval(Vector2(288, 491), Vector2(15, 16), CREAM, 3)
	oval(Vector2(288, 491), Vector2(8, 9), Color("786273"), 2)
	box(Rect2(221, 473, 63, 44), CREAM, 14, 3)
	oval(Vector2(252, 474), Vector2(30, 6), Color("a27b52"), 2)
	oval(Vector2(252, 523), Vector2(44, 5), CREAM, 2)
	# Porcelain cups waiting for an equally unreasonable tea party.
	box(Rect2(63, 643, 385, 35), Color("a67e5e"), 7, 4)
	for i in range(4):
		var x = 91 + i * 87
		oval(Vector2(x + 58, 609), Vector2(18, 19), CREAM, 3)
		oval(Vector2(x + 58, 609), Vector2(10, 11), Color("e0d9cd"), 2)
		box(Rect2(x, 580, 57, 60), CREAM, 18, 3)
		oval(Vector2(x + 28, 581), Vector2(28, 8), Color("a27b52"), 3)
		star(Vector2(x + 28, 614), 11, Color("a08499"), i)
		oval(Vector2(x + 27, 643), Vector2(38, 6), CREAM, 2)
	# A ticking tea timer and hanging saucers frame the boss.
	draw_circle(Vector2(1220, 248), 56, INK)
	draw_circle(Vector2(1220, 248), 49, CREAM)
	line([Vector2(1220, 218), Vector2(1220, 248), Vector2(1241, 263)], INK, 4)
	for i in range(3):
		var x = 1370 + i * 77
		line([Vector2(x, 174), Vector2(x, 225)], Color("a67e5e"), 3)
		draw_circle(Vector2(x, 258), 32, INK)
		draw_circle(Vector2(x, 258), 28, CREAM)
		draw_circle(Vector2(x, 258), 20, Color("b6c7b2"))
	box(Rect2(-10, 684, 1620, 60), Color("b09173"), 4, 5)
	box(Rect2(-10, 679, 1620, 24), Color("ead8b5"), 3, 4)
	for x in range(0, 1600, 55):
		draw_line(Vector2(x, 718), Vector2(x + 29, 718), Color("8d705a"), 2)
	draw_rect(Rect2(0, 744, 1600, 156), Color("8a8297"))
	for row in range(3):
		for col in range(-1, 18):
			var x = col * 100 + row * 22
			if (row + col) % 2 == 0:
				draw_colored_polygon(PackedVector2Array([Vector2(x, 744 + row * 58), Vector2(x + 100, 744 + row * 58), Vector2(x + 122, 802 + row * 58), Vector2(x + 22, 802 + row * 58)]), Color("c4bcc6"))
	box(Rect2(0, 868, 1600, 32), GREEN, 0)

func skillet(p: Vector2, t: float, phase: int = 1, windup: bool = false, hurt: bool = false, defeated: bool = false, s: float = 1.0) -> void:
	var bob = sin(t * (4.0 if phase == 1 else 9.0)) * 5
	draw_set_transform(p + Vector2(0, bob), sin(t * 2.6) * 0.025, Vector2.ONE * s)
	# The pan handle doubles as a tall chef's hat, with a copper hanging eyelet.
	box(Rect2(-27, -392, 54, 135), Color("986447"), 18, 6)
	box(Rect2(-13, -372, 26, 57), INK, 12)
	for x in [-46, 0, 46]:
		draw_circle(Vector2(x, -391 - (15 if x == 0 else 0)), 34, INK)
		draw_circle(Vector2(x, -394 - (15 if x == 0 else 0)), 29, CREAM)
	box(Rect2(-73, -391, 146, 42), CREAM, 8, 4)
	line([Vector2(-47, -375), Vector2(47, -375)], Color("d1c5a5"), 3)
	# Rubber-hose legs and flamboyantly oversized shoes.
	line([Vector2(-69, -45), Vector2(-82, -6)], INK, 15)
	line([Vector2(69, -45), Vector2(82, -6)], INK, 15)
	oval(Vector2(-106, 14), Vector2(48, 18), Color("925f44"), 4)
	oval(Vector2(102, 14), Vector2(48, 18), Color("925f44"), 4)
	line([Vector2(-126, 9), Vector2(-98, 7)], CREAM, 4)
	line([Vector2(82, 9), Vector2(110, 7)], CREAM, 4)
	var arm_lift = -20.0 if windup else sin(t * 4) * 10
	line([Vector2(-123, -181), Vector2(-171, -151 + arm_lift), Vector2(-196, -184 + arm_lift)], INK, 12)
	oval(Vector2(-199, -190 + arm_lift), Vector2(27, 26), CREAM, 4)
	line([Vector2(127, -182), Vector2(173, -140), Vector2(198, -169)], INK, 12)
	# A comically large spatula is his chef's scepter.
	line([Vector2(203, -156), Vector2(220, -260)], Color("c2c9b5"), 11)
	box(Rect2(198, -318, 49, 72), Color("c2c9b5"), 12, 4)
	for x in [210, 222, 234]:
		line([Vector2(x, -302), Vector2(x, -267)], INK, 4)
	oval(Vector2(200, -169), Vector2(23, 25), CREAM, 4)
	# Cast iron, copper rim, and a red-hot second act.
	oval(Vector2(0, -168), Vector2(149, 145), Color("b57a4d"), 7)
	oval(Vector2(0, -168), Vector2(135, 131), CREAM if hurt else (Color("526b61") if phase == 1 else Color("a7503e")), 5)
	oval(Vector2(0, -169), Vector2(118, 113), Color("658174") if phase == 1 else Color("c86a42"))
	draw_arc(Vector2(0, -168), 124, PI * 0.91, PI * 1.40, 24, Color("b8c3a4"), 5, true)
	for x in [-47, 45]:
		oval(Vector2(x, -197), Vector2(27, 32), CREAM, 4)
		if defeated:
			line([Vector2(x - 10, -208), Vector2(x + 10, -186)], INK, 4)
			line([Vector2(x + 10, -208), Vector2(x - 10, -186)], INK, 4)
		else:
			oval(Vector2(x - 7, -193), Vector2(8, 15), INK)
	line([Vector2(-79, -238), Vector2(-24, -222)], INK, 9)
	line([Vector2(21, -222), Vector2(77, -242)], INK, 9)
	oval(Vector2(-4, -163), Vector2(18, 13), GOLD, 3)
	# The moustache curls into two little skillet handles.
	for side in [-1, 1]:
		oval(Vector2(side * 25, -146), Vector2(29, 12), INK)
		draw_arc(Vector2(side * 54, -156), 15, 0 if side == 1 else PI, PI if side == 1 else TAU, 16, INK, 7, true)
	box(Rect2(-32, -123, 64, 35 if windup else 24), INK, 12)
	line([Vector2(-20, -118), Vector2(20, -118)], CREAM, 7)
	box(Rect2(-34, -76, 68, 24), RED, 9, 3)
	for x in [-14, 14]:
		draw_circle(Vector2(x, -64), 4, GOLD)
	if phase == 2:
		for i in range(5):
			var x = -80 + i * 40
			var height = 21 + absf(sin(t * 9 + i)) * 23
			var flame = PackedVector2Array([Vector2(x - 16, -38), Vector2(x - 9, -53), Vector2(x, -38 - height), Vector2(x + 9, -52), Vector2(x + 16, -38)])
			draw_colored_polygon(flame, GOLD)
	draw_set_transform(Vector2.ZERO)

func pancake(p: Vector2, rotation: float = 0.0, pink: bool = false) -> void:
	draw_set_transform(p, sin(rotation) * 0.2)
	oval(Vector2(0, 8), Vector2(30, 13), Color("ba7543"), 3)
	oval(Vector2(0, -2), Vector2(30, 14), Color("f4b4c5") if pink else Color("e7b66b"), 3)
	oval(Vector2(-2, -4), Vector2(23, 8), Color("f9d2db") if pink else Color("f1cf8d"))
	box(Rect2(-10, -14, 18, 11), CREAM, 3, 2)
	line([Vector2(14, -5), Vector2(18, 4), Vector2(18, 10)], Color("a76b42"), 4)
	draw_set_transform(Vector2.ZERO)

func shield_marker(p: Vector2) -> void:
	var outline = PackedVector2Array([p + Vector2(-10, -10), p + Vector2(10, -10), p + Vector2(9, 2), p + Vector2(0, 11), p + Vector2(-9, 2), p + Vector2(-10, -10)])
	draw_colored_polygon(outline, Color("a1e7e8"))
	draw_polyline(outline, INK, 3, true)
	line([p + Vector2(0, -5), p + Vector2(0, 4)], INK, 3)

func diner_stage() -> void:
	draw_rect(Rect2(0, 0, 1600, 900), Color("e7c9a3"))
	# A warm late-night diner, copper extraction hood, and theatrical flames.
	for x in range(0, 1600, 100):
		for y in range(142, 684, 72):
			box(Rect2(x + (50 if y % 144 < 72 else 0), y, 97, 68), Color("d9af86") if x % 200 == 0 else Color("ead2ae"), 4)
	box(Rect2(515, 163, 555, 91), Color("486b64"), 18, 5)
	center("THE SIZZLE REEL", 205, 30, CREAM, true)
	var hood = PackedVector2Array([Vector2(670, 286), Vector2(925, 286), Vector2(1010, 398), Vector2(582, 398), Vector2(670, 286)])
	draw_colored_polygon(hood, Color("b77d57"))
	draw_polyline(hood, INK, 5, true)
	box(Rect2(582, 394, 428, 34), Color("8d624d"), 5, 4)
	for x in range(616, 990, 34):
		line([Vector2(x, 405), Vector2(x + 15, 405)], INK, 4)
	box(Rect2(600, 510, 391, 164), Color("486b64"), 18, 4)
	box(Rect2(585, 491, 420, 28), INK, 8, 4)
	for x in [659, 787, 915]:
		oval(Vector2(x, 487), Vector2(40, 13), Color("9b5840"), 3)
		draw_arc(Vector2(x, 487), 29, PI, TAU, 20, GOLD, 6, true)
		draw_circle(Vector2(x, 544), 11, GOLD)
	box(Rect2(649, 574, 294, 75), Color("294c48"), 10, 4)
	line([Vector2(685, 588), Vector2(908, 588)], CREAM, 6)
	# Condiments, stacked plates, and an unhelpful specials board.
	box(Rect2(64, 282, 362, 26), Color("93694f"), 5, 4)
	for i in range(3):
		var x = 113 + i * 107
		box(Rect2(x, 201, 53, 80), [RED, GOLD, GREEN][i], 12, 3)
		box(Rect2(x + 12, 182, 29, 29), CREAM, 5, 3)
		star(Vector2(x + 27, 245), 13, CREAM)
	box(Rect2(87, 353, 332, 191), Color("35574f"), 16, 5)
	center("PANIC-CAKES", 401, 27, GOLD, true, 253)
	for i in range(3):
		oval(Vector2(253, 497 - i * 16), Vector2(72, 17), Color("e7b66b"), 3)
	box(Rect2(238, 447, 30, 17), CREAM, 4, 2)
	for i in range(5):
		oval(Vector2(258, 652 - i * 9), Vector2(100, 13), CREAM, 3)
	for i in range(3):
		var x = 1163 + i * 144
		line([Vector2(x, 155), Vector2(x, 181)], INK, 4)
		box(Rect2(x - 22, 181, 44, 25), Color("a56b46"), 10, 3)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 22, 204), Vector2(x + 22, 204), Vector2(x + 51, 241), Vector2(x - 51, 241)]), Color("b77d57"))
		line([Vector2(x - 51, 241), Vector2(x + 51, 241)], GOLD, 5)
	box(Rect2(-10, 684, 1620, 60), Color("986c50"), 4, 5)
	box(Rect2(-10, 679, 1620, 24), Color("e9d5a9"), 3, 4)
	draw_rect(Rect2(0, 744, 1600, 156), Color("ad6b58"))
	for row in range(3):
		for col in range(-1, 18):
			var x = col * 100 + row * 22
			if (row + col) % 2 == 0:
				draw_colored_polygon(PackedVector2Array([Vector2(x, 744 + row * 58), Vector2(x + 100, 744 + row * 58), Vector2(x + 122, 802 + row * 58), Vector2(x + 22, 802 + row * 58)]), Color("e4c4a0"))
	box(Rect2(0, 868, 1600, 32), GREEN, 0)

func chef(p: Vector2, t: float, phase: int = 1, windup: bool = false, hurt: bool = false, defeated: bool = false, s: float = 1.0) -> void:
	var bob = sin(t * (3.8 if phase == 1 else 8.5)) * 4
	draw_set_transform(p + Vector2(0, bob), sin(t * 2) * 0.018, Vector2.ONE * s)
	# A human head chef with enormous shoes, a tiny moustache, and a tall toque.
	for side in [-1, 1]:
		line([Vector2(side * 56, -53), Vector2(side * 71, -5)], INK, 20)
		oval(Vector2(side * 90, 12), Vector2(47, 19), INK, 4)
		line([Vector2(side * 80, 6), Vector2(side * 108, 6)], CREAM, 4)
	line([Vector2(-101, -192), Vector2(-153, -220), Vector2(-177, -274 if windup else -250)], INK, 25)
	line([Vector2(-101, -192), Vector2(-153, -220), Vector2(-177, -274 if windup else -250)], CREAM, 17)
	oval(Vector2(-179, -274 if windup else -250), Vector2(28, 25), Color("eac09d"), 4)
	line([Vector2(105, -190), Vector2(161, -132), Vector2(190, -178)], INK, 25)
	line([Vector2(105, -190), Vector2(161, -132), Vector2(190, -178)], CREAM, 17)
	line([Vector2(194, -155), Vector2(218, -252)], Color("b9c6b7"), 9)
	for width in [12, 23, 33]:
		draw_arc(Vector2(228, -276), width, PI * 0.55, PI * 2.55, 32, Color("c7d7c1"), 5, true)
	oval(Vector2(192, -176), Vector2(25, 27), Color("eac09d"), 4)
	# Double-breasted jacket, checked trousers, and a dramatic red neckerchief.
	oval(Vector2(0, -135), Vector2(125, 116), CREAM if not hurt else Color("ffffff"), 6)
	box(Rect2(-93, -61, 186, 37), Color("42655e"), 9, 4)
	for x in range(-79, 90, 28):
		line([Vector2(x, -57), Vector2(x, -31)], CREAM, 3)
	line([Vector2(-88, -45), Vector2(88, -45)], CREAM, 3)
	line([Vector2(12, -213), Vector2(12, -73)], Color("ccbfa2"), 3)
	for x in [-14, 38]:
		for y in [-170, -125, -80]:
			draw_circle(Vector2(x, y), 6, INK)
	box(Rect2(-86, -151, 43, 46), Color("e6d9ba"), 5, 3)
	line([Vector2(-80, -140), Vector2(-49, -140)], INK, 3)
	oval(Vector2(-77, -276), Vector2(22, 30), Color("eac09d"), 4)
	oval(Vector2(77, -276), Vector2(22, 30), Color("eac09d"), 4)
	oval(Vector2(0, -277), Vector2(82, 83), Color("eac09d") if phase == 1 else Color("df947d"), 5)
	for x in [-30, 31]:
		oval(Vector2(x, -291), Vector2(21, 27), CREAM, 3)
		if defeated:
			line([Vector2(x - 9, -302), Vector2(x + 9, -281)], INK, 4)
			line([Vector2(x + 9, -302), Vector2(x - 9, -281)], INK, 4)
		else:
			oval(Vector2(x - 5, -287), Vector2(6, 12), INK)
	line([Vector2(-54, -327), Vector2(-10, -314)], INK, 8)
	line([Vector2(11, -314), Vector2(55, -330)], INK, 8)
	oval(Vector2(0, -269), Vector2(22, 17), Color("dc9a7d"), 3)
	for side in [-1, 1]:
		oval(Vector2(side * 21, -251), Vector2(24, 10), INK)
		draw_arc(Vector2(side * 45, -261), 13, 0 if side == 1 else PI, PI if side == 1 else TAU, 15, INK, 5, true)
	box(Rect2(-24, -234, 48, 24 if windup else 16), INK, 9)
	line([Vector2(-14, -230), Vector2(14, -230)], CREAM, 4)
	var scarf = PackedVector2Array([Vector2(-41, -207), Vector2(0, -185), Vector2(42, -207), Vector2(24, -170), Vector2(6, -183), Vector2(-8, -158), Vector2(-26, -175), Vector2(-41, -207)])
	draw_colored_polygon(scarf, RED)
	draw_polyline(scarf, INK, 3, true)
	# The hat bounces in the dinner rush; little peppercorns decorate its band.
	var hat_y = -365 - (absf(sin(t * 11)) * 10 if phase == 2 else 0.0)
	for x in [-47, 0, 47]:
		draw_circle(Vector2(x, hat_y - 36 - (17 if x == 0 else 0)), 35, INK)
		draw_circle(Vector2(x, hat_y - 39 - (17 if x == 0 else 0)), 30, CREAM)
	box(Rect2(-73, hat_y - 38, 146, 50), CREAM, 9, 4)
	line([Vector2(-62, hat_y), Vector2(62, hat_y)], Color("ba9b65"), 4)
	for x in [-29, 0, 29]:
		draw_circle(Vector2(x, hat_y - 17), 5, GREEN)
	if phase == 2:
		for side in [-1, 1]:
			line([Vector2(side * 100, -303), Vector2(side * 125, -320), Vector2(side * 117, -343)], CREAM, 5)
	draw_set_transform(Vector2.ZERO)

func ravioli(p: Vector2, rotation: float = 0.0, pink: bool = false) -> void:
	draw_set_transform(p, rotation)
	box(Rect2(-29, -24, 58, 48), Color("f1b3c5") if pink else Color("e9ba72"), 10, 3)
	box(Rect2(-19, -15, 38, 30), Color("f9d3df") if pink else Color("f4d393"), 12, 2)
	for x in [-20, -7, 7, 20]:
		for side in [-1, 1]:
			draw_line(Vector2(x, side * 17), Vector2(x, side * 22), Color("b88a55"), 2)
	draw_set_transform(Vector2.ZERO)

func flying_whisk(p: Vector2, rotation: float = 0.0) -> void:
	draw_set_transform(p, rotation)
	line([Vector2(-38, 0), Vector2(0, 0)], INK, 11)
	line([Vector2(-38, 0), Vector2(0, 0)], Color("ac7957"), 6)
	for height in [9, 17, 25]:
		oval(Vector2(18, 0), Vector2(27, height), Color(0, 0, 0, 0), 3)
	draw_set_transform(Vector2.ZERO)

func chef_stage() -> void:
	draw_rect(Rect2(0, 0, 1600, 900), Color("b9c9bd"))
	# A grand restaurant pass with brass trim, plates, and a very demanding menu.
	for x in range(0, 1600, 100):
		for y in range(144, 681, 78):
			box(Rect2(x + 3, y + 3, 94, 72), Color("cdd6c4") if (x / 100 + y / 78) % 2 == 0 else Color("bdccbd"), 5)
	box(Rect2(523, 163, 543, 74), Color("355b54"), 17, 5, Color("a9864d"))
	center("THE HEAD TABLE", 208, 30, CREAM, true)
	box(Rect2(550, 269, 491, 360), Color("aa8858"), 90, 5)
	box(Rect2(565, 284, 461, 330), Color("47645b"), 79, 3)
	box(Rect2(589, 307, 413, 272), Color("779d8c"), 65, 3)
	for i in range(4):
		var x = 636 + i * 96
		line([Vector2(x, 315), Vector2(x, 373)], Color("b69559"), 4)
		oval(Vector2(x, 402), Vector2(35, 27), Color("b88156"), 4)
		oval(Vector2(x, 401), Vector2(26, 19), Color("d2a271"), 3)
	box(Rect2(563, 570, 466, 44), Color("aa8858"), 7, 4)
	for i in range(4):
		var x = 627 + i * 105
		oval(Vector2(x, 553), Vector2(43, 11), CREAM, 3)
		oval(Vector2(x, 540), Vector2(34, 24), Color("b6c5b3"), 3)
		draw_circle(Vector2(x, 516), 6, GOLD)
	box(Rect2(65, 239, 372, 310), Color("2d514a"), 16, 5, Color("a9864d"))
	center("CHEF'S SPECIAL", 285, 29, CREAM, true, 251)
	line([Vector2(96, 308), Vector2(405, 308)], GOLD, 3)
	egg(Vector2(251, 500), 0, false, false)
	box(Rect2(68, 630, 373, 26), Color("aa8858"), 5, 4)
	for i in range(5):
		var x = 97 + i * 65
		box(Rect2(x, 572, 43, 57), [RED, GOLD, GREEN, Color("936b82"), Color("c18d58")][i], 9, 3)
		box(Rect2(x - 3, 562, 49, 16), CREAM, 5, 3)
		star(Vector2(x + 22, 602), 10, CREAM, i)
	line([Vector2(1134, 157), Vector2(1543, 157)], Color("aa8858"), 5)
	for i in range(4):
		var x = 1160 + i * 112
		line([Vector2(x, 158), Vector2(x, 200)], INK, 4)
		draw_circle(Vector2(x, 229), 29, INK)
		draw_circle(Vector2(x, 229), 25, CREAM)
		star(Vector2(x, 229), 14, GOLD, i)
	box(Rect2(-10, 684, 1620, 60), Color("819e8f"), 4, 5)
	box(Rect2(-10, 679, 1620, 24), Color("e1cf9f"), 3, 4)
	draw_rect(Rect2(0, 744, 1600, 156), Color("45685e"))
	for row in range(3):
		for col in range(-1, 18):
			var x = col * 100 + row * 22
			if (row + col) % 2 == 0:
				draw_colored_polygon(PackedVector2Array([Vector2(x, 744 + row * 58), Vector2(x + 100, 744 + row * 58), Vector2(x + 122, 802 + row * 58), Vector2(x + 22, 802 + row * 58)]), Color("aebfaa"))
	box(Rect2(0, 868, 1600, 32), GREEN, 0)

func stage(course: int = 1) -> void:
	if course == 5:
		chef_stage()
		return
	if course == 4:
		diner_stage()
		return
	if course == 3:
		tea_stage()
		return
	if course == 2:
		smoothie_stage()
		return
	# Warm paper, sage kitchen tiles, and a huge checkerboard countertop.
	draw_rect(Rect2(0, 0, 1600, 900), Color("f1e8cd"))
	for x in range(0, 1600, 100):
		for y in range(135, 647, 100):
			box(Rect2(x + 3, y + 3, 94, 94), Color("d8debc") if (x / 100 + y / 100) % 2 == 0 else Color("e5e5c9"), 4)
	# Window with a quiet morning outside.
	box(Rect2(574, 190, 394, 328), Color("c5b58b"), 52, 5)
	box(Rect2(589, 204, 364, 295), Color("a7c6b1"), 40, 4)
	draw_circle(Vector2(843, 279), 48, Color("f3d486"))
	oval(Vector2(666, 323), Vector2(72, 20), Color("e9ebd4"))
	oval(Vector2(891, 403), Vector2(61, 17), Color("d8e5cc"))
	draw_line(Vector2(770, 206), Vector2(770, 500), Color("eee2be"), 15)
	draw_line(Vector2(590, 357), Vector2(952, 357), Color("eee2be"), 15)
	box(Rect2(548, 500, 446, 27), CREAM, 8, 4)
	# Cafe curtain.
	for x in range(580, 961, 38):
		box(Rect2(x, 184, 36, 56 if x < 696 or x > 844 else 35), Color("cc6550") if x % 76 < 38 else Color("f1e8cd"), 9)
	line([Vector2(562, 183), Vector2(977, 183)], INK, 6)
	# Left shelf.
	box(Rect2(64, 352, 379, 21), Color("ac8060"), 5, 4)
	for i in range(3):
		var x = 107 + i * 99
		box(Rect2(x, 265 - i * 9, 65, 86 + i * 9), [Color("e0bc71"), Color("cf6650"), Color("799b80")][i], 11, 3)
		box(Rect2(x - 3, 257 - i * 9, 71, 16), CREAM, 4, 3)
		box(Rect2(x + 9, 293, 47, 38), CREAM, 3)
		star(Vector2(x + 32, 311), 9, GREEN, i)
	# Clock and hanging utensils.
	draw_circle(Vector2(1195, 263), 65, INK)
	draw_circle(Vector2(1195, 263), 57, CREAM)
	for i in range(12):
		var a = i * TAU / 12.0
		draw_line(Vector2(1195, 263) + Vector2(sin(a), -cos(a)) * 46, Vector2(1195, 263) + Vector2(sin(a), -cos(a)) * 51, INK, 3)
	line([Vector2(1195, 230), Vector2(1195, 263), Vector2(1220, 278)], INK, 5)
	line([Vector2(1354, 225), Vector2(1532, 225)], INK, 5)
	for i in range(3):
		var x = 1380 + i * 60
		line([Vector2(x, 227), Vector2(x, 326)], Color("59796b"), 7)
		oval(Vector2(x, 344), Vector2(16, 26), Color("59796b"), 3)
	# Stove, tea towel, and cabinet at the rear of the counter.
	box(Rect2(52, 511, 382, 167), Color("7f9a81"), 16, 4)
	box(Rect2(69, 523, 349, 39), CREAM, 8, 3)
	for x in [103, 185, 267, 349]:
		draw_circle(Vector2(x, 543), 10, INK)
	box(Rect2(88, 580, 190, 78), Color("405d50"), 10, 4)
	line([Vector2(112, 592), Vector2(250, 592)], CREAM, 5)
	box(Rect2(318, 568, 78, 103), CREAM, 4, 3)
	for x in [329, 349, 369]:
		draw_line(Vector2(x, 569), Vector2(x, 667), RED, 4)
	# Counter edge establishes the collision plane.
	box(Rect2(-10, 684, 1620, 60), Color("b87b55"), 4, 5)
	box(Rect2(-10, 679, 1620, 24), Color("ead3a1"), 3, 4)
	for x in range(0, 1600, 46):
		draw_line(Vector2(x, 714), Vector2(x + 22, 714), Color("9f694c"), 2)
	draw_rect(Rect2(0, 744, 1600, 156), Color("668774"))
	for row in range(3):
		for col in range(-1, 18):
			var x = col * 100 + row * 22
			if (row + col) % 2 == 0:
				draw_colored_polygon(PackedVector2Array([Vector2(x, 744 + row * 58), Vector2(x + 100, 744 + row * 58), Vector2(x + 122, 802 + row * 58), Vector2(x + 22, 802 + row * 58)]), Color("aec0a0"))
	# Foreground framing.
	box(Rect2(0, 868, 1600, 32), GREEN, 0)

shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform ivec2 target_resolution = ivec2(320, 180);
uniform float target_alpha = -1.0;

void fragment() {
	float block_size = 1.0 / (float(target_resolution.x) * SCREEN_PIXEL_SIZE.x);
	vec4 c = textureLod(screen_texture, round(SCREEN_UV / SCREEN_PIXEL_SIZE / block_size) * SCREEN_PIXEL_SIZE * block_size, 0.0);

	if (target_alpha >= .0)
	{
		if (c.a != .0)
			c.a = target_alpha;
	}
	else if (c.a > 0.0001)
		c.rgb /= c.a;

	COLOR = c;
}
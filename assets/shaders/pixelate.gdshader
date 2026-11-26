shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture_filtered : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform ivec2 target_resolution = ivec2(320, 180);
uniform float max_alpha = .5;

void fragment() {
	vec2 block_size = vec2(1.0, 1.0) / vec2(target_resolution) / SCREEN_PIXEL_SIZE;
	vec2 pos = round(SCREEN_UV / SCREEN_PIXEL_SIZE / block_size) * SCREEN_PIXEL_SIZE * block_size;
	vec2 pos_step = block_size * SCREEN_PIXEL_SIZE;

	vec4 c = textureLod(
		screen_texture,
		pos,
		0.0
	);

	//c.rgb /= c.a;
	float reference_alpha = textureLod(screen_texture_filtered, pos, 3.0).a;
	c.a = max_alpha * smoothstep(.0, .65, reference_alpha) * step(.01, c.a);
	c.a = round(c.a * 16.0) / 16.0;

	COLOR = c;
}
shader_type canvas_item;
render_mode unshaded;

uniform vec3 flame_color: source_color = vec3(1.0, 0.3, 0.0);
uniform ivec2 target_resolution = ivec2(640, 360);

#include "random.gdshaderinc"

void fragment() {
	float block_size = 1.0 / (float(target_resolution.x) * SCREEN_PIXEL_SIZE.x);
	vec2 uv = floor(UV / block_size / TEXTURE_PIXEL_SIZE) * block_size * TEXTURE_PIXEL_SIZE;
	vec2 uv_offset = floor(vec2(UV.x, fract(UV.y + TIME / 5.0)) / block_size / TEXTURE_PIXEL_SIZE) * block_size * TEXTURE_PIXEL_SIZE;
	float rand_val = texture(TEXTURE, uv_offset).r * 2.0;
	// float rand_val = random_value(floor(UV / TEXTURE_PIXEL_SIZE));
	COLOR = vec4(
		flame_color * rand_val,
		1.0
	);
	COLOR.a = .5 + (COLOR.r + COLOR.g + COLOR.b) / 3.0;
	
	vec2 dist = abs(2.0 * uv - 1.0);
	COLOR.a *= min(1.0 - dist.x * dist.x * dist.x, 1.0);
	COLOR.a *= min(1.0 - dist.y * dist.y, 1.0);
	// COLOR.rgb /= COLOR.a;
}

shader_type canvas_item;

// This variable will be updated by our GDScript every frame
uniform vec2 roll_offset = vec2(0.0, 0.0);

// Adjust this to make the rolling look faster or slower physically
uniform float roll_scale = 0.005;

void fragment() {
	// 1. Start with standard UV coordinates (0.0 to 1.0)
	vec2 new_uv = UV;

	// 2. Add the offset based on how far the marble has moved.
	// We multiply by roll_scale to tune the look.
	// The X movement shifts the U coordinate.
	// The Y movement shifts the V coordinate (negative because Y is down in 2D).
	new_uv.x += roll_offset.x * roll_scale;
	new_uv.y -= roll_offset.y * roll_scale;

	// 3. Apply the texture using these new, shifted coordinates
	COLOR = texture(TEXTURE, new_uv);
}
shader_type canvas_item;

// Glow/bloom em torno de pixels brilhantes — aplicado em projéteis, XP gems,
// e efeitos pra dar polish. Sampling de 8 vizinhos pra criar halo suave.
//
// Usage: material_override do Sprite2D com este shader. tex_size deve ser ajustada
// pra match TEXTURE size. glow_strength controla intensidade do halo.

uniform float glow_strength : hint_range(0.0, 3.0) = 1.5;
uniform float glow_radius : hint_range(0.0, 6.0) = 2.5;
uniform vec4 glow_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.4;

void fragment() {
	vec2 texel = 1.0 / vec2(textureSize(TEXTURE, 0));
	vec4 base = texture(TEXTURE, UV);
	// Sample 8 vizinhos pra construir glow.
	vec4 sum = vec4(0.0);
	float r = glow_radius;
	sum += texture(TEXTURE, UV + texel * vec2( r,  0));
	sum += texture(TEXTURE, UV + texel * vec2(-r,  0));
	sum += texture(TEXTURE, UV + texel * vec2( 0,  r));
	sum += texture(TEXTURE, UV + texel * vec2( 0, -r));
	sum += texture(TEXTURE, UV + texel * vec2( r,  r));
	sum += texture(TEXTURE, UV + texel * vec2(-r,  r));
	sum += texture(TEXTURE, UV + texel * vec2( r, -r));
	sum += texture(TEXTURE, UV + texel * vec2(-r, -r));
	sum /= 8.0;
	// Glow contribution: só onde brightness do entorno excede threshold.
	float bright = (sum.r + sum.g + sum.b) / 3.0;
	float halo = max(0.0, bright - threshold) * glow_strength;
	vec3 glow_color = glow_tint.rgb * halo * sum.a;
	// Compõe: base + glow halo onde transparente, mais brilho onde opaco.
	if (base.a < 0.01) {
		// Pixel transparente — só o halo de glow.
		COLOR = vec4(glow_color, halo * sum.a * glow_tint.a);
	} else {
		// Pixel opaco — boost com glow leve.
		COLOR = vec4(base.rgb + glow_color * 0.3, base.a);
	}
}

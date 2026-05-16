shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55;
uniform float chromatic_aberration : hint_range(0.0, 0.005) = 0.0015;
uniform float curvature : hint_range(0.0, 0.2) = 0.04;

void fragment() {
    // Curvatura sutil (efeito CRT bombado)
    vec2 uv = SCREEN_UV;
    vec2 cc = uv - vec2(0.5);
    float dist = dot(cc, cc) * curvature;
    uv = uv + cc * dist;

    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        // Aberração cromática
        vec4 col;
        col.r = texture(screen_tex, uv + vec2(chromatic_aberration, 0.0)).r;
        col.g = texture(screen_tex, uv).g;
        col.b = texture(screen_tex, uv - vec2(chromatic_aberration, 0.0)).b;
        col.a = 1.0;

        // Scanlines (alternam linhas claras e escuras)
        float scan = sin(uv.y * 360.0 * 3.14159) * 0.5 + 0.5;
        col.rgb *= 1.0 - scanline_intensity * (1.0 - scan);

        // Vignette (escurece bordas)
        vec2 vig = uv * (1.0 - uv);
        float v = pow(vig.x * vig.y * 14.0, vignette_strength);
        col.rgb *= clamp(v, 0.3, 1.0);

        COLOR = col;
    }
}

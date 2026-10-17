// Shader das entidades: flash de impacto e realce de estado (sangria, atordoamento...).
shader_type canvas_item;

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cor_flash : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// Realce: cor misturada aos pixels opacos (alfa = intensidade), pulsando suavemente.
uniform vec4 realce : source_color = vec4(0.0, 0.0, 0.0, 0.0);

void fragment() {
	vec4 c = COLOR;
	if (c.a > 0.01) {
		float pulso = 0.75 + 0.25 * sin(TIME * 9.0);
		c.rgb = mix(c.rgb, realce.rgb, realce.a * pulso);
		c.rgb = mix(c.rgb, cor_flash.rgb, flash);
	}
	COLOR = c;
}

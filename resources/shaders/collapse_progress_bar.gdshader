shader_type canvas_item;

uniform bool stepify = true;
uniform float value : hint_range(0.0, 1.0) = 1.0;
uniform int count = 8;
uniform vec2 margin = vec2(0.08, 0.0);
uniform float shear_angle : hint_range(-1.0, 1.0) = 0.0;
uniform sampler2D gradient_x : source_color;
uniform sampler2D gradient_y : source_color;
uniform bool use_value_gradient = false;
uniform bool invert = false;

// NUEVOS EFECTOS
uniform float chromatic_strength : hint_range(0.0, 0.05) = 0.0;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.5;
uniform float pulse_speed : hint_range(0.0, 5.0) = 2.0;
uniform bool enable_pulse = true;
uniform float border_thickness : hint_range(0.0, 0.1) = 0.02;
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 0.8);
uniform float shine_speed : hint_range(0.0, 2.0) = 0.5;
uniform bool enable_shine = true;
uniform float corner_radius : hint_range(0.0, 0.5) = 0.1;

vec4 get_gradient_color(sampler2D src, float position) {
    position = clamp(position, 0.01, 0.99);
    return texture(src, vec2(position, 0.5));
}

// Función para esquinas redondeadas
float rounded_box(vec2 uv, vec2 size, float radius) {
    vec2 half_size = size / 2.0;
    vec2 center = vec2(0.5);
    vec2 d = abs(uv - center) - half_size + radius;
    float dist = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - radius;
    return smoothstep(0.01, -0.01, dist);
}

float square_shape(vec2 uv, vec2 size) {
    if (corner_radius > 0.0) {
        return rounded_box(uv, size, corner_radius);
    } else {
        vec2 bl = step((1.0-size)/2.0, uv);
        vec2 tr = step((1.0-size)/2.0, 1.0-uv);
        return bl.x * bl.y * tr.x * tr.y;
    }
}

vec2 segmented_bar(vec2 uv) {
    float shape = 0.0;
    float bar_count = float(count);
    float bar_size = 1.0/bar_count;
    float separation = margin.x;
    float bar_value = 0.0;
    
    for (int i=0; i<count; i++) {
        float bar_x = bar_size * float(i);
        vec2 bar_uv = vec2((uv.x - bar_x) / bar_size, uv.y);
        
        float current_bar_value = clamp((value * bar_count) - float(i), 0.0, 1.0);
        
        if (stepify) {
            current_bar_value = step(0.99, current_bar_value);
        }
        
        vec2 bar_size_vec = vec2(1.0 - separation, 1.0 - margin.y);
        float bar_shape = square_shape(bar_uv, bar_size_vec);
        
        shape += bar_shape * current_bar_value;
        bar_value = max(bar_value, bar_uv.x * current_bar_value);
    }
    
    return vec2(shape, bar_value);
}

// Efecto de brillo animado
float shine_effect(vec2 uv, float time) {
    float shine_pos = fract(time * shine_speed);
    float shine = smoothstep(shine_pos - 0.1, shine_pos, uv.x) * 
                  smoothstep(shine_pos + 0.1, shine_pos, uv.x);
    return shine * 0.5;
}

// Efecto de aberración cromática
vec4 chromatic_aberration(sampler2D gradient, vec2 uv, float strength) {
    vec4 color_r = get_gradient_color(gradient, uv.x + strength);
    vec4 color_g = get_gradient_color(gradient, uv.x);
    vec4 color_b = get_gradient_color(gradient, uv.x - strength);
    return vec4(color_r.r, color_g.g, color_b.b, 1.0);
}

void fragment() {
    vec2 uv = UV;
    
    // NO invertir uv para que las barras se quiten de derecha a izquierda
    // uv.x permanece normal
    
    uv.x += uv.y * shear_angle;
    
    vec2 bar = segmented_bar(uv);
    float shape = bar.x;
    
    // Gradiente invertido (para que el rojo esté a la izquierda)
    vec4 color;
	if (chromatic_strength > 0.0) {
		color = chromatic_aberration(gradient_x, vec2(UV.x, 0.5), chromatic_strength);
	} else {
		color = get_gradient_color(gradient_x, UV.x);
	}
    vec4 y_gradient = get_gradient_color(gradient_y, uv.y);
    color *= y_gradient;
    
    // Efecto de pulso
    if (enable_pulse) {
        float pulse = sin(TIME * pulse_speed) * 0.15 + 0.85;
        color.rgb *= pulse;
    }
    
    // Efecto de brillo animado
    if (enable_shine) {
        float shine = shine_effect(UV, TIME);
        color.rgb += vec3(shine);
    }
    
    // Glow (resplandor)
    color.rgb *= (1.0 + glow_intensity * 0.3);
    
    // Borde interno
    vec2 border_bar = segmented_bar(uv);
    float border_shape = border_bar.x;
    
    // Crear borde
    float border_mask = shape - square_shape(uv, vec2(1.0 - border_thickness * 2.0, 1.0 - border_thickness * 2.0));
    vec4 final_color = mix(color, border_color, border_mask * shape);
    
    COLOR = vec4(final_color.rgb, final_color.a * shape);
}

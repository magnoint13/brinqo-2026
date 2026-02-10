shader_type canvas_item;

uniform vec4 liquid_color1 : source_color = vec4(0.02, 0.02, 0.2, 1.0);
uniform vec4 liquid_color2 : source_color = vec4(0.1, 0.05, 0.4, 1.0);
uniform vec4 liquid_color3 : source_color = vec4(0.2, 0.1, 0.7, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.4, 0.3, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.6, 0.5, 1.0, 1.0);
uniform float speed : hint_range(0.0, 2.0) = 0.5;
uniform float scale : hint_range(0.5, 5.0) = 1.5;
uniform float flow_strength : hint_range(0.0, 3.0) = 1.5;

vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
    vec2 i = floor(v + dot(v, C.yy));
    vec2 x0 = v - i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m;
    m = m*m;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
    vec3 g;
    g.x = a0.x * x0.x + h.x * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 6; i++) {
        value += amplitude * snoise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = UV * scale;
    float time = TIME * speed;
    
    vec2 flow1 = vec2(
        fbm(uv * 0.8 + vec2(time * 0.3, time * 0.2)),
        fbm(uv * 0.8 + vec2(time * 0.25 + 100.0, time * 0.35))
    ) * flow_strength;
    
    vec2 flow2 = vec2(
        fbm(uv * 1.2 - vec2(time * 0.4, time * 0.15)),
        fbm(uv * 1.2 - vec2(time * 0.2 + 50.0, time * 0.45))
    ) * flow_strength * 0.7;
    
    vec2 flow3 = vec2(
        fbm(uv * 0.5 + vec2(time * 0.15, time * 0.25)),
        fbm(uv * 0.5 + vec2(time * 0.3 + 200.0, time * 0.1))
    ) * flow_strength * 1.3;
    
    float wave1 = fbm(uv * 2.0 + flow1 + time * 0.2);
    float wave2 = fbm(uv * 3.0 + flow2 + time * 0.3);
    float wave3 = fbm(uv * 1.5 + flow3 + time * 0.15);
    
    float liquid = wave1 * 0.5 + wave2 * 0.3 + wave3 * 0.2;
    liquid = liquid * 0.5 + 0.5;
    
    float surface_detail = snoise(uv * 8.0 + flow1 * 2.0 + time * 0.5) * 0.5 + 0.5;
    liquid = mix(liquid, surface_detail, 0.3);
    
    float highlight = pow(liquid, 4.0) * (surface_detail * 0.5 + 0.5);
    
    vec4 color;
    float t = liquid * 3.5;
    
    if (t < 1.0) {
        color = mix(liquid_color1, liquid_color2, smoothstep(0.0, 1.0, t));
    } else if (t < 2.0) {
        color = mix(liquid_color2, liquid_color3, smoothstep(0.0, 1.0, t - 1.0));
    } else if (t < 3.0) {
        color = mix(liquid_color3, highlight_color, smoothstep(0.0, 1.0, t - 2.0));
    } else {
        color = mix(highlight_color, glow_color, smoothstep(0.0, 1.0, t - 3.0));
    }
    
    color.rgb += glow_color.rgb * highlight * 0.4;
    
    float ripple = sin(length(uv - vec2(0.5)) * 20.0 - time * 2.0) * 0.5 + 0.5;
    ripple *= smoothstep(0.8, 0.0, length(uv - vec2(0.5)));
    color.rgb += glow_color.rgb * ripple * 0.15;
    
    float vignette = 1.0 - length(UV - 0.5) * 0.5;
    vignette = smoothstep(0.0, 1.0, vignette);
    color.rgb *= vignette;
    
    COLOR = color;
}

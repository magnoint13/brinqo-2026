shader_type canvas_item;
render_mode blend_add;

void vertex() {
}

uniform float time_offset : hint_range(0.0f, 10.0f, 0.1f) = 0.0f;
uniform vec3 color_tint : source_color = vec3(1.0f);

// Adapted from: https://www.shadertoy.com/view/MlBGDw

#define SCALE 20.0
#define TIME_SCALE 0.25

#define Z_FROM -2.0
#define Z_TO 2.0
#define Z_STEP 0.1

#define A0 1.0
#define E1 1.0
#define E_1s E1
#define E_2p (E1 / 4.0)
#define E_3d (E1 / 9.0)

#define PI 3.141592653589793
#define R_A_PI_3 0.5641895835477563

void im_exp(float amp, float phase, out vec2 im) {
  im.x = cos(phase) * amp;
  im.y = sin(phase) * amp;
}


void wave_1s(vec3 pos, float t, out vec2 im) {
  float amp = R_A_PI_3 * exp(-pos.x / A0);
  float phase = E_1s * t;

  im_exp(amp, phase, im);
}


void wave_2p(vec3 pos, float t, out vec2 im) {
  float amp = 1.0 / (sqrt(2.0) * 4.0 * A0);
  amp *= R_A_PI_3 * exp(-pos.x / (2.0 * A0));
  amp *= pos.x * cos(pos.y);

  float phase = E_2p * t;

  im_exp(amp, phase, im);
}


void wave_3d(vec3 pos, float t, out vec2 im) {
  float amp = 1.0 / (sqrt(6.0) * 81.0 * A0 * A0);
  amp *= R_A_PI_3 * exp(-pos.x / (3.0 * A0));
  amp *= pos.x * pos.x;
  amp *= 3.0 * cos(pos.y) * cos(pos.y) - 1.0;

  float phase = E_3d * t;

  im_exp(amp, phase, im);
}


void draw(vec3 pos, float t, float time, out vec2 i) {
  vec2 w1;
  wave_1s(pos, t, w1);

  vec2 w2;
  wave_2p(pos, t, w2);

  //vec2 w3;
  //wave_3d(pos, t, w3);

  float f = time / 1.5;
  //float trans = max(cos(f), 0.0);

  float c1 = /*trans **/ cos(f);
  float c2 = sin(f);
  //float c3 = (1.0 - trans) * cos(f);

  w1 *= c1;
  w2 *= c2;
  //w3 *= c3;

  i = w1 + w2;// + w3;
  i.x *= i.x;
  i.y *= i.y;
}

void fragment() {
  vec2 pos = UV.xy - 0.5f;
  float time = (TIME + time_offset) * TIME_SCALE;

  float yz_ang = PI/2.0 + time * 0.6;
  float xz_ang = PI/2.0 + time * 0.33;

  mat3 rot_yz = mat3(
    vec3(1.0, 0.0, 0.0),
    vec3(0.0, cos(yz_ang), sin(yz_ang)),
    vec3(0.0, -sin(yz_ang), cos(yz_ang))
  );
  mat3 rot_xz = mat3(
    vec3(cos(xz_ang), 0.0, sin(xz_ang)),
    vec3(0.0, 1.0, 0.0),
    vec3(-sin(xz_ang), 0.0, cos(xz_ang))
  );
  mat3 rot = rot_yz * rot_xz;

  vec2 intensity = vec2(0.0, 0.0);
  for (float z = Z_FROM; z <= Z_TO; z += Z_STEP) {
    vec3 cart = vec3(pos, z);

    cart *= SCALE;
    cart *= rot;

    vec3 sph;
    sph.x = sqrt(cart.x * cart.x + cart.y * cart.y + cart.z * cart.z);
    sph.y = acos(cart.z / sph.x);
    sph.z = atan(cart.y / cart.x);

    vec2 i;
    draw(sph, time / E1 * 30.0, time, i);

    intensity += i * Z_STEP / (Z_TO - Z_FROM);
  }

  intensity /= 0.0001;
  vec3 total = vec3(intensity.x + intensity.y);
  vec3 hue = vec3(intensity, 0.0);
  vec3 final_rgb = (total + hue * 0.23) / 1.23;
  final_rgb *= color_tint;
  float alpha = max(final_rgb.r, max(final_rgb.g, final_rgb.b));
  alpha = clamp(alpha * 2.0, 0.0, 1.0);
  COLOR = vec4(final_rgb, alpha);
  //COLOR = vec4(final_rgb * 2.0, 1.0);
}

/*
void fragment() {
  vec2 pos = UV.xy - vec2(0.5f);
  float value = exp(- (pos.x * pos.x + pos.y * pos.y) / (2.0f * 0.25f * 0.25f));
  COLOR = value * value * vec4(1.0f, 1.0f, 0.0f, 1.0f);
}
*/

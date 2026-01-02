shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, depth_test_disabled, shadows_disabled;

///// ПАРАМЕТРЫ КРУГА /////
uniform vec2 circle_center = vec2(0.5, 0.5);
uniform float radius : hint_range(0.0, 1.0) = 0.35;
uniform float thickness : hint_range(0.0, 0.5) = 0.02;
uniform float edge_softness : hint_range(0.0, 0.05) = 0.002;
uniform vec4 border_color : source_color = vec4(1.0,1.0,1.0,1.0);
uniform vec4 fill_color   : source_color = vec4(0.0,0.0,0.0,0.0);
uniform float unscaled_time = 0.0;

///// ПАРАМЕТРЫ ВОЛН (исходят наружу от границы кольца) /////
uniform float wave_speed       : hint_range(-5.0, 5.0) = 0.8;
uniform float wave_wavelength  : hint_range(0.005, 1.0) = 0.06;
uniform float wave_decay       : hint_range(0.0, 20.0) = 4.0;
uniform float wave_strength    : hint_range(0.0, 1.5) = 0.9;
uniform float peak_thresh      : hint_range(0.0, 1.0) = 0.88;
uniform float peak_softness    : hint_range(0.0, 0.05) = 0.002;
uniform float max_distance     : hint_range(0.0, 2.0) = 0.5;
uniform float fade_range       : hint_range(0.0, 0.5) = 0.08;
uniform vec4  wave_color       : source_color = vec4(0.8,0.9,1.0,0.8);
uniform sampler2D wave_fade_curve : hint_default_white; // CurveTexture для кривой исчезновения волн (от 1.0 к 0.0 по расстоянию)

///// ПАРАМЕТРЫ ШУМА / НЕРАНОСТЕЙ /////
uniform float noise_scale_ring   : hint_range(0.1, 50.0) = 10.0; // масштаб шума по углу для кольца
uniform float noise_amp_ring     : hint_range(0.0, 0.1) = 0.01;   // амплитуда смещения радиуса кольца (в UV)
uniform float noise_speed_ring   : hint_range(-5.0, 5.0) = 0.6;   // анимирование шума для кольца
uniform int   noise_octaves_ring : hint_range(1, 6) = 3;          // октвы для FBM (кольцо)

uniform float noise_scale_wave   : hint_range(0.1, 50.0) = 6.0;   // масштаб шума для волн (пространственный)
uniform float noise_amp_wave     : hint_range(0.0, 1.0) = 0.25;   // сколько шума влияет на амплитуду волн (множитель)
uniform float noise_speed_wave   : hint_range(-5.0, 5.0) = 0.9;   // анимация шума для волн
uniform int   noise_octaves_wave : hint_range(1, 6) = 3;          // октвы для FBM (волны)

///// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ: simplex noise / fbm /////
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x*34.0)+1.0)*x); }

float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187, 0.366025403784439, -0.57735026919, 0.0243902439);
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;
    i = mod289(i);
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 )) + i.x + vec3(0.0, i1.x, 1.0 ));
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

// value noise replacement: normalized simplex (0..1)
float noise2(vec2 p) {
    return (snoise(p) + 1.0) * 0.5;
}

// fractal brownian motion (FBM)
float fbm(vec2 p, int octaves) {
    float amp = 0.5;
    float freq = 1.0;
    float sum = 0.0;
    float norm = 0.0;
    for (int i = 0; i < 6; ++i) {
        if (i >= octaves) break;
        sum += amp * noise2(p * freq);
        norm += amp;
        freq *= 2.0;
        amp *= 0.5;
    }
    return sum / max(norm, 1e-6);
}

void fragment() {
    vec2 uv = UV;
    vec2 to_center = uv - circle_center;
    float dist = length(to_center); // расстояние от центра в UV

    // антиалиасинг базируем на производных
    float pixel_aa = fwidth(dist);
    float aa = max(edge_softness, pixel_aa);

    // --- ПОЛЯРНЫЕ КООРДИНАТЫ для кольца (для шумовой неровности по углу) ---
    float angle = atan(to_center.y, to_center.x); // -PI..PI

    // анимируем шум по времени ротационно
    float t = unscaled_time;
	if (t==0.0f)
	{
		t=TIME;
	}
    float angle_mod = angle + t * noise_speed_ring;

    // используем 2D-полярный ввод в fbm, чтобы шум был непрерывным по углу
    vec2 ring_noise_pos = vec2(cos(angle_mod), sin(angle_mod)) * noise_scale_ring;
    float ring_noise = fbm(ring_noise_pos, noise_octaves_ring); // ~0..1
    ring_noise = (ring_noise - 0.5) * 2.0; // -1..1
    float radius_perturbed = radius + ring_noise * noise_amp_ring;

    // Увеличим полуширину с запасом по амплитуде шума, чтобы смещение не "вырезало" кольцо:
    float half_th = thickness * 0.5 + abs(noise_amp_ring) * 0.6; // 0.6 — эмпирический запас, можно менять
    float d = abs(dist - radius_perturbed);
    float ring_mask = 1.0 - smoothstep(half_th - aa, half_th + aa, d);

    // заполнение внутри кольца: используем НЕ-пертурбированный радиус (иначе внутренняя заливка может быть странной)
    float fill_mask = 1.0 - smoothstep(radius - aa, radius + aa, dist);
    vec4 base_col = mix(fill_color, border_color, ring_mask);

    // --- ВОЛНЫ: исходят наружу от границы кольца ---
    float radial_from_ring = dist - radius_perturbed; // стартуем именно от perturbed границы

    // только наружные волны
    float outside_step = step(0.0, radial_from_ring);

    // ограничение по max_distance с плавным затуханием
    float distance_fade = 1.0 - smoothstep(max_distance - fade_range, max_distance, radial_from_ring);

    // частота волны
    float freq = 2.0 * PI / max(wave_wavelength, 1e-6);
    float phase = freq * (radial_from_ring - wave_speed * t);

    // просторный шум для волн (чтобы фронты не были идеально круглыми)
    // ротационная анимация вокруг центра
    vec2 pos = to_center; // относительный центр
    float c = cos(t * noise_speed_wave);
    float s = sin(t * noise_speed_wave);
    vec2 rot_pos = vec2(c * pos.x - s * pos.y, s * pos.x + c * pos.y);
    vec2 wave_noise_pos = rot_pos * noise_scale_wave;
    float wave_fbm = fbm(wave_noise_pos, noise_octaves_wave); // 0..1
    // центрируем: -0.5..0.5
    float wave_fbm_c = (wave_fbm - 0.5);

    // Модифицируем фазу и амплитуду волн шумом:
    // phase offset по пространству -> фронты будут рваные
    float phase_offset = wave_fbm_c * noise_amp_wave * 2.0; // смещение фазы
    float raw = sin(phase + phase_offset);

    // абсолютная синусоида для пиков
    float raw_abs = abs(raw);
    float peak_aa = max(peak_softness, fwidth(raw_abs));
    float wave_band = smoothstep(peak_thresh - peak_aa, peak_thresh + peak_aa, raw_abs);

    // амплитуда волн также модулируется шумом (локально сильнее/слабее)
    float local_amp = 1.0 + wave_fbm_c * noise_amp_wave; // 1 +/- small
    local_amp = max(0.0, local_amp);

    // нормализованное расстояние для кривой
    float norm_rad = clamp(radial_from_ring / max(max_distance, 1e-6), 0.0, 1.0);
    float curve_fade = texture(wave_fade_curve, vec2(norm_rad, 0.0)).r;

    // экспоненциальное затухание по расстоянию (и local_amp)
    float env = exp(-max(0.0, radial_from_ring) * wave_decay) * local_amp * curve_fade;

    // итоговая маска волн: учитываем расстояние, наружность, силу и fade
    float wave_mask = wave_band * env * distance_fade * outside_step * wave_strength;

    // можно добавить вторую гармонику с другим шумом для богатства
    vec2 wave_noise_pos2 = wave_noise_pos * 1.7 + vec2(23.0);
    float phase2_off = fbm(wave_noise_pos2, noise_octaves_wave) - 0.5;
    float raw2 = abs(sin(0.6 * phase + phase2_off * 2.0));
    float band2 = smoothstep(0.82 - peak_aa, 0.82 + peak_aa, raw2) * 0.45;
    float env2  = exp(-max(0.0, radial_from_ring) * (wave_decay * 0.6)) * curve_fade;
    float wave_mask2 = band2 * env2 * distance_fade * outside_step * (wave_strength * 0.5);

    wave_mask += wave_mask2;
    wave_mask = clamp(wave_mask, 0.0, 1.0);

    // Наложение цвета волн
    vec3 waves_rgb = wave_color.rgb * wave_mask;
    float waves_a = wave_color.a * wave_mask;

    // Комбинация: аддитивно подсвечиваем базовый цвет волнами
    vec3 out_rgb = base_col.rgb + waves_rgb;
    float out_alpha = max(base_col.a, waves_a);

    // Если ни заливка, ни обводка, ни волны — прозрачный пиксель
    float visible_mask = max(max(fill_mask, ring_mask), wave_mask);
    out_alpha *= visible_mask;

    // Для spatial shader используем ALBEDO и ALPHA
    ALBEDO = out_rgb;
    ALPHA = out_alpha;
}


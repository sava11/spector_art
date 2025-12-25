shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 base_position = vec3(0.0, 0.0, 0.0);
uniform float fade_start_height : hint_range(0.0, 10.0) = 1.0;
uniform float fade_end_height : hint_range(0.0, 10.0) = 3.0;

// Albedo
uniform sampler2D albedo_texture;
uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Metallic and Roughness (separate as in StandardMaterial3D)
uniform sampler2D metallic_texture : hint_default_black;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D roughness_texture : hint_default_white;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;

// Specular
uniform float specular : hint_range(0.0, 1.0) = 0.5;

// Emission
uniform sampler2D emission_texture : hint_default_black;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy_multiplier : hint_range(0.0, 100.0) = 1.0;

// Normal Map
uniform sampler2D normal_texture ;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;

// Rim Lighting
uniform sampler2D rim_texture : hint_default_white;
uniform float rim : hint_range(0.0, 1.0) = 0.0;
uniform float rim_tint : hint_range(0.0, 1.0) = 0.5;

// Clearcoat
uniform sampler2D clearcoat_texture : hint_default_white;
uniform float clearcoat : hint_range(0.0, 1.0) = 0.0;
uniform float clearcoat_gloss : hint_range(0.0, 1.0) = 1.0;

// Anisotropy
uniform sampler2D anisotropy_flowmap : hint_default_white;
uniform float anisotropy : hint_range(-1.0, 1.0) = 0.0;

// Subsurface Scattering (SSS)
uniform sampler2D sss_strength_texture : hint_default_white;
uniform float sss_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 sss_transmittance_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float sss_transmittance_depth : hint_range(0.0, 10.0) = 0.1;
uniform float sss_transmittance_boost : hint_range(0.0, 10.0) = 0.0;

// Ambient Occlusion
uniform sampler2D ao_texture : hint_default_white;
uniform float ao_light_affect : hint_range(0.0, 1.0) = 0.0;

// Backlight
uniform sampler2D backlight_texture : hint_default_black;
uniform vec4 backlight_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Varying for world position
varying vec3 world_vertex;

void vertex() {
    world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // Calculate fade alpha based on height
    float height = world_vertex.y - base_position.y;
    float alpha = 1.0 - smoothstep(fade_start_height, fade_end_height, height);

    // Albedo
    vec4 albedo_tex = texture(albedo_texture, UV) * albedo_color;
    ALBEDO = albedo_tex.rgb;

    // Metallic
    float metal_tex = texture(metallic_texture, UV).r;
    METALLIC = metal_tex * metallic;

    // Roughness
    float rough_tex = texture(roughness_texture, UV).r;
    ROUGHNESS = rough_tex * roughness;

    // Specular
    SPECULAR = specular;

    // Emission
    vec3 emission_tex = texture(emission_texture, UV).rgb * emission_color.rgb * emission_energy_multiplier;
    EMISSION = emission_tex;

    // Normal Map
    vec3 normal_tex = texture(normal_texture, UV).rgb;
    NORMAL_MAP = normalize(normal_tex * 2.0 - 1.0);
    NORMAL_MAP_DEPTH = normal_scale;

    // Rim Lighting
    float rim_tex = texture(rim_texture, UV).r;
    RIM = rim * rim_tex;
    RIM_TINT = rim_tint;

    // Clearcoat
    vec4 clearcoat_tex = texture(clearcoat_texture, UV);
    CLEARCOAT = clearcoat * clearcoat_tex.r;
    CLEARCOAT_ROUGHNESS = clearcoat_gloss * clearcoat_tex.g;

    // Anisotropy
    vec4 anisotropy_tex = texture(anisotropy_flowmap, UV);
    ANISOTROPY_FLOW = anisotropy_tex.rg * 2.0 - 1.0;
    ANISOTROPY = anisotropy * anisotropy_tex.b;

    // Subsurface Scattering
    float sss_tex = texture(sss_strength_texture, UV).r;
    SSS_STRENGTH = sss_strength * sss_tex;
    SSS_TRANSMITTANCE_COLOR = sss_transmittance_color;
    SSS_TRANSMITTANCE_DEPTH = sss_transmittance_depth;
    SSS_TRANSMITTANCE_BOOST = sss_transmittance_boost;

    // Ambient Occlusion
    float ao_tex = texture(ao_texture, UV).r;
    AO = ao_tex;
    AO_LIGHT_AFFECT = ao_light_affect;

    // Backlight
    vec3 backlight_tex = texture(backlight_texture, UV).rgb * backlight_color.rgb;
    BACKLIGHT = backlight_tex;

    // Apply alpha with fade
    ALPHA = albedo_tex.a * alpha;

    // Discard fully transparent pixels
    if (ALPHA < 0.01) {
        discard;
    }
}
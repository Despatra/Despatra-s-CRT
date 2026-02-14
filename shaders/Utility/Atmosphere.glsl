#define UTILITY_ATMOSPHERE
#ifndef UTILITY_SETTINGS
    #include Settings.glsl
#endif

// Uniforms //
uniform mat4 gbufferModelViewInverse;

uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform bool HasLightSource;

// Constants //
vec3 ShadowLightDirection = normalize( (gbufferModelViewInverse * vec4(shadowLightPosition, 1.0)).xyz );
vec3 ShadowLightColor = ((HasLightSource) ?
    (shadowLightPosition == sunPosition) ?
        (KelvinToRGB(Atmosphere_Sun_Tempurature) * Atmosphere_Sun_Brightness) :
        (KelvinToRGB(Atmosphere_Moon_Tempurature) * Atmosphere_Moon_Brightness) :
    vec3(0.0)) * clamp(ShadowLightDirection.y*7.0, 0.0, 1.0);
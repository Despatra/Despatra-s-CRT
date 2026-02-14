#version 330 compatibility
#include Utility/Common.glsl

// Textures //
uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform sampler2D specular;

// Uniforms //
uniform float alphaTestRef;
uniform float fogStart;
uniform float fogEnd;
uniform vec3 fogColor;
uniform int fogMode;
uniform int fogShape;
uniform float far;

// In //
in vec2 TexCoord;
in vec2 LightmapCoord;
in vec4 GLColor;
in vec3 ViewPosition;

in vec3 VertexNormal;
in float TextureSize;
in float Emission;

// Out //
/* RENDERTARGETS: 0,2 */
layout (location = 0) out vec4 FragColor;
layout (location = 1) out vec4 FragSpecular;

// Includes //
#include Utility/Atmosphere.glsl

// Code //
float LinearStep(float edge0, float edge1, float x){
    return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

float FogIntensity(vec3 ViewPosition){
    #define GL_EXP 2048
    #define GL_EXP2 2049
    #define FOG_SPHERE 0

    float Distance = length(ViewPosition);
    float CylDistance = max(length(ViewPosition.xz), abs(ViewPosition.y));

    float x;
    if (fogShape == FOG_SPHERE || true){
        x = max(
            LinearStep(fogStart, fogEnd, Distance),
            LinearStep(far - clamp(0.1*far, 4.0, 64.0), far, CylDistance)
        );
    } else {
        x = LinearStep(far - clamp(0.1*far, 4.0, 64.0), far, CylDistance);
    }

    float t;
    if (fogMode == GL_EXP){
        return exp(x) - 1.0;
    } else if (fogMode == GL_EXP2){
        return exp2(x) - 1.0;
    } else {
        return x;
    }
}

void main(){
    FragColor = texture(gtexture, TexCoord);
    FragColor *= (texture(lightmap, LightmapCoord) * GLColor) +
        vec4(LightmapCoord.y * 0.5 * ShadowLightColor * max(0.0, dot(ShadowLightDirection, VertexNormal)), 1.0);

    float FogIntensity = FogIntensity(ViewPosition);
    FragColor.rgb = mix(FragColor.rgb, fogColor, FogIntensity);

    FragSpecular = vec4(0.0,0.0,0.0,1.0);
    FragSpecular.r = fract(texture(specular, TexCoord).a) * 254.0 / 255.0;

    if (FragSpecular.r == 0.0) {
        float TextureBrightness = Lumenosity(textureLod(gtexture, TexCoord, log2(TextureSize)).rgb);
        FragSpecular.r = (Emission / 15.0) * max(0.0, (Lumenosity(FragColor.rgb) - TextureBrightness)) / (1.0 - TextureBrightness);
    }

    FragSpecular.rgb *= (1.0 - FogIntensity);

    if (FragColor.a < alphaTestRef) discard;
}
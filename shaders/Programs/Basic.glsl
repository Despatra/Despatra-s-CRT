#version 330 compatibility
#include ../Utility/Common.glsl
/*
    Defines:
    PASS_VERTEX - Sets to vertex shader
    PASS_FRAGMENT - Sets to fragment shader
    PASS_STYLE_GBUFFERS - Uses a gbuffers_ setup
    PASS_STYLE_COMPOSITE - Uses a screen space setup
*/

#ifdef PASS_VERTEX
    // Out //
    #ifdef PASS_STYLE_GBUFFERS
        out vec2 TexCoord;
        out vec2 LightmapCoord;
        out vec4 GLColor;
        out vec3 ViewPosition;
        out vec3 VertexNormal;
    #endif
    #ifdef PASS_STYLE_COMPOSITE
        out vec2 FragCoord;
    #endif

    // Code //
    void main(){
        gl_Position = ftransform();
        #ifdef PASS_STYLE_GBUFFERS
            TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
            LightmapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
            LightmapCoord = gl_MultiTexCoord1.xy/256.0;
            GLColor = gl_Color;
            ViewPosition = (gl_ModelViewMatrix * gl_Vertex).xyz;
            VertexNormal = gl_Normal;
        #endif
        #ifdef PASS_STYLE_COMPOSITE
            FragCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
        #endif
    }
#endif

#ifdef PASS_FRAGMENT
    // Textures //
    #ifdef PASS_STYLE_GBUFFERS
        uniform sampler2D gtexture;
        uniform sampler2D lightmap;

        uniform sampler2D specular;
    #endif
    #ifdef PASS_STYLE_COMPOSITE
        uniform sampler2D colortex0;
    #endif

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
    #ifdef PASS_STYLE_GBUFFERS
        in vec2 LightmapCoord;
        in vec4 GLColor;
        in vec3 ViewPosition;
        in vec3 VertexNormal;
    #endif

    // Out //
    /* RENDERTARGETS: 0,2 */
    layout (location = 0) out vec4 FragColor;
    layout (location = 1) out vec4 FragSpecular;

    // Includes //
    #include ../Utility/Atmosphere.glsl

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
        #ifdef PASS_STYLE_GBUFFERS
            FragColor = texture(gtexture, TexCoord);
            FragColor *= (texture(lightmap, LightmapCoord) * GLColor) +
                vec4(LightmapCoord.y * 0.5 * ShadowLightColor * max(0.0, dot(ShadowLightDirection, VertexNormal)), 1.0);

            float FogIntensity = FogIntensity(ViewPosition);
            FragColor.rgb = mix(FragColor.rgb, fogColor, FogIntensity);

            FragSpecular = vec4(0.0,0.0,0.0,1.0);
            FragSpecular.r = fract(texture(specular, TexCoord).a) * 254.0 / 255.0;
            FragSpecular.rgb *= (1.0 - FogIntensity);
        #endif
        #ifdef PASS_STYLE_COMPOSITE
            FragColor = texture(colortex0, TexCoord);
        #endif

        if (FragColor.a < alphaTestRef) discard;
    }
#endif
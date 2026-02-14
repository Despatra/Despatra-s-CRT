#version 330 compatibility
#include Utility/Common.glsl

// Uniforms //
uniform ivec2 atlasSize;

// In //
in vec2 mc_midTexCoord;
in vec4 at_midBlock;

// Out //
out vec2 TexCoord;
out vec2 LightmapCoord;
out vec4 GLColor;
out vec3 ViewPosition;

out vec3 VertexNormal;
out float TextureSize;
out float Emission;

// Code //
void main(){
    gl_Position = ftransform();

    TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    LightmapCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    LightmapCoord = gl_MultiTexCoord1.xy/256.0;
    GLColor = gl_Color;
    ViewPosition = (gl_ModelViewMatrix * gl_Vertex).xyz;

    VertexNormal = gl_Normal;
    vec2 TexSize = atlasSize * (2.0 * abs(mc_midTexCoord - TexCoord));
    TextureSize = max(TexSize.x, TexSize.y);
    Emission = at_midBlock.w;
}
#version 330 compatibility

// Textures //
uniform sampler2D gtexture;

// Uniforms //
uniform float alphaTestRef;
uniform int Dimension;

// In //
in vec2 TexCoord;
in vec4 GLColor;

// Out //
/* RENDERTARGETS: 0,2 */
layout (location = 0) out vec4 FragColor;
layout (location = 1) out vec4 FragSpecular;

// Code //
void main(){
	FragColor = texture(gtexture, TexCoord) * GLColor;
	if (Dimension == 2) FragColor.rgb *= 0.25;
	FragSpecular = vec4(0.0,0.0,0.0,1.0);
	if (FragColor.a < alphaTestRef) discard;
}
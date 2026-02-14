#version 330 compatibility

// Out //
out vec2 TexCoord;
out vec4 GLColor;

// Code //
void main(){
	gl_Position = ftransform();
	TexCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	GLColor = gl_Color;
}
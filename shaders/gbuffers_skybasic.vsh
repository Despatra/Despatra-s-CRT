#version 330 compatibility

// Out //
out vec4 StarData; //rgb = star color, a = is a star?

// Code //
void main(){
	gl_Position = ftransform();
	
	StarData = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
}
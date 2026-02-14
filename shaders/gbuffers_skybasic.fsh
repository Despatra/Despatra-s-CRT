#version 330 compatibility

// Uniforms //
uniform float viewHeight;
uniform float viewWidth;

uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;

uniform vec3 fogColor;
uniform vec3 skyColor;

// In //
in vec4 StarData; //rgb = star color, a = is a star?

// Out //
/* RENDERTARGETS: 0,2 */
layout (location = 0) out vec4 FragColor;
layout (location = 1) out vec4 FragSpecular;

// Constants //
vec2 ScreenSize = vec2(viewWidth, viewHeight);

// Code //
float FogFalloff(float d, float coeff){
	return coeff / (d * d + coeff);
}

vec3 CalcSkyColor(vec3 pos){
	float upDot = dot(pos, gbufferModelView[1].xyz);
	return mix(skyColor, fogColor, FogFalloff( max(upDot, 0.0), 0.25 ));
}

vec3 ScreenToView(vec3 screenPos){
	vec4 ndcPos = vec4(screenPos, 1.0) * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * ndcPos;
	return tmp.xyz / tmp.w;
}

void main(){
	if (StarData.a > 0.5){
		FragColor = vec4(StarData.rgb, 1.0);
		FragSpecular = vec4(1.0,0.0,0.0,1.0);
	} else{
		vec3 pos = ScreenToView(vec3(gl_FragCoord.xy / ScreenSize, 1.0));
		FragColor = vec4(CalcSkyColor(normalize(pos)), 1.0);
		FragSpecular = vec4(0.0,0.0,0.0,1.0);
	}
}
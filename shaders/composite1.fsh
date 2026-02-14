#version 330 compatibility
#include Utility/Common.glsl

// Textures //
uniform sampler2D noisetex;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex2;

// Uniforms //
uniform float ScreenRatio;
uniform float CRTBaseRatio;

uniform vec2 ScreenSize;
uniform vec2 CRTBaseResolution;
uniform vec2 CRTResolution;
uniform float Pi;

// In //
in vec2 FragCoord;

// Out //
/* RENDERTARGETS: 0,1,2 */
layout (location = 0) out vec4 FragColor;
layout (location = 1) out vec4 FragBloom;
layout (location = 2) out vec4 FragAO;

// Globals //
ivec2 Texel = ivec2(FragCoord * ScreenSize);
ivec2 NoiseTexSize = textureSize(noisetex, 0);
vec3 Noise = texelFetch(noisetex, Texel % NoiseTexSize, 0).rgb;

// Code //
vec3 Bloom(float SampleSize, vec2 Coord){
	const float Threshold = 0.5;
	const float Curve = 2.0;

	const int Points = 5 * (1 << Composite_BloomQuality);
	const float Phi = (1.0 + sqrt(5.0)) / 2.0; // Golden Ratio
	float AngleStep = 2.0*Pi * (1.0 - 1.0/Phi);

	vec2 Step = SampleSize * vec2(1.0, 0.125) / ScreenSize;

	vec3 Total = vec3(0.0);
	for (int n = 0; n < Points; n++){
		float i = n + Noise.r;
		float Radius = sqrt(i / (Points + Noise.r));
		float Angle = (AngleStep * i) + (Noise.g * 2.0*Pi);
		vec2 SampleOffset = pow(Radius, 2.0) * Step * vec2(sin(Angle), cos(Angle));
		vec2 SampleCoord = Coord + SampleOffset;

		vec3 Sample = texture(colortex0, SampleCoord).rgb;
		float Factor = pow(clamp(
			(pow(clamp(Lumenosity(Sample) - Threshold, 0.0, 1.0) / (1.0 - Threshold), 3.0) + pow(texture(colortex2, SampleCoord).r * 4.0, 0.25)), // Calculate Brightness
			0.0, 2.0), // Normalize and clamp
			Curve // Curve
		);

		Total += Sample * Factor;
	}

	Total /= Points;

	const float constant = 1.0;
	const float mult = 2.84;
	const float power = 1.56;
	Total = -exp(-mult*pow(Total, vec3(power))) + constant;

	return Total;
}

float GetAmbientOcclusion(vec2 Coord){
	return 0.0;
}

void main(){
	vec2 CenterCRTCoord = (floor(FragCoord * CRTResolution) + 0.5) / CRTResolution;
	vec2 Offset = abs(fract(FragCoord * CRTResolution) - 0.5) * 2.0;
	FragColor.rgb = texture(colortex0, CenterCRTCoord).rgb * mix(1.0 - length(pow(Offset, vec2(2.0, 3.0))), 1.0, 0.75);

	int SquareSize = 1 << int(log2(
		min(ScreenSize.x / CRTResolution.x, ScreenSize.y / CRTResolution.y)
	)); // Set into squares such that we can sample mipmaps to get averaged results

	vec2 BloomCoord = (floor(FragCoord * ScreenSize / SquareSize) + 0.5) / CRTResolution;
	if (clamp(BloomCoord, 0.0, 1.0) != BloomCoord) return;

	FragBloom.rgb = pow(Bloom(20.0, BloomCoord), vec3(Camera_Gamma));
	FragAO.r = GetAmbientOcclusion(BloomCoord);
}
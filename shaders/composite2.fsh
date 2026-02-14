#version 330 compatibility
#include Utility/Common.glsl

/*
	const bool colortex1MipmapEnabled = true;
*/

// Textures //
uniform sampler2D noisetex;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

// Uniforms //
uniform vec2 ScreenSize;
uniform vec2 CRTResolution;
uniform float Pi;

// In //
in vec2 FragCoord;

// Out //
/* RENDERTARGETS: 0 */
layout (location = 0) out vec4 FragColor;

// Globals //
ivec2 Texel = ivec2(FragCoord * ScreenSize);
ivec2 NoiseTexSize = textureSize(noisetex, 0);
vec3 Noise = texelFetch(noisetex, Texel % NoiseTexSize, 0).rgb;

// Code //
vec3 Blur(float SampleSize, vec2 Coord){
	const int Points = 5 * (1 << Composite_BlurQuality);
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

		Total += Sample;
	}

	return Total / Points;
}

vec2 CurveUV(vec2 uv){
	const float ViewScale = 0.86;

    uv = ((uv-0.5) * 2.0);
    uv *= ((1.0 / ViewScale) - 0.05) + vec2(0.05*pow(abs(uv.y), 3.0), 0.1*pow(abs(uv.x), 3.0));
    uv = pow(abs(uv), vec2(1.05)) * sign(uv);
    uv = (uv/2.0)+0.5;
	return uv;
}

void main(){
	vec2 CurvedCoord = CurveUV(FragCoord);

	if (clamp(CurvedCoord, 0.0, 1.0) != CurvedCoord){
		vec2 t = abs(0.5 - CurvedCoord) * 2.0;
		vec2 Reflect = normalize(
			pow(t / min(t.x, t.y), vec2(1.0)) *
			(vec2(t.x >= t.y, t.y > t.x) + 0.6)
		);
        float Strength = max(t.x, t.y)-1.0;
        Reflect *= 1.25 * Strength * sign(FragCoord - 0.5);
		vec2 ReflectCoord = CurvedCoord - Reflect;

		FragColor.rgb = Blur(50.0, ReflectCoord) * 0.1 * min(1.0, pow(max(t.x, t.y) - 1.0, 0.5) * 5.0);
		return;
	}

	vec2 edge = sqrt( 1.0 - ( abs(CurvedCoord-0.5) * 2.0));
    float fade = clamp(length(edge)*pow(min(edge.x, edge.y), 0.5), 0.0, 0.9);

	int SquareExp = int(log2( min(ScreenSize.x / CRTResolution.x, ScreenSize.y / CRTResolution.y) ));
	vec3 Bloom = texelFetch(colortex1, ivec2(CurvedCoord * CRTResolution), SquareExp).rgb;

	FragColor = texture(colortex0, CurvedCoord);
	FragColor.rgb += Bloom * Camera_BloomStrength;

	FragColor.rgb *= fade;
}
#include Settings.glsl

// Atmosphere //
float pow2(float v) {return v*v;}

float Lumenosity(vec3 Color){
	return sqrt( 0.299*pow2(Color.r) + 0.587*pow2(Color.g) + 0.114*pow2(Color.b) );
}

vec3 KelvinToRGB(float Kelvin){
    Kelvin /= 100.0;
    vec3 Color = vec3(
        (Kelvin <= 66.0) ? 
            (255) :
            (329.698727446 * pow((Kelvin - 60.0), -0.1332047592)),
        (Kelvin <= 66.0) ?
            (99.4708025861 * log(Kelvin) - 161.1195681661) :
            (288.1221695283 * pow((Kelvin - 60.0), -0.0755148492)),
        (Kelvin >= 66.0) ?
            (255) :
            (Kelvin <= 19.0) ?
                (0) :
                (138.5177312231 * log(Kelvin - 10.0) - 305.0447927307)
    );

    return clamp(Color / 255.0, 0.0, 1.0);
}
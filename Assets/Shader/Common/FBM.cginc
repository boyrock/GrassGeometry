#define NUM_OCTAVES 3
//#include "Noise.cginc"

float fbm(float st, int octaves) {
	float value = 0.0;
	float amplitud = 0.5;
	float2 shift = float2(100, 100);
	// Loop of octaves
	for (int i = 0; i < octaves; i++) {
		value += amplitud * cnoise(st);
		st *= 2.0;
		amplitud *= .5;
	}
	return value;
}

float fbm(float2 st, int octaves) {
	float value = 0.0;
	float amplitud = 0.5;
	float2 shift = float2(100, 100);
	// Loop of octaves
	for (int i = 0; i < octaves; i++) {
		value += amplitud * noise(st);
		st *= 2.0;
		amplitud *= .5;
	}
	return value;
}

float fbm(float3 st, int octaves) {
	float value = 0.0;
	float amplitud = 0.5;
	// Loop of octaves
	for (int i = 0; i < octaves; i++) {
		value += amplitud * cnoise(st);
		st *= 2.0;
		amplitud *= .5;
	}
	return value;
}

float fbm(float3 P, int octaves, float lacunarity, float gain)
{
	float sum = 0.0;
	float amp = 0.5;
	float3 pp = P;

	int i;

	for (i = 0; i < octaves; i += 1)
	{
		amp *= gain;
		sum += amp * abs((2 * cnoise(pp)) - 1);
		//sum += amp * cnoise(pp);
		pp *= lacunarity;
	}
	return sum;
}

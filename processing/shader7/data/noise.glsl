#define PROCESSING_TEX_SHADER

#define PI 3.1415926535897932384626
#define IMPULSE_CAP 100
#define OCTAVE_CAP 10
#define EPSILON .001
#define MORTON_ITERATIONS 16

uniform sampler2D textureSampler;

uniform float gridSize; //as a multiple of wavelength
uniform float density;
uniform int offset;

uniform vec4 harmonic;

uniform vec2 domainWarp;
uniform vec2 origin;

uniform vec2 resolution;


uint nextRand(uint lastRand){// rng
    return 3039177861U*lastRand;
}
float intToFloat(inout uint r){
	// float ret = float(r)/4.2949673E9;
	float ret = float(r) * 2.3283064E-10;
	r = nextRand(r);
	return ret;
}
 uint seed(ivec2 grid){
	// morton order seed,
	// interleave bits
	
	int mask = 1;
	int ret = 0;
	grid.y = grid.y << 1;
	for(int i=0; i<MORTON_ITERATIONS; i++){ //period of 2^MORTON_ITERATIONS cells
		ret = ret | (grid.x & mask);
		mask = mask << 1;
		ret = ret | (grid.y & mask);
		mask = mask << 1;
		grid.x = grid.x << 1;
		grid.y = grid.y << 1;
	}
	return uint(ret+offset);
 }
 
 int poisson(inout uint u, float lambda, float rootLambda){// from Galerne, Lagae, Lefebvre, Drettakis
	float u1 = intToFloat(u);
	float u2 = intToFloat(u);
	float x = sqrt(-2.0*log(u1+EPSILON))*cos(2.0*PI*u2);
	return int(lambda+rootLambda*x+.5);
 
 }
 
float evaluate(vec2 pos, float freq, vec2 orange){ 
	
	float gs = gridSize/freq;
	
	float lambda = density*gs*gs;
	float rootLambda = sqrt(lambda);
	
	float mPiInvGsSq = -PI/(gs*gs);

	vec2 gpos; // cell position in gridspace
	vec2 cpos = modf(pos/gs, gpos);// fragment position in cellspace
	vec2 mc = vec2(cpos.x<0, cpos.y<0);
	cpos+= mc;
	gpos-= mc;
	ivec2 grid = ivec2(gpos.xy);
	
	float v =0; // fragment value
	
	// for cells
	for(int dx=-1; dx<=1; dx++){
	for(int dy=-1; dy<=1; dy++){
		ivec2 d = ivec2(dx, dy);
		uint s = seed(grid+d); 
		uint u = nextRand(s);
		int impulses = poisson(u, lambda, rootLambda);
		int k=0;
		// for impulses
		for(int k=0; k<IMPULSE_CAP; k++){
			if(k>=impulses) break;
			// position using uniform distribution over cell
			vec2 fpos = vec2(intToFloat(u),intToFloat(u));
			// displacement to fragment
			vec2 delta = (cpos - fpos - d)*gs;
			// harmonic (frequency, orientation)
	
			vec2 h = vec2(freq,
						  mix(orange.x, orange.y, intToFloat(u)));
						  // values for this feature
			// weight
			float w = intToFloat(u)*2.0-1.0;
			// evaluate kernel
			vec2 omega = vec2(cos(h.t), sin(h.t));
			v+= w
				*exp(dot(delta,delta)*mPiInvGsSq)
				*cos(2*PI*h.s*dot(delta, omega));
		}
	}}
	v /= rootLambda;
	return v;
}
float octaves(vec2 pos, float freq, vec2 orange, float num){
	float sigma=0.0;
	float norm=0.0;
	float s=1.0;
	for(int oct = 0; oct<OCTAVE_CAP; oct++){
		if(oct>=num) break;
		sigma += evaluate(pos, freq*pow(2,oct), orange)*s;
		norm+=s;
		s*=.5;
	}
	return sigma/norm;
}

void main(void){
	
	vec2 texCoords = (gl_FragCoord.xy/resolution.xy) * vec2(1.0, -1.0) + vec2(0.0, 1.0);
	
	vec2 domainOffset = domainWarp.xy*2.0*(texture2D(textureSampler, texCoords.xy).xy-vec2(.5));

	vec2 pos = gl_FragCoord.xy+origin.xy;
	
	float v = octaves(pos+domainOffset, harmonic.x, harmonic.zw, harmonic.y);
	
	v=v*.5+.5;
	
	
	vec3 c = vec3(v,v,v);
	gl_FragColor = vec4(c, 1.0);
	
}
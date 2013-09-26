#define PROCESSING_TEXTURE_SHADER

#define PI 3.1415926535897932384626
#define IMPULSE_CAP 100
#define OCTAVE_CAP 6
#define EPSILON .001
#define MORTON_ITERATIONS 8

uniform sampler2D textureSampler;

uniform vec4 writeFlags;
uniform vec4 readFlags;

uniform float gridSize; //as a multiple of wavelength
uniform float density;
uniform int offset;

uniform vec4 harmonic; //frequency, octaves, orientation, isotropy

uniform float domainWarp; //in pixels
uniform float harmonicWarp; //0 to 1

uniform vec2 origin;
uniform vec2 resolution;


uint nextRand(uint lastRand){// rng
    return 3039177861U*lastRand;
}
float intToFloat(inout uint r){ //returns a random value between -1 and 1, and advances the rng
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
 
float evaluate(vec2 pos, float freq, vec2 oRange){ 
	
	float gs = gridSize/freq;
	
	float lambda = density;//*gs*gs;
	float rootLambda = sqrt(lambda);
	
	vec2 gpos; // cell position in gridspace
	vec2 cpos = modf(pos/gs, gpos);// fragment position in cellspace
	vec2 mc = vec2(cpos.x<0, cpos.y<0);
	cpos+= mc;
	gpos-= mc;
	ivec2 grid = ivec2(gpos.xy);
	
	float v =0; // fragment value
	
	// for local cells
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
			
			// displacement to fragment, normalized to gridsize
			vec2 delta = (cpos - fpos - d);

			//feature orientation
			float orientation = mix(oRange.x, oRange.y, intToFloat(u));
			
			//feature weight
			float w = intToFloat(u)*2.0-1.0;
			
			// evaluate kernel
			vec2 omega = vec2(cos(orientation), sin(orientation));
			v+= w
				*exp(-PI*dot(delta,delta))
				*cos(2*PI*freq*gs*dot(delta, omega));
		}
	}}
	//normalize to density... this isn't quite right but works ok
	//the correct expression for sigma^2 is a big nasty integral
	v/=rootLambda;
	return v;
}
float octaves(vec2 pos, float freq, vec2 oRange, float num){
	float sigma=0.0;
	float norm=0.0;
	float s=1.0;
	for(int oct = 0; oct<OCTAVE_CAP; oct++){
		if(oct>=num) break;
		sigma += evaluate(pos, freq*pow(2.0,oct), oRange)*s;
		norm+=s;
		s*=.5;
	}
	return sigma/norm;
}

void main(void){
	
	vec2 texCoords = (gl_FragCoord.xy/resolution.xy) * vec2(1.0, -1.0) + vec2(0.0, 1.0);
	vec4 colorIn = texture2D(textureSampler, texCoords.xy);
	
	vec2 hvec = normalize(colorIn.zw);
	
	vec2 domainOffset = readFlags.xy * domainWarp*2.0*(normalize(colorIn.xy)-vec2(.5));
	float orientation = mix(harmonic.z, atan(hvec.y, hvec.x), harmonicWarp);
	vec2 oRange = vec2(orientation-.5*harmonic.w, orientation+.5*harmonic.w);
	
	vec2 pos = gl_FragCoord.xy+origin.xy;
	float v = octaves(pos+domainOffset, harmonic.x, oRange, harmonic.y);
	
	v=v*.5+.5;
	
	gl_FragColor = v*writeFlags + colorIn*(vec4(1.0)-writeFlags);
	if(writeFlags.w<0) gl_FragColor.w=1.0;
	
}
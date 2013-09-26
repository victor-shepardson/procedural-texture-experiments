#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.1415926535897932384626
#define IMPULSE_CAP 100
#define OCTAVE_CAP 5
#define EPSILON .001
#define MORTON_ITERATIONS 16

uniform vec3 gridSize;
uniform vec3 density;
uniform ivec3 offset;

uniform vec4 harmonicX;
uniform vec4 harmonicY;
uniform vec4 harmonicZ;

mat4 harmonic = mat4(harmonicX, harmonicY, harmonicZ, vec4(0.0));

uniform vec2 warp;
uniform vec2 origin;

vec3 lambda = density*gridSize*gridSize;
vec3 rootLambda = sqrt(lambda);

vec3 mPiInvGsSq = vec3(-PI)/(gridSize*gridSize);

uint nextRand(uint lastRand){// rng
    return 3039177861U*lastRand;
}
float intToFloat(inout uint r){
	// float ret = float(r)/4.2949673E9;
	float ret = float(r) * 2.3283064E-10;
	r = nextRand(r);
	return ret;
}
 uint seed(int gridX, int gridY, int offset){
	// morton order seed,
	// interleave bits
	
	int mask = 1;
	int ret = 0;
	gridY = gridY << 1;
	for(int i=0; i<MORTON_ITERATIONS; i++){ //period of 2^MORTON_ITERATIONS cells
		ret = ret | (gridX & mask);
		mask = mask << 1;
		ret = ret | (gridY & mask);
		mask = mask << 1;
		gridX = gridX << 1;
		gridY = gridY << 1;
	}
	return uint(ret+offset);
 }
 
 int poisson(inout uint u, float lambda, float rootLambda){// from Galerne, Lagae, Lefebvre, Drettakis
	float u1 = intToFloat(u);
	float u2 = intToFloat(u);
	float x = sqrt(-2.0*log(u1+EPSILON))*cos(2.0*PI*u2);
	return int(lambda+rootLambda*x+.5);
 
 }
 
float evaluate(vec2 pos, int i, int j){ //i is instance for warping, j is octave
	
	float scale = pow(2.0, j);
	float gs_ij = gridSize[i]/scale;
	vec4 hrange_ij = harmonic[i]; // range of values for this instance
	hrange_ij.x*=scale;
	float mPiInvGsSq_ij = mPiInvGsSq[i]*scale*scale;
	float lambda_ij = lambda[i]/(scale*scale);
	float rootLambda_ij = rootLambda[i]/scale;
	int offset_ij=offset[i];

	vec2 gpos; // cell position in gridspace
	vec2 cpos = modf(pos/gs_ij, gpos);// fragment position in cellspace
	vec2 mc = vec2(cpos.x<0, cpos.y<0);
	cpos+= mc;
	gpos-= mc;
	int gridX = int(gpos.x);
	int gridY = int(gpos.y);
	
	float v =0; // fragment value
	
	// for cells
	for(int dx=-1; dx<=1; dx++){
	for(int dy=-1; dy<=1; dy++){
		uint s = seed(gridX+dx, gridY+dy, offset_ij); 
		uint u = nextRand(s);
		int impulses = poisson(u, lambda_ij, rootLambda_ij);
		int k=0;
		// for impulses
		for(int k=0; k<IMPULSE_CAP; k++){
			if(k>=impulses) break;
			// position
			vec2 fpos = vec2(intToFloat(u),intToFloat(u));
			// displacement to fragment
			vec2 delta = (cpos - fpos - vec2(dx,dy))*gs_ij;
			// harmonic (frequency, orientation)
	
			vec2 h = vec2(hrange_ij.x, 
						  mix(hrange_ij.z, hrange_ij.w, intToFloat(u)));
						  // values for this feature
			// weight
			float w = intToFloat(u)*2.0-1.0;
			// evaluate kernel
			vec2 omega = vec2(cos(h.t), sin(h.t));
			v+= w
				*exp(dot(delta,delta)*mPiInvGsSq_ij)
				*cos(2*PI*h.s*dot(delta, omega));
		}
	}}
	v /= rootLambda_ij;
	return v;
}

float octaves(vec2 pos, int i){
	int num = int(harmonic[i].y);
	float sigma=0.0;
	float norm=0.0;
	float s=1.0;
	for(int oct = 0; oct<OCTAVE_CAP; oct++){
		if(oct>=num) break;
		sigma += evaluate(pos, i, oct)*s;
		norm+=s;
		s/=2.0;
	}
	return sigma/norm;
}
void main(void){

	vec2 pos = gl_FragCoord.xy+origin.xy;

	float nx = octaves(pos, 0);
	float ny = octaves(pos, 1);
	vec2 npos = vec2(nx,ny);
	float v = octaves(pos + dot(npos, warp), 2);
	
	v=v*.5+.5;
	vec3 c = vec3(v,v,v);
	gl_FragColor = vec4(c, 1.0);
}
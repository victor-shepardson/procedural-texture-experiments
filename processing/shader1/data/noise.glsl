#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.1415926535897932384626
#define IMPULSE_CAP 1000
#define EPSILON .001

uniform float gridSize; //side length of square grid used for evaluation
uniform float density; //control over number of impulses / unit area (accuracy)
uniform vec2 origin; //offset of image space from texture space
uniform int offset; //offset to rng seeds
uniform vec4 harmonic; //min freq, max freq, min orientation, max orientation

float lambda = density*gridSize*gridSize;
float rootLambda = sqrt(lambda);

float mPiInvGsSq = -PI/(gridSize*gridSize);
float invRootNineLambda = .33333333333/rootLambda;

uint nextRand(uint lastRand){//rng
    return 3039177861U*lastRand;
}
float consumeFloat(inout uint r){ //return a rand float in [0, 1), advance rng
	//float ret = float(r)/4.2949673E9;
	float ret = float(r) * 2.3283064E-10; //precise enough?
	r = nextRand(r);
	return ret;
}
 uint seed(ivec2 pos){
	//morton order seed,
	//interleave bits
	int mask = 1;
	int ret = 0;
	pos.y = pos.y << 1;
	for(int i=0; i<16; i++){
		ret = ret | (pos.x & mask);
		mask = mask << 1;
		ret = ret | (pos.y & mask);
		mask = mask << 1;
		pos.x = pos.x << 1;
		pos.y = pos.y << 1;
	}
	return uint(ret+offset);
 }
 
 int poisson(inout uint u){//from Galerne, Lagae, Lefebvre, Drettakis
	float u1 = consumeFloat(u);
	float u2 = consumeFloat(u);
	float x = sqrt(-2*log(u1+EPSILON))*cos(2*PI*u2);
	return int(lambda+rootLambda*x+.5);
 
 }
void main(void){
	//fragment position in image space: continuous [-inf, inf]
	vec2 pos = gl_FragCoord.xy+origin.xy;

	vec2 temp; 
	vec2 cpos = modf(pos/gridSize, temp); //fragment position in cell space: continuous [0, 1]
	//correct for negative coordinates
	vec2 mc = vec2(cpos.x<0, cpos.y<0);
	cpos+= mc; temp-= mc;
	ivec2 gpos = ivec2(temp); //cell position in grid space: integer in [-inf, inf]
	
	float v =0; //fragment value
	
	//for local cells
	ivec2 dnbr; //offset to nbr cell in grid space
	for(dnbr.x=-1; dnbr.x<=1; dnbr.x++){
	for(dnbr.y=-1; dnbr.y<=1; dnbr.y++){
		uint u = seed(gpos+dnbr); //deterministic seed for nbr cell
		//uint u = nextRand(s);
		int impulses = poisson(u); //number of impulses in nbr cell
		int k=0;
		//for impulses
		for(int k=0; k<IMPULSE_CAP; k++){
			if(k>=impulses) break;
			//position of impulse in cell space - uniform distribution
			vec2 ipos = vec2(consumeFloat(u), consumeFloat(u));
			//displacement to fragment
			vec2 delta = (cpos - ipos - vec2(dnbr))*gridSize;
			//inpulse harmonic (frequency, orientation) - uniform distribution on input ranges
			vec2 iharmonic = vec2(mix(harmonic.x, harmonic.y, consumeFloat(u)), 
						  mix(harmonic.z, harmonic.w, consumeFloat(u)));
			//weight - uniform dist [-1, 1]
			float w = consumeFloat(u)*2.0-1.0;
			//evaluate kernel, accumulate fragment value
			vec2 omega = vec2(cos(iharmonic.t), sin(iharmonic.t));
			v+= w
				*exp(dot(delta,delta)*mPiInvGsSq)
				*cos(2*PI*iharmonic.s*dot(delta, omega));
		}
	}}
	//normalize / clamp
	v*=invRootNineLambda;
	v=v*.5+.5;
	//monochrome
	vec3 c = vec3(v,v,v);
	//draw fragment
	gl_FragColor = vec4(c, 1.0);
}
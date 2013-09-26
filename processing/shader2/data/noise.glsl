#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.1415926535897932384626
#define IMPULSE_CAP 1000
#define EPSILON .001

uniform float gridSize;
uniform float density;
uniform vec2 resolution;
uniform vec2 origin;
uniform int offset;
uniform vec4 harmonic;

float lambda = density*gridSize*gridSize;
float rootLambda = sqrt(lambda);

float mPiInvGsSq = -PI/(gridSize*gridSize);
float invRootNineLambda = 1.0/(3*rootLambda);

uint nextRand(uint lastRand){//rng
    return 3039177861U*lastRand;
}
float intToFloat(inout uint r){
	//float ret = float(r)/4.2949673E9;
	float ret = float(r) * 2.3283064E-10;
	r = nextRand(r);
	return ret;
}
 uint seed(int gridX, int gridY){
	//morton order seed,
	//interleave bits
	
	int mask = 1;
	int ret = 0;
	gridY = gridY << 1;
	for(int i=0; i<16; i++){
		ret = ret | (gridX & mask);
		mask = mask << 1;
		ret = ret | (gridY & mask);
		mask = mask << 1;
		gridX = gridX << 1;
		gridY = gridY << 1;
	}
	return uint(ret+offset);
 }
 
 int poisson(inout uint u){//from Galerne, Lagae, Lefebvre, Drettakis
	float u1 = intToFloat(u);
	float u2 = intToFloat(u);
	float x = sqrt(-2*log(u1+EPSILON))*cos(2*PI*u2);
	return int(lambda+rootLambda*x+.5);
 
 }
 
float evaluate(vec2 pos){

	vec2 gpos; //cell position in gridspace
	vec2 cpos = modf(pos/gridSize, gpos);//fragment position in cellspace
	vec2 modCorrect = vec2(cpos.x<0, cpos.y<0);
	cpos+= modCorrect;
	gpos-= modCorrect;
	int gridX = int(gpos.x);
	int gridY = int(gpos.y);
	
	float v =0; //fragment value
	
	//for cells
	for(int dx=-1; dx<=1; dx++){
	for(int dy=-1; dy<=1; dy++){
		uint s = seed(gridX+dx, gridY+dy); 
		uint u = nextRand(s);
		int impulses = poisson(u);
		int k=0;
		//for impulses
		for(int k=0; k<IMPULSE_CAP; k++){
			if(k>=impulses) break;
			//position
			vec2 fpos = vec2(intToFloat(u),intToFloat(u));
			//displacement to fragment
			vec2 delta = (cpos - fpos - vec2(dx,dy))*gridSize;
			//harmonic (frequency, orientation)
			vec2 h = vec2(mix(harmonic.x, harmonic.y, intToFloat(u)), 
						  mix(harmonic.z, harmonic.w, intToFloat(u)));
			//weight
			float w = intToFloat(u)*2.0-1.0;
			//evaluate kernel
			vec2 omega = vec2(cos(h.t), sin(h.t));
			v+= w
				*exp(dot(delta,delta)*mPiInvGsSq)
				*cos(2*PI*h.s*dot(delta, omega));
		}
	}}
	v*=invRootNineLambda;
	v=v*.5+.5;
	return v;
}
void main(void){

	vec2 pos = gl_FragCoord.xy+origin.xy;

	float v = evaluate(pos);
	
	vec3 c = vec3(v,v,v);
	gl_FragColor = vec4(c, 1.0);
}
#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.1415926535897932384626
#define IMPULSE_CAP 1000
#define EPSILON .001

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
vec3 invRootNineLambda = 1.0/(3.0*rootLambda);

uint nextRand(uint lastRand){//rng
    return 3039177861U*lastRand;
}
float intToFloat(inout uint r){
	//float ret = float(r)/4.2949673E9;
	float ret = float(r) * 2.3283064E-10;
	r = nextRand(r);
	return ret;
}
 uint seed(int gridX, int gridY, int i){
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
	return uint(ret+offset[i]);
 }
 
 int poisson(inout uint u, int i){//from Galerne, Lagae, Lefebvre, Drettakis
	float u1 = intToFloat(u);
	float u2 = intToFloat(u);
	float x = sqrt(-2.0*log(u1+EPSILON))*cos(2.0*PI*u2);
	return int(lambda[i]+rootLambda[i]*x+.5);
 
 }
 
float evaluate(vec2 pos, int i){

	vec2 gpos; //cell position in gridspace
	vec2 cpos = modf(pos/gridSize[i], gpos);//fragment position in cellspace
	vec2 modCorrect = vec2(cpos.x<0, cpos.y<0);
	cpos+= modCorrect;
	gpos-= modCorrect;
	int gridX = int(gpos.x);
	int gridY = int(gpos.y);
	
	float v =0; //fragment value
	
	//for cells
	for(int dx=-1; dx<=1; dx++){
	for(int dy=-1; dy<=1; dy++){
		uint s = seed(gridX+dx, gridY+dy, i); 
		uint u = nextRand(s);
		int impulses = poisson(u, i);
		int k=0;
		//for impulses
		for(int k=0; k<IMPULSE_CAP; k++){
			if(k>=impulses) break;
			//position
			vec2 fpos = vec2(intToFloat(u),intToFloat(u));
			//displacement to fragment
			vec2 delta = (cpos - fpos - vec2(dx,dy))*gridSize[i];
			//harmonic (frequency, orientation)
			vec4 hrange = harmonic[i]; //range of values for this instance
			vec2 h = vec2(mix(hrange.x, hrange.y, intToFloat(u)), 
						  mix(hrange.z, hrange.w, intToFloat(u)));
						  //values for this feature
			//weight
			float w = intToFloat(u)*2.0-1.0;
			//w*=pow(2.0, 1.0-h.s/hrange.x);
			//evaluate kernel
			vec2 omega = vec2(cos(h.t), sin(h.t));
			v+= w
				*exp(dot(delta,delta)*mPiInvGsSq[i])
				*cos(2*PI*h.s*dot(delta, omega));
		}
	}}
	v*=invRootNineLambda[i];
	v=v*.5+.5;
	return v;
}
void main(void){

	vec2 pos = gl_FragCoord.xy+origin.xy;

	float nx = evaluate(pos, 0);
	float ny = evaluate(pos, 1);
	vec2 npos = vec2(nx,ny);
	float v = evaluate(pos + dot(npos, warp), 2);
	
	vec3 c = vec3(v,v,v);
	gl_FragColor = vec4(c, 1.0);
}
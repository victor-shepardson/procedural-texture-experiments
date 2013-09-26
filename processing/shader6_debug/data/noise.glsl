#define PROCESSING_COLOR_SHADER
#define PI 3.1415926535897932384626
#define IMPULSE_CAP 100
#define OCTAVE_CAP 10
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


void main(void){

	gl_FragColor = vec4(gl_FragCoord.xxyy/100.0);
}
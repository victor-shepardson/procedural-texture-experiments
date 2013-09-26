#define PROCESSING_TEXTURE_SHADER

#define PI 3.1415926535897932384626

uniform sampler2D textureSampler;
uniform vec2 resolution;

uniform float magnitude;

void main(void){
	
	vec2 vCoords = (gl_FragCoord.xy/resolution.xy) * vec2(1.0, -1.0) + vec2(0.0, 1.0);
	
	vec2 v = texture2D(textureSampler, vCoords.xy).xy;
		
	
	vec2 cCoords = vCoords - magnitude*(v-.5);
	
	float c = texture2D(textureSampler, cCoords.xy).z;
		
	gl_FragColor = vec4(v, c, 1.0);
	
}
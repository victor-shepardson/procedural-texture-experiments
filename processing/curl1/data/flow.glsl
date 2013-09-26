#define PROCESSING_TEXTURE_SHADER

#define PI 3.1415926535897932384626

uniform sampler2D textureSampler;
uniform vec2 resolution;

uniform float magnitude;

void main(void){
	
	vec2 texCoords = (gl_FragCoord.xy/resolution.xy) * vec2(1.0, -1.0) + vec2(0.0, 1.0);
	vec4 colorIn = texture2D(textureSampler, texCoords.xy);
	
	vec2 pos = (texCoords-.5) + magnitude*texCoords.x*(colorIn.xy-.5);
	float v = max(0, cos(100.0*pos.y)+1.0-4.0*abs(pos.y));
		
	gl_FragColor = vec4(vec3(v), 1.0);
	
	
}
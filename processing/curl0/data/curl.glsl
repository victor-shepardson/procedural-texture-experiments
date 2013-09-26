#define PROCESSING_TEXTURE_SHADER

uniform sampler2D textureSampler;
uniform vec2 resolution;

void main(void){
	
	vec2 texCoords_left = ((gl_FragCoord.xy+vec2(-1.0,0.0))/resolution.xy) * vec2(1.0, -1.0) + vec2(0.0, 1.0);
	vec4 colorIn_left = texture2D(textureSampler, texCoords_left.xy);
	
	vec2 texCoords_right = ((gl_FragCoord.xy+vec2(1.0,0.0))/resolution.xy) * vec2(1.0, -1.0) + vec2(0.0, 1.0);
	vec4 colorIn_right = texture2D(textureSampler, texCoords_right.xy);
	
	vec2 texCoords_up = ((gl_FragCoord.xy+vec2(0.0,1.0))/resolution.xy) * vec2(1.0, -1.0) + vec2(0.0, 1.0);
	vec4 colorIn_up = texture2D(textureSampler, texCoords_up.xy);
	
	vec2 texCoords_down = ((gl_FragCoord.xy+vec2(0.0,-1.0))/resolution.xy) * vec2(1.0, -1.0) + vec2(0.0, 1.0);
	vec4 colorIn_down = texture2D(textureSampler, texCoords_down.xy);
	
	vec2 colorOut;
	
	colorOut.x = ((colorIn_up.z-colorIn_down.z) - (colorIn_right.y-colorIn_left.y));
	colorOut.y = ((colorIn_right.x-colorIn_left.x) - (colorIn_right.z-colorIn_left.z));
	
	//colorOut=normalize(colorOut);
	gl_FragColor = vec4(colorOut*0.5+0.5 , 0.0, 1.0);
	
	
}
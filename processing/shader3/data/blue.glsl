#ifdef GL_ES
precision mediump float;
#endif

void main(void){
	vec3 c = vec3(0.0,0.0,1.0);
	gl_FragColor = vec4(c, 1.0);
}
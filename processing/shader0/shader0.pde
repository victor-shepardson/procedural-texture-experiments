PShader noise;

void setup() {
  size(1280, 720, P2D);
  noise = loadShader("noise.glsl"); 
}

int offset = 0xfeedbeef;
float originX=0;
float originY=0;

void draw() {
  background(0);
  shader(noise);
  noise.set("gridSize", 16.0);
  noise.set("density", 0.125);
  noise.set("origin", originX, originY);
  noise.set("offset", offset);
  noise.set("harmonic", 0.0625, 0.0625, 0, PI);
  rect(0, 0, width, height);
  originX--; originY--;
}

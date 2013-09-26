import controlP5.*;

ControlP5 cp5;
PShader cells;

int sliderPanelHeight;
int noiseWidth = 256;
int noiseHeight = 256;

//controlled by sliders
float density = 4;
float gridSize = 32;

int offset = 0xfeedbeef;
float originX=0;
float originY=0;

void setup() { 
  int sliderWidth=100;
  int sliderHeight=8;
  int sliderSpacing=4;
 
  int numSliders = 2;
  
  sliderPanelHeight = numSliders*(sliderHeight+sliderSpacing)+sliderSpacing;
 
  cp5=new ControlP5(this); 
  cp5.addSlider("density")
    .setPosition(4,sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,32);
  cp5.addSlider("gridSize")
    .setPosition(4,sliderHeight+2*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(4,64);
    
  size(noiseWidth, sliderPanelHeight+noiseHeight, P2D);
  cells = loadShader("cells.glsl");
}

void draw() {
  background(64);
  shader(cells);
  cells.set("gridSize", gridSize);
  cells.set("density", density/(gridSize*gridSize));
  cells.set("origin", originX, originY);
  cells.set("offset", offset);
  originX--; originY--;
  
  rect(0, sliderPanelHeight, noiseWidth, height);
  
  resetShader();
}

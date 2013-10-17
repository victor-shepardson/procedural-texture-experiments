import controlP5.*;

ControlP5 cp5;
PShader noise;

PGraphics buffer;
PImage img;

int sliderPanelHeight;
int noiseWidth = 512;
int noiseHeight = 256;

//controlled by sliders
float isotropy = PI;
float orientation = 0.0;
float wavelength = 32.0;
float density = 50;
float gridSize = 1;
float octaves = 1;
float synchronicity = 1;

int offset = 0xfeedbeef;
float originX=-noiseWidth/2;
float originY=-noiseHeight/2;

void updateBuffer(){
  //buffer.beginDraw();
  /*buffer.*/shader(noise);
  noise.set("gridSize", gridSize*wavelength);
  noise.set("density", density*pow(2,octaves-1));
  noise.set("origin", originX, originY);
  noise.set("offset", offset);
  noise.set("sync", synchronicity);
  noise.set("harmonic",
    1./wavelength, pow(2,octaves-1)/wavelength,
    orientation-isotropy*.5, orientation+isotropy*.5);
  //buffer.rect(0, 0, buffer.width, buffer.height);
  originX--; originY--;
  
  //img = buffer.get(0, 0, buffer.width, buffer.height);
  
  //buffer.endDraw();
  rect(0, sliderPanelHeight, noiseWidth, noiseHeight);
  resetShader();
}

void setup() { 
  
  int sliderWidth=100;
  int sliderHeight=8;
  int sliderSpacing=4;
 
  int numSliders = 7;
  
  sliderPanelHeight = numSliders*(sliderHeight+sliderSpacing)+sliderSpacing;
 
  cp5=new ControlP5(this); 
  cp5.addSlider("wavelength")
    .setPosition(4,sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(2,128);
  cp5.addSlider("synchronicity")
    .setPosition(4,sliderHeight+2*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,1);
  cp5.addSlider("isotropy")
    .setPosition(4,2*sliderHeight+3*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,PI);
  cp5.addSlider("orientation")
    .setPosition(4,3*sliderHeight+4*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,2*PI);
  cp5.addSlider("density")
    .setPosition(4,4*sliderHeight+5*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,100);
  cp5.addSlider("gridSize")
    .setPosition(4,5*sliderHeight+6*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,2);
  cp5.addSlider("octaves")
    .setPosition(4,6*sliderHeight+7*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(1,5);
    
  size(noiseWidth, sliderPanelHeight+noiseHeight, P2D);
  noise = loadShader("noise.glsl");
  //buffer = createGraphics(noiseWidth, noiseHeight, P2D);
  
  background(64);
  updateBuffer();

}

void draw() {
  updateBuffer();
  //image(img,0,sliderPanelHeight);
  
}

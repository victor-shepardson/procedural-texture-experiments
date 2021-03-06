import controlP5.*;

ControlP5 cp5;

PImage img;
RenderThread rThread;

int sliderPanelHeight;
int noiseWidth = 256;
int noiseHeight = 256;

//controlled by sliders
float isotropy = PI;
float orientation = 0.0;
float wavelength = 32.0;
float density = .02;
float gridSize = 32;
float octaves=1;

int offset = 0xfeedbeef;
float originX=0;
float originY=0;


void setup() { 
  
  int sliderWidth=100;
  int sliderHeight=8;
  int sliderSpacing=4;
 
  int numSliders = 6;
  
  sliderPanelHeight = numSliders*(sliderHeight+sliderSpacing)+sliderSpacing;
 
  cp5=new ControlP5(this); 
  cp5.addSlider("wavelength")
    .setPosition(4,sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(2,128);
  cp5.addSlider("isotropy")
    .setPosition(4,sliderHeight+2*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,PI);
  cp5.addSlider("orientation")
    .setPosition(4,2*sliderHeight+3*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,2*PI);
  cp5.addSlider("density")
    .setPosition(4,3*sliderHeight+4*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,.25);
  cp5.addSlider("gridSize")
    .setPosition(4,4*sliderHeight+5*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(4,64);
  cp5.addSlider("octaves")
    .setPosition(4,5*sliderHeight+6*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(1,5);
    
  size(noiseWidth, sliderPanelHeight+noiseHeight, P2D);

  rThread = new RenderThread(noiseWidth, noiseHeight);
  rThread.start();
  img = rThread.getImage();
  
  background(64);

}

void draw() {
  img = rThread.getImage();
  image(img,0,sliderPanelHeight);
  
}

class RenderThread extends Thread{
  PGraphics buffer;
  PImage img;
  PShader noise;
  int originX, originY;
  int offset;
  
  RenderThread(int w, int h){
    originX=originY=0;
    offset=0xfeedbeef;
    noise = loadShader("noise.glsl");
    buffer = createGraphics(w, h, P2D);
    updateBuffer():
  }
  
  void setParams(float gridSize, float density, float wavelength, float orientation){
    
  }
  
  void updateBuffer(){
    
    buffer.beginDraw();
      buffer.shader(noise);
      noise.set("gridSize", gridSize);
      noise.set("density", density);
      noise.set("origin", originX, originY);
      noise.set("offset", offset);
      noise.set("harmonic",
        1./wavelength, pow(2,octaves-1)/wavelength,
        orientation-isotropy*.5, orientation+isotropy*.5);
      buffer.rect(0, 0, buffer.width, buffer.height);
      originX--; originY--;
  
      img = buffer.get(0, 0, buffer.width, buffer.height);
  
      buffer.resetShader();
      buffer.endDraw();
  }
  
  void run(){
    while(true){
      updateBuffer();
    }
  }
  
  PImage getImage(){
     return img; 
  }
  
}

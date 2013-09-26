//frequency warping in X
//orientation warping in Y

//TODO: separate shader draw from GUI draw
//TODO: increase precision displayed on sliders
//TODO: choice of vertical, horizontal, frequency, orientation warp
//TODO: choice of gabor, cells
//TODO: examine power spectra of warped noise

import controlP5.*;

ControlP5 cp5;
RenderThread renderThread;

int sliderPanelHeight;
int noiseWidth = 512;
int noiseHeight = 256;

String[] prefix =     {"wavelength",  "gridSize",  "isotropy",  "orientation",  "density",   "octaves"};
float [] lowerRange = {4,             4,           0,           0,              0,           1};
float[] upperRange =  {128,           128,         PI,          PI,             .0625,       6};
String[] suffix = {"X", "Y", "Z"};

//controlled by sliders
float isotropyX = PI;
float orientationX = 0.0;
float wavelengthX = 64.0;
float densityX = .00;
float gridSizeX = 64;
float octavesX=4;

float isotropyY = PI;
float orientationY = 0.0;
float wavelengthY = 64.0;
float densityY = .02;
float gridSizeY = 64;
float octavesY=1;

float isotropyZ = 0;
float orientationZ = 0.0;
float wavelengthZ = 8.0;
float densityZ = .02;
float gridSizeZ = 32;
float octavesZ=1;

float warpX=0;
float warpY=0;

int offsetX = 0xfeedbeef;
int offsetY = 0xbeefdead;
int offsetZ = 0xabcdabcd;

float originX=0;
float originY=0;

void setup() { 
  
  int sliderWidth=min(256, noiseWidth-160);
  int sliderHeight=8;
  int sliderSpacing=4;
 
  int dropDownWidth = 80;
  int dropDownHeight = sliderHeight;
  
  sliderPanelHeight = (prefix.length+2)*(sliderHeight+sliderSpacing)+sliderSpacing;
 
  cp5=new ControlP5(this); 
  
  DropdownList ddl = 
    cp5.addDropdownList("textureSelect")
    .setPosition(noiseWidth-dropDownWidth-4, sliderSpacing+dropDownHeight)
    .setSize(dropDownWidth, dropDownHeight*(suffix.length+1))
    .setItemHeight(sliderHeight);
    
  
  for(int i=0; i<suffix.length; i++){
    ddl.addItem(suffix[i], i);
    for(int j=0; j<prefix.length; j++){
      cp5.addSlider(prefix[j]+suffix[i])
        .setPosition(4,j*sliderHeight+(j+1)*sliderSpacing)
        .setSize(sliderWidth, sliderHeight)
        .setRange(lowerRange[j],upperRange[j])
        .setVisible(false);//i==0);
    }
  }
  cp5.addSlider("warpX")
    .setPosition(4,6*sliderHeight+7*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,1);
  cp5.addSlider("warpY")
    .setPosition(4,7*sliderHeight+8*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,1);
    
  size(noiseWidth, sliderPanelHeight+noiseHeight, P2D);
  renderThread=new RenderThread(noiseWidth, noiseHeight);
  renderThread.setParams( gridSizeX,  gridSizeY,  gridSizeZ,
                  densityX,  densityY,  densityZ,
                  originX,  originY,
                  offsetX,  offsetY, offsetZ,
                  wavelengthX,  wavelengthY,  wavelengthZ,
                  orientationX,  orientationY,  orientationZ,
                  isotropyX,  isotropyY,  isotropyZ,
                  warpX,  warpY);
  renderThread.start();
}

void draw() {
  originX--; originY--;
  if(renderThread.frameReady()){
    image(renderThread.getFrame(), 0, sliderPanelHeight);
    renderThread.setParams(
                  gridSizeX,  gridSizeY,  gridSizeZ,
                  densityX,  densityY,  densityZ,
                  originX,  originY,
                  offsetX,  offsetY, offsetZ,
                  wavelengthX,  wavelengthY,  wavelengthZ,
                  orientationX,  orientationY,  orientationZ,
                  isotropyX,  isotropyY,  isotropyZ,
                  warpX,  warpY);
  }
}

void controlEvent(ControlEvent theEvent){
  if(theEvent.isGroup() && theEvent.getGroup().toString().equals("textureSelect [DropdownList]")){
    int curSuffix = int(theEvent.getGroup().getValue());
    for(int i=0; i<suffix.length; i++){
      for(int j=0; j<prefix.length; j++){
        if(i==curSuffix)
          cp5.getController(prefix[j]+suffix[i]).setVisible(true);
        else
          cp5.getController(prefix[j]+suffix[i]).setVisible(false);
      }
    }
  }
}

class RenderThread extends Thread {
  PShader noise;
  PGraphics buf;
  boolean done;
  
  RenderThread(int w, int h){
    buf = createGraphics(w,h,P2D);
    noise = buf.loadShader("noise.glsl");
    done = false; 
  }
  
  boolean frameReady(){
    return done;
  }
  
  PImage getFrame(){
    return buf.get(0,0,buf.width, buf.height);
  }
 
  void run() {
    buf.beginDraw();
    while(true){
      //buf.background(64);
      buf.shader(noise, POLYGON);

      buf.rect(0, 0, buf.width, buf.height);
      buf.resetShader(POLYGON);
      done=true;
    }
  }
  
  void setParams(float gridSizeX, float gridSizeY, float gridSizeZ,
                 float densityX, float densityY, float densityZ,
                 float originX, float originY,
                 int offsetX, int offsetY, int offsetZ,
                 float wavelengthX, float wavelengthY, float wavelengthZ,
                 float orientationX, float orientationY, float orientationZ,
                 float isotropyX, float isotropyY, float isotropyZ,
                 float warpX, float warpY){
    noise.set("gridSize", gridSizeX, gridSizeY, gridSizeZ);
    noise.set("density", densityX, densityY, densityZ);
    noise.set("origin", originX, originY);
    noise.set("offset", offsetX, offsetY, offsetZ);
    noise.set("harmonicX", 1./wavelengthX,
                         octavesX, 
                         orientationX-isotropyX*.5,
                         orientationX+isotropyX*.5);
    noise.set("harmonicY", 1./wavelengthY,
                         octavesY, 
                         orientationY-isotropyY*.5,
                         orientationY+isotropyY*.5);
    noise.set("harmonicZ", 1./wavelengthZ,
                         octavesZ,
                         orientationZ-isotropyZ*.5,
                         orientationZ+isotropyZ*.5);
    noise.set("warp", warpX, warpY);
    done=false;
  } 
  
}

//frequency warping in X
//orientation warping in Y

//TODO: separate shader draw from GUI draw
//TODO: increase precision displayed on sliders
//TODO: choice of vertical, horizontal, frequency, orientation warp
//TODO: choice of gabor, cells
//TODO: examine power spectra of warped noise

import controlP5.*;

ControlP5 cp5;
PShader noise;
PGraphics buffer;

int noiseWidth = 512;
int noiseHeight = 512;


String[] prefix =     {"wavelength",  "gridSize",  "isotropy",  "orientation",  "density",   "octaves"};
float [] lowerRange = {4,             .25,           0,           0,              0,           1};
float[] upperRange =  {128,           4,             PI,          PI,             .0625,       6};
String[] suffix = {"X", "Y", "Z"};

int sliderWidth=min(256, noiseWidth-160);
int sliderHeight=8;
int sliderSpacing=4;
int dropDownWidth = 80;
int dropDownHeight = sliderHeight;  
int sliderPanelHeight = (prefix.length+2)*(sliderHeight+sliderSpacing)+sliderSpacing;

//controlled by sliders
float isotropyX = PI;
float orientationX = 0.0;
float wavelengthX = 32.0;
float densityX = .02;
float gridSizeX = 2;
float octavesX=1;

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
  
  size(noiseWidth, sliderPanelHeight+noiseHeight, P2D);
 
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
    .setRange(0,100);
  cp5.addSlider("warpY")
    .setPosition(4,7*sliderHeight+8*sliderSpacing)
    .setSize(noiseWidth-100, sliderHeight)
    .setRange(0,100);
    
  cp5.addFrameRate().setInterval(10).setPosition(noiseWidth-20, 90);  
   
  noise = loadShader("noise.glsl");
  buffer=createGraphics(noiseWidth, noiseHeight, P2D);
}


void draw() {
  buffer.shader(noise, POLYGON);
  noise.set("resolution", float(noiseWidth), float(noiseHeight));
  noise.set("gridSize", gridSizeX);
  noise.set("density", densityX);
  noise.set("origin", originX, originY);
  noise.set("offset", offsetX);
  noise.set("harmonic", 1./wavelengthX,
                        octavesX, 
                        orientationX-isotropyX*.5,
                        orientationX+isotropyX*.5);
  noise.set("domainWarp", warpX, warpY);
  
  buffer.beginDraw();
  buffer.background(127);
  buffer.endDraw();
  
  buffer.beginDraw();
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.endDraw();

  buffer.beginDraw();
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.endDraw();
  
  image(buffer, 0, sliderPanelHeight, noiseWidth, noiseHeight);
  
  buffer.resetShader(POLYGON);
  originX--; originY--;
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

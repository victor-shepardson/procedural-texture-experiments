//Gabor noise with domain and harmonic warping
//There are five noise functions:
//  - two each for the domain warping and harmonic warping vector fields
//  - one master noise which is warped by the others
// a single shader renders each function in a separate pass
//  its behavior is controlled by setting the readFlags and writeFlags uniforms below
// performance on intel graphics is pretty wretched, but it does render

//use the dropdown to select a set of gabor parameters to change - D for domain warping, H for harmonic warping, M for main noise
//use the sliders to mess with gabor parameters, number of octaves, and amount of warping
//to get started, leave warping turned off and select M from the dropdown
//the density parameter of gabor noise is available. it trades accuracy for performace, though abuse can create interesting textures as well with low values.
//gridsize as a multiple of wavelength is available as well. It also trades accuracy (specifically, increased bandwidth and artifacts) for performance
//if the density is set to 0 under the D or H dropdowns you won't see any warping

import controlP5.*;

ControlP5 cp5;
PShader noise;
PShader curl;
PGraphics buffer;

//alter these to change the size of the rendered area
int noiseWidth = 512;
int noiseHeight = 256;

String[] prefix =     {"wavelength",  "gridSize",  "isotropy",  "orientation",  "density",   "octaves"};
float [] paramLowerRange = {4,             .25,           0,           0,              0,           1};
float[] paramUpperRange =  {128,           4,             PI,          PI,             16,       6};
String[] paramSuffix = {"D", "M"}; //domain warping, harmonic warping, main noise

int sliderWidth=min(256, noiseWidth-160);
int sliderHeight=8;
int sliderSpacing=4;
int dropDownWidth = 80;
int dropDownHeight = sliderHeight;  
int sliderPanelHeight = (prefix.length)*(sliderHeight+sliderSpacing)+2*sliderSpacing;

//controlled by sliders
float isotropyD = PI;
float orientationD = 0.0;
float wavelengthD = 32.0;
float densityD = 8;
float gridSizeD = 2;
float octavesD=1;

float isotropyM = 0;
float orientationM = 0.0;
float wavelengthM = 64.0;
float densityM = 8;
float gridSizeM = 2;
float octavesM=1;

int offsetX = 0xfeedbeef;
int offsetY = 0xbeefdead;
int offsetZ = 0xabcdabcd;
int offsetM = 0xfabcdabc;

float originX=0;
float originY=0;

void setup() { 
  size(noiseWidth, sliderPanelHeight+noiseHeight, P2D);
 
  cp5=new ControlP5(this); 
  
  DropdownList ddl = 
    cp5.addDropdownList("textureSelect")
    .setPosition(noiseWidth-dropDownWidth-4, sliderSpacing+dropDownHeight)
    .setSize(dropDownWidth, dropDownHeight*(paramSuffix.length+1))
    .setItemHeight(sliderHeight);  
  
  for(int i=0; i<paramSuffix.length; i++){
    ddl.addItem(paramSuffix[i], i);
    for(int j=0; j<prefix.length; j++){
      cp5.addSlider(prefix[j]+paramSuffix[i])
        .setPosition(4,j*sliderHeight+(j+1)*sliderSpacing)
        .setSize(sliderWidth, sliderHeight)
        .setRange(paramLowerRange[j],paramUpperRange[j])
        .setVisible(false);
    }
  }
    
  cp5.addFrameRate().setInterval(10).setPosition(noiseWidth-20, 90);  
   
  buffer= createGraphics(noiseWidth, noiseHeight, P2D);
  noise = buffer.loadShader("noise.glsl");
  curl = buffer.loadShader("curl.glsl");
}


void draw() {
  background(100);
  g.endDraw();
  
  buffer.beginDraw();
  buffer.colorMode(RGB, 1.0);  
  buffer.background(.5);
  buffer.endDraw();
  
  noise.set("resolution", float(noiseWidth), float(noiseHeight));
  noise.set("domainWarp", 0.0);
  noise.set("harmonicWarp", 0.0);
  noise.set("origin", originX, originY);

  noise.set("readFlags", 0.0, 0.0, 0.0, 0.0);
  noise.set("gridSize", gridSizeD);
  noise.set("density", densityD);
  noise.set("harmonic", 1./wavelengthD,
                        octavesD, 
                        orientationD,
                        isotropyD);
  noise.set("offset", offsetX);                      
  noise.set("writeFlags", 1.0, 0.0, 0.0, 0.0);                      
  buffer.beginDraw();
  buffer.shader(noise, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader(POLYGON);
  buffer.endDraw();
  
  noise.set("offset", offsetY);                      
  noise.set("writeFlags", 0.0, 1.0, 0.0, 0.0);                      
  buffer.beginDraw();
  buffer.shader(noise, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader(POLYGON);
  buffer.endDraw();

  noise.set("offset", offsetZ);                      
  noise.set("writeFlags", 0.0, 0.0, 1.0, -1.0);                      
  buffer.beginDraw();
  buffer.shader(noise, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader(POLYGON);
  buffer.endDraw();
  
  curl.set("resolution", float(noiseWidth), float(noiseHeight));
  
  buffer.beginDraw();
  buffer.shader(curl, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader(POLYGON);
  buffer.endDraw();
  
  noise.set("domainWarp", 1000.0);
  noise.set("readFlags", 1.0, 1.0, 0.0, 0.0);
  noise.set("gridSize", gridSizeM);
  noise.set("density", densityM);
  noise.set("harmonic", 1./wavelengthM,
                        octavesM, 
                        orientationM,
                        isotropyM);
  noise.set("offset", offsetM);                      
  noise.set("writeFlags", 1.0, 1.0, 1.0, -1.0);                      
  buffer.beginDraw();
  buffer.shader(noise, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader(POLYGON);
  buffer.endDraw();
  
  
  g.beginDraw();
  image(buffer, 0, sliderPanelHeight, noiseWidth, noiseHeight);
  
  originX--; originY--;
}

void controlEvent(ControlEvent theEvent){
  if(theEvent.isGroup() && theEvent.getGroup().toString().equals("textureSelect [DropdownList]")){
    int curSuffix = int(theEvent.getGroup().getValue());
    for(int i=0; i<paramSuffix.length; i++){
      for(int j=0; j<prefix.length; j++){
        if(i==curSuffix)
          cp5.getController(prefix[j]+paramSuffix[i]).setVisible(true);
        else
          cp5.getController(prefix[j]+paramSuffix[i]).setVisible(false);
      }
    }
  }
}

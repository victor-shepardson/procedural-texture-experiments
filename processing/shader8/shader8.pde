//TODO: gui, fix freq warping
import controlP5.*;

ControlP5 cp5;
PShader noise;
PGraphics buffer;

int noiseWidth = 512;
int noiseHeight = 128;

String[] prefix =     {"wavelength",  "gridSize",  "isotropy",  "orientation",  "density",   "octaves"};
float [] paramLowerRange = {4,             .25,           0,           0,              0,           1};
float[] paramUpperRange =  {128,           4,             PI,          PI,             .0625,       6};
String[] paramSuffix = {"X", "Y", "F", "O", "M"};

String[] warpSuffix =   {"X", "Y", "F", "O"};
float[] warpLowerRange = {0,   0,   1,   0};
float[] warpUpperRange = {100, 100, 4,   4};

int sliderWidth=min(256, noiseWidth-160);
int sliderHeight=8;
int sliderSpacing=4;
int dropDownWidth = 80;
int dropDownHeight = sliderHeight;  
int sliderPanelHeight = (prefix.length+warpSuffix.length)*(sliderHeight+sliderSpacing)+2*sliderSpacing;

//controlled by sliders
float isotropyX = PI;
float orientationX = 0.0;
float wavelengthX = 32.0;
float densityX = .0;
float gridSizeX = 2;
float octavesX=1;

float isotropyY = PI;
float orientationY = 0.0;
float wavelengthY = 32.0;
float densityY = .0;
float gridSizeY = 2;
float octavesY=1;

float isotropyF = PI;
float orientationF = 0.0;
float wavelengthF = 32.0;
float densityF = .0;
float gridSizeF = 2;
float octavesF=1;

float isotropyO = PI;
float orientationO = 0.0;
float wavelengthO = 32.0;
float densityO = .02;
float gridSizeO = 2;
float octavesO=1;

float isotropyM = 0;
float orientationM = 0.0;
float wavelengthM = 8.0;
float densityM = .02;
float gridSizeM = 4;
float octavesM=1;

float warpX=0;
float warpY=0;
float warpF=1;
float warpO=0;

int offsetX = 0xfeedbeef;
int offsetY = 0xbeefdead;
int offsetF = 0xabcdabcd;
int offsetO = 0xcdababcd;
int offsetM = 0x12312312;

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
  for(int i=0; i<warpSuffix.length; i++){
    cp5.addSlider("warp"+warpSuffix[i])
      .setPosition(4,(i+prefix.length)*sliderHeight+(i+2+prefix.length)*sliderSpacing)
      .setSize(sliderWidth, sliderHeight)
      .setRange(warpLowerRange[i],warpUpperRange[i]);
  }
    
  cp5.addFrameRate().setInterval(10).setPosition(noiseWidth-20, 90);  
   
  buffer= createGraphics(noiseWidth, noiseHeight, P2D);
  noise = buffer.loadShader("noise.glsl");
}


void draw() {
  background(100);
  g.endDraw();
  
  buffer.beginDraw();
  buffer.colorMode(RGB, 1.0);  
  buffer.background(.5);
  buffer.endDraw();
  
  noise.set("resolution", float(noiseWidth), float(noiseHeight));
  noise.set("domainWarp", warpX, warpY);
  noise.set("freqWarp", 1.0, warpF);
  noise.set("oWarp", warpO);
  noise.set("origin", originX, originY);

 //X warping
  noise.set("gridSize", gridSizeX);
  noise.set("density", densityX);
  noise.set("offset", offsetX);
  noise.set("harmonic", 1./wavelengthX,
                        octavesX, 
                        orientationX,
                        isotropyX);
  noise.set("writeFlags", 1.0, 0.0, 0.0, 0.0);
  noise.set("readFlags", 0.0, 0.0, 0.0, 0.0);
  buffer.beginDraw();
  buffer.shader(noise, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader(POLYGON);
  buffer.endDraw();
  
  //Y warping
  noise.set("gridSize", gridSizeY);
  noise.set("density", densityY);
  noise.set("offset", offsetY);
  noise.set("harmonic", 1./wavelengthY,
                        octavesY, 
                        orientationY,
                        isotropyY);
  noise.set("writeFlags", 0.0, 1.0, 0.0, 0.0);
  noise.set("readFlags", 0.0, 0.0, 0.0, 0.0);
  buffer.beginDraw();
  buffer.shader(noise, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader(POLYGON);
  buffer.endDraw();
  
  //Frequency warping
  noise.set("gridSize", gridSizeF);
  noise.set("density", densityF);
  noise.set("offset", offsetF);
  noise.set("harmonic", 1./wavelengthF,
                        octavesF, 
                        orientationF,
                        isotropyF);
  noise.set("writeFlags", 0.0, 0.0, 1.0, 0.0);
  noise.set("readFlags", 0.0, 0.0, 0.0, 0.0);
  buffer.beginDraw();
  buffer.shader(noise, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader(POLYGON);
  buffer.endDraw();
  
  //Orientation warping
  noise.set("gridSize", gridSizeO);
  noise.set("density", densityO);
  noise.set("offset", offsetO);
  noise.set("harmonic", 1./wavelengthO,
                        octavesO, 
                        orientationO,
                        isotropyO);
  noise.set("writeFlags", 0.0, 0.0, 0.0, 1.0);
  noise.set("readFlags", 0.0, 0.0, 0.0, 0.0);
  buffer.beginDraw();
  buffer.shader(noise, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader(POLYGON);
  buffer.endDraw();
  
  //Main
  noise.set("gridSize", gridSizeM);
  noise.set("density", densityM);
  noise.set("offset", offsetM);
  noise.set("harmonic", 1./wavelengthM,
                        octavesM, 
                        orientationM,
                        isotropyM);
  noise.set("writeFlags", 1.0, 1.0, 1.0, -1.0);
  noise.set("readFlags", 1.0, 1.0, 1.0, 1.0);
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

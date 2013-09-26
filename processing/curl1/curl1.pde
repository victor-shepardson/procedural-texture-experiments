//TODO: correct flow, obstacles

import controlP5.*;

ControlP5 cp5;
PShader flow;
PShader curl;
PGraphics buffer;

//alter these to change the size of the rendered area
int noiseWidth = 512;
int noiseHeight = 256;

String[] prefix =     {"wavelength",  "gridSize",  "isotropy",  "orientation",  "density",   "octaves"};
float [] paramLowerRange = {4,             .25,           0,           0,              0,           1};
float[] paramUpperRange =  {128,           4,             PI,          PI,             16,       6};
String[] paramSuffix = {"C"}; 

String[] warpSuffix =   {"M"};
float[] warpLowerRange = {0};
float[] warpUpperRange = {10};

int sliderWidth=min(256, noiseWidth-160);
int sliderHeight=8;
int sliderSpacing=4;
int dropDownWidth = 80;
int dropDownHeight = sliderHeight;  
int sliderPanelHeight = (prefix.length+warpSuffix.length)*(sliderHeight+sliderSpacing)+2*sliderSpacing;

//controlled by sliders
float isotropyC = PI;
float orientationC = 0.0;
float wavelengthC = 128.0;
float densityC = 4;
float gridSizeC = 2;
float octavesC=6;

int offsetC = 0xfeedbeef;

float warpM=400;

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
        ;//.setVisible(false);
    }
  }
  
  for(int i=0; i<warpSuffix.length; i++){
    cp5.addSlider("warp"+warpSuffix[i])
      .setPosition(4,(i+prefix.length)*sliderHeight+(i+2+prefix.length)*sliderSpacing)
      .setSize(sliderWidth, sliderHeight)
      .setRange(warpLowerRange[i],warpUpperRange[i]);
  }
  
  cp5.addSlider("ss")
    .setPosition(sliderHeight+100, 100)
    .setSize(100, sliderHeight)
    .setRange(1,4);
    
  cp5.addFrameRate().setInterval(10).setPosition(noiseWidth-20, 90);  
   
  buffer= createGraphics(noiseWidth, noiseHeight, P2D);
  curl = buffer.loadShader("curl.glsl");
  flow = buffer.loadShader("flow.glsl");
}


void draw() {
  background(100);
  g.endDraw();
  
  buffer.beginDraw();
  buffer.colorMode(RGB, 1.0);  
  buffer.background(.5);
  buffer.endDraw();
  
  curl.set("origin", originX, originY);

  curl.set("gridSize", gridSizeC);
  curl.set("density", densityC);
  curl.set("harmonic", 1./wavelengthC,
                        octavesC, 
                        orientationC,
                        isotropyC);
  curl.set("offset", offsetC);                                           
  buffer.beginDraw();
  buffer.shader(curl, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader(POLYGON);
  buffer.endDraw();
  
  flow.set("resolution",float(buffer.width), float(buffer.height));
  flow.set("magnitude", warpM);
  buffer.beginDraw();  
  buffer.shader(flow, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader();
  buffer.endDraw();
 
  g.beginDraw();
  image(buffer, 0, sliderPanelHeight, noiseWidth, noiseHeight);
  
  originX--; originY--;
  //orientationC+=.1;
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
void ss(float m){
  buffer= createGraphics(int(noiseWidth*m), int(noiseHeight*m), P2D);
}

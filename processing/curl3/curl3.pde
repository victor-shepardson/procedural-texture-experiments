import controlP5.*;

ControlP5 cp5;
PShader flow;
PShader curl;
PGraphics buffer;

//alter these to change the size of the rendered area
int noiseWidth = 512;
int noiseHeight = 512;

String[] prefix =     {"wavelength",  "gridSize",  "isotropy",  "orientation",  "density",   "octaves"};
float [] paramLowerRange = {4,             .25,           0,           0,              0,           1};
float[] paramUpperRange =  {512,           4,             PI,          PI,             16,          6};
String[] paramSuffix = {"C"}; 

String[] warpSuffix =   {"M"};
float[] warpLowerRange = {0};
float[] warpUpperRange = {1};

int sliderWidth=min(256, noiseWidth-160);
int sliderHeight=8;
int sliderSpacing=4;
int dropDownWidth = 80;
int dropDownHeight = sliderHeight;  
int sliderPanelHeight = (prefix.length+warpSuffix.length)*(sliderHeight+sliderSpacing)+2*sliderSpacing;

//controlled by sliders
float isotropyC = PI;
float orientationC = 0.0;
float wavelengthC = 200.0;
float densityC = 4;
float gridSizeC = 2;
float octavesC=5;

int offsetC = 0xfeedbeef;

float warpM=0;

float originX=0;
float originY=0;

float scale=1;

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
    .setPosition(sliderWidth+100, 50)
    .setSize(100, sliderHeight)
    .setRange(.25,4)
    .setValue(1);
    
  cp5.addFrameRate().setInterval(10).setPosition(noiseWidth-20, 90);  
   
  buffer= createGraphics(int(scale*noiseWidth), int(scale*noiseHeight), P2D);
  curl = buffer.loadShader("curl.glsl");
  /*g.endDraw();
  buffer.beginDraw();
  buffer.colorMode(RGB, 1.0);  
  buffer.background(0);
  buffer.fill(color(0,0,255));
  buffer.noStroke();
  buffer.rect(100,100,100,100);
  buffer.endDraw();
  g.beginDraw();*/
}

int flag=1;
void draw() {
  background(100);
  g.endDraw();
  if(flag>0){
    flag=0;
    buffer.beginDraw();
    buffer.colorMode(RGB, 1.0);  
    buffer.background(0);
    buffer.fill(color(255));
    buffer.noStroke();
    buffer.ellipseMode(CENTER);
    float rsize=min(buffer.width, buffer.height)/3;
    buffer.ellipse(buffer.width/2,buffer.height/2,rsize, rsize);
    int lines=20;
    float spacing=3;
    for(int line=0; line<lines; line++){
      float linewidth=buffer.width/lines/spacing;
      float linepos=linewidth*spacing*(line+.5);
      buffer.rect(linepos, 0, linewidth, buffer.height);
    }
    buffer.endDraw();
  }
  curl.set("mouse", mouseX*scale, (height-mouseY)*scale);
  curl.set("origin", originX, originY);
  curl.set("resolution",float(buffer.width), float(buffer.height));
  curl.set("gridSize", gridSizeC);
  curl.set("density", densityC);
  curl.set("harmonic", 1./(wavelengthC*scale),
                        octavesC, 
                        orientationC,
                        isotropyC);
  curl.set("offset", offsetC);  
  curl.set("magnitude", warpM);  
  buffer.beginDraw();
  buffer.shader(curl, POLYGON);
  buffer.image(buffer.get(), 0,0,buffer.width, buffer.height);
  buffer.resetShader(POLYGON);
  buffer.endDraw();
 
  g.beginDraw();
  image(buffer, 0, sliderPanelHeight, noiseWidth, noiseHeight);
  //tint(0,0,255);
  
  originX-=.5; originY-=.5;
  orientationC+=.02;
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
void ss(float s){
  scale=s;
  buffer= createGraphics(int(noiseWidth*s), int(noiseHeight*s), P2D);
  flag=1;
}

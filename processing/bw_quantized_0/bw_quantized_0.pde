import java.awt.Frame;
import controlP5.*;

ControlFrame controls;
PShader noise;

int noiseWidth = 512;
int noiseHeight = 256;

//controlled by sliders
float isotropy = PI;
float orientation = 0.0;
float wavelength = 32.0;
float density = 50;
float bandwidth = .5;
float octaves = 1;
float synchronicity = 1;

int offset = 0xfeedbeef;
float originX=-noiseWidth/2;
float originY=-noiseHeight/2;

void updateBuffer(){
  shader(noise);
  float or = orientation;
  float f = 1.0/wavelength;
  float[] bw = {bandwidth, bandwidth*.5, bandwidth*.25, bandwidth*.125, bandwidth*.0625, bandwidth*.03125};
  int[] ds = {0,2,4,6,8,10};
  int[] dl = {2,2,2,2,2,2};
  float[] kf = {f,2*f, f,2*f, f,2*f, f,2*f, f,2*f, f,2*f};
  float[] ko = {or,2*or, or,2*or, or,2*or, or,2*or, or,2*or, or,2*or};
  int[] ka = {0,0, 0,0, 0,0, 0,0, 0,0, 0,0};
  float[] kc = {0,1, 0,0, 0,0, 0,0, 0,0, 0,0};
  noise.set("_bandwidth", bw);
  noise.set("_distStart", ds);
  noise.set("_distLen", dl);
  noise.set("_kernelFrequency", kf);
  noise.set("_kernelOrientation", ko);
  noise.set("_alias", ka);
  noise.set("_cutoff", kc);
  noise.set("_density", density);
  noise.set("_origin", originX, originY);
  noise.set("_offset", offset);
  //noise.set("_sync", synchronicity);
  /*noise.set("_harmonic",
    1.0/wavelength,
    orientation);*/
  originX--; originY--;
  
  rect(0, 0, noiseWidth, noiseHeight);
  resetShader();
}

void setup() { 
  
  controls = addControlFrame("kernel parameters");
  
  size(noiseWidth, noiseHeight, P2D);
  noise = loadShader("noise.glsl");
  
  updateBuffer();
}

void draw() {
  updateBuffer();  
}

ControlFrame addControlFrame(String name){
  Frame f = new Frame(name);
  ControlFrame cf = new ControlFrame(this);
  f.add(cf);
  cf.init();
  f.setTitle(name);
  f.setSize(cf.w,cf.h);
  f.setLocation(100,100);
  f.setResizable(false);
  f.setVisible(true);
  return cf;
}

public class ControlFrame extends PApplet {
  int numSliders = 4;
  int sliderHeight = 8;
  int sliderSpacing = 4;
  int w=512;
  int h=(sliderHeight+sliderSpacing)*numSliders+sliderSpacing+30;
  int sliderLength = w-sliderSpacing-100;
  ControlP5 cp5;
  Object parent;
  public void setup() {
    size(w,h); 
    cp5 = new ControlP5(this);
    int i=0;
    addSlider("bandwidth", 1.0/w, .5, i++);
    addSlider("density", 2*PI, 100, i++);
    addSlider("wavelength", 4, 256, i++);
    addSlider("orientation", 0, 2*PI, i++);
    background(64);
  }
  private void addSlider(String name, float lRange, float uRange, int i){
    cp5.addSlider(name)
      .plugTo(parent, name)
      .setRange(lRange,uRange)
      .setSize(sliderLength, sliderHeight)
      .setPosition(sliderSpacing, i*(sliderHeight+sliderSpacing)+sliderSpacing)
      .update();
  }
  public ControlFrame(Object parent){
    this.parent=parent;
  }
  private ControlFrame(){}
  public void draw(){}
}

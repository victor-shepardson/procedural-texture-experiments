import java.awt.Frame;
import java.util.Arrays;
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
float originX = -noiseWidth/2;
float originY = -noiseHeight/2;

void draw(){
  shader(noise);
  float or = orientation;
  float f = 1.0/wavelength;
  float[] bw = {bandwidth, bandwidth*.5, bandwidth*.25, bandwidth*.125, bandwidth*.0625, bandwidth*.03125};
  float[] bp = {.015625, .03125, .0625, .125, .25, .5};
  float[] kf = {f,2*f,4*f,8*f};
  float[] ko = {or,or,or,or};
  float[] kp = {.4, .3, .2, .1};
  int[] ds = {0,kp.length,2*kp.length,3*kp.length,4*kp.length,5*kp.length};
  int[] dl = {kp.length, kp.length, kp.length, kp.length, kp.length, kp.length};
  float[] frequency = cat(kf, kf, kf, kf, kf, kf);
  float[] orientation = cat(ko, ko, ko, ko, ko, ko);
  DiscreteDist dist = new DiscreteDist(kp);
  int[] alias = cat(dist.alias, dist.alias, dist.alias, dist.alias, dist.alias, dist.alias);
  float[] cutoff = cat(dist.cutoff, dist.cutoff, dist.cutoff, dist.cutoff, dist.cutoff, dist.cutoff);
  noise.set("_bandwidth", bw);
  noise.set("_probability", bp);
  noise.set("_distStart", ds);
  noise.set("_distLen", dl);
  noise.set("_kernelFrequency", frequency);
  noise.set("_kernelOrientation", orientation);
  noise.set("_alias", alias);
  noise.set("_cutoff", cutoff);
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
  float[] p = {.99, 0, 0, 0, .01};
  DiscreteDist dist= new DiscreteDist(p);
  println(dist.p);
  println(dist.alias);
  println(dist.cutoff);
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

public int[] cat(int[] first, int[]... rest){
  int i = 0;
  int n = first.length;
  for(int[] array : rest){
    n+=array.length;
  }
  int[] ret = Arrays.copyOf(first, n);
  int offset = first.length;
  for(int[] array : rest){
    System.arraycopy(array, 0, ret, offset, array.length);
    offset += array.length;
  }
  return ret;
}
public float[] cat(float[] first, float[]... rest){
  int i = 0;
  int n = first.length;
  for(float[] array : rest){
    n+=array.length;
  }
  float[] ret = Arrays.copyOf(first, n);
  int offset = first.length;
  for(float[] array : rest){
    System.arraycopy(array, 0, ret, offset, array.length);
    offset += array.length;
  }
  return ret;
}
public <T> T[] cat(T[] first, T[]... rest){
  int i = 0;
  int n = first.length;
  for(T[] array : rest){
    n+=array.length;
  }
  T[] ret = Arrays.copyOf(first, n);
  int offset = first.length;
  for(T[] array : rest){
    System.arraycopy(array, 0, ret, offset, array.length);
    offset += array.length;
  }
  return ret;
}

//following Walker 1977, compute alis & cutoff for constant-time sampling
//of a discrete distribution p
public class DiscreteDist{
  public int n;
  public float[] p;
  public float[] cutoff;
  public int[] alias;
  public DiscreteDist(float[] p){
    this.p=p;
    n = p.length;
    float nf = n; //probability under uniform distribution
    float[] diff = new float [n];
    cutoff = new float[n];
    alias = new int[n];
    for(int i=0; i<n; i++){
      alias[i] = i;
      cutoff[i] = 0;
      diff[i] = p[i]-1.0/nf; 
    }
    for(int i=0; i<n; i++){
      float take_p=0; float give_p=0;
      int take_idx=0; int give_idx=0;
      //most positive and negative differences
      for(int j=0; j<n; j++){
        float cur = diff[j];
        if(cur < take_p){
          take_p = cur;
          take_idx = j;
        }else if (cur > give_p){
          give_p = cur;
          give_idx = j;
        }
      }
//    if (take_idx == give_idx) {break;}
      alias[take_idx] = give_idx;
      cutoff[take_idx] = take_p * nf + 1.0;
      diff[take_idx] = 0;
      diff[give_idx] = take_p + give_p;
    }
  }
}

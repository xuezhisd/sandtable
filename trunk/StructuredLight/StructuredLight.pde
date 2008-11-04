
/*    http://www.mediamolecule.com/blog/2007/12/10/homebrew-3d-scanner/
 *    http://www.david-laserscanner.com/forum/viewtopic.php?p=1534&sid=84455abad746563ec57604c8d8a14bd7
 *
 *    slidegen.zip (cpp) mm_alex (see above)
 *    fjenett 20071218 (speed-port to processing)
 */

//import processing.opengl.*;
import JMyron.*;

float inc, gX, gY, mX, mY, mdX, mdY, dispX, dispY;
float SET_AVGD = 10.0;
float keystone_correct = -100.0;
int counter;
float numStripes;
JMyron m;

PImage p1, p2, p3, o2, gr, flat, display, slice1, slice2, slice3;
PImage heightMold;
PImage[] imgs;

PFont font;  
BufferedReader input;
PrintWriter output;

float P1 = PI*2.0/3.0;
float P2 = PI*4.0/3.0;

float[][] futureColors = new float[640][480]; //used for blur code
int[][] slicedPix = new int[640][480]; //used for slice code

long waitMillis;
long pauseLength = 15000; //millis
boolean showcam = false;
boolean blur = true; //turning blur false may speed up code

//We start by showing a blank window; windowMode = 0.
//Pressing the spacebar tells the program to scan, setting windowMode = 1.
//Calibration is windowMode = 3;
//WindowMode 4 is height map
int windowMode = 0;
int displayType = 0;
boolean setImage = false;

float[][] corners = new float[4][2];

int AVERAGE_ITER = 1; // blurs the image dumbly this many times (3x3 kernel)
int HOLE_FILL_ITER = 4; // fills in holes and expands boundaries up to this size in pixels 
int MEDIAN_ITER = 4; // median blurs the image to remove outliers. also has a side effect of hole filling (more dumb than hole filler)
int XRES = 640;
int YRES = 480;
int shapeSize = 10;
int level = 0;
int cropValue = 40;

float[][] _wrapphase = new float[YRES][XRES];
float[][] _gamma = new float[YRES][XRES];
float[][] _owrap = new float[YRES][XRES];
float[][] _var = new float[YRES][XRES];
float[][] _ovar = new float[YRES][XRES];
float[][] _dx = new float[YRES][XRES];
float[][] _dy = new float[YRES][XRES];
float[][] heightsMarb = new float[640][480];
float[][][] gradient = new float[640][480][2];

int[][] _isconf = new int[YRES][XRES];
int[][] _unwraporder = new int[YRES][XRES];

java.util.Vector pix;

int idxx=0;

float scalefac = (2.0 / 3.0) * cos( 1.0 / 6.0 * PI );
float friction = .02;

// zscale is related to 1/tan(angle-between-projector-and-camera), so for small angles you need a big zscale and vice-versa
float zscale = -155; 

boolean won = false;
boolean saveImage = true;

int bestx=0;
int besty=0;
float best=0;
float avgd=0,avgdw=0;


String read;



float flatOffset = 0, flatScale = 0;
//float flatOffset = -1.44, flatScale = 84.7;

float minHigh, maxHigh, offset, scalingVal;

public void init()
{
  frame.setUndecorated(true);
  super.init();
}

void setup()
{
    size( 1024,768, P3D);
    //frame.setLocation(0, 0);    
    
    corners[0][0] = 50; corners[0][1] = -40;
    corners[1][0] = width-70; corners[1][1] = 0;
    corners[2][0] =width-10; corners[2][1] = height-40;
    corners[3][0] = 0 + 50; corners[3][1] = height-60;
    slice1 = loadImage("kittens1.gif");
    slice2 = loadImage("puppies2.jpg");
    slice3 = loadImage("lions3.jpg");
    
    
    input = createReader("flat.txt");
    try{
    read = input.readLine();}
    catch(IOException e)
    {println("error, n' stuff");}
    if(read != null)
    {
      flatOffset = float(read);
      println(flatOffset);
      try{
      read = input.readLine();}
      catch(IOException e)
      {println("error, n' stuff");}
      if (read != null)
      {
        flatScale = float(read);
        println(flatScale);
      }
      else
      {
        flatOffset = 0;
        println("no settings loaded");
      }
   }
    else
    {
      println("no flat settings loaded");
    }
    
    font = loadFont("AmericanTypewriter48.vlw");
    gX = 430;
    gY = 350;
    mX = 320;
    mY = 240;
    mdX = 0.0;
    mdY = 0.0;
    shapeSize = 10;
    p1 = new PImage(640, 480);
    p2 = new PImage(640, 480);
    p3 = new PImage(640, 480);
    display = new PImage(640, 480);
    flat = loadImage("flat.png");
    heightMold = loadImage("santafecompressed.png");
    m = new JMyron();
    m.start(640, 480);
    frameRate(30);
    counter = 0;
    //numStripes = 10.0;
    numStripes = 45; //JBT
    inc = TWO_PI / height * numStripes;
    //calcHeights();
}


void draw ()
{
    if (windowMode == 1 || windowMode == 3)
    {
      m.update();
      counter++;
      float sinoffset = (counter % 3) * height / numStripes / 3.0 ;
      for(int y=0; y < height; y++)
      {
        colorMode(RGB, 255);
        stroke((sin((y + sinoffset) * inc ) + 1)/2.0 * 255.0 );
        ///stroke(abs(255-((y+offset)*255.0/(height/(2*numStripes))%510)));
        line (0, y, width, y);
      }
  
      if (counter == 6)
        m.imageCopy(p2.pixels);
      if (counter == 7)
        m.imageCopy(p1.pixels);
      if (counter == 8)
        m.imageCopy(p3.pixels);
      if (counter == 9)
      {
        calcHeights(windowMode == 3);
        counter = 0;
        if (windowMode != 3)
        { 
          setImage = false;
          windowMode = 4;
          waitMillis = millis(); //jbt
        }
        else
          windowMode = 0;
        
        if (saveImage){
        p1.save(savePath("img1.png"));
        p2.save(savePath("img2.png"));
        p3.save(savePath("img3.png"));
        }
      }
    }
   else if (windowMode == 4)
   {
     if (displayType != 3)
       background(0);
     if (!setImage)
     {
       if (displayType == 1) 
       {
        display = heightCompare();
       }
      if (displayType == 0 || displayType == 2)
       {
         //display.copy;
       }
       setImage = true;
     }
   
    long t = millis() - waitMillis;     
    if (t > pauseLength && displayType !=2) windowMode = 1;  //jbt
    
    beginShape();
    if (displayType == 1) {
      texture(display);
      vertex(corners[0][0], corners[0][1], 0, 0);
    vertex(corners[1][0], corners[1][1], width, 0);
    vertex(corners[2][0], corners[2][1], width, height);
    vertex(corners[3][0], corners[3][1], 0, height);
    endShape(CLOSE);
    }
    if (displayType == 0 || displayType == 2) {
      texture(o2);
    vertex(corners[0][0], corners[0][1], 0, 0);
    vertex(corners[1][0], corners[1][1], width, 0);
    vertex(corners[2][0], corners[2][1], width, height);
    vertex(corners[3][0], corners[3][1], 0, height);
    endShape(CLOSE);
    }  
    
    colorMode(RGB, 255);
    fill(color(255,255,255));
    rect(0,40,1.0*t/(1.0*pauseLength) * width,5);
  if (showcam) {
    m.update();
    display = new PImage(m.width(), m.height());
    m.imageCopy(display.pixels);
    image(display, 0,0,m.width()/6, m.height()/6);
  } 
   if (displayType == 2) {
     
     float[][] edgePoints = new float[4][2];
     boolean x1Done = false, x2Done = false;;
     float m=0, n=0, b=0, c=0;
      for (int i=0; i<4; i++)
      {
        float changeFrac = 0;              //This whole bit calculates where the 4 points lie on the new edges.
        if (i%2 == 0)
        {
          changeFrac = mX/o2.width;
        }
        else
        {
          changeFrac = mY/o2.height;
        }
        if (i <=1)
        {
          edgePoints[i][0] = changeFrac * ( corners[(i+1)][0] - corners[i][0]) + corners[i][0];
          edgePoints[i][1] = changeFrac * ( corners[(i+1)][1] - corners[i][1]) + corners[i][1];
        }
        else if (i >= 2)
        {
      
          edgePoints[i][0] = changeFrac * ( corners[i][0] - corners[(i+1)%4][0] ) + corners[(i + 1)%4][0];
          edgePoints[i][1] = changeFrac * ( corners[i][1] - corners[(i + 1)%4][1]) + corners[(i + 1)%4][1];
        }
      }
      
      if(edgePoints[2][0] != edgePoints[0][0])
      {
        m = (edgePoints[2][1]-edgePoints[0][1])/(edgePoints[2][0] - edgePoints[0][0]);
      }
      else
      {
        dispX = edgePoints[0][0];
        m = 0;
        b = 0;
        x1Done = true;
      }
      if(edgePoints[1][0] != edgePoints[3][0])
      {
        n = (edgePoints[3][1]-edgePoints[1][1])/(edgePoints[3][0] - edgePoints[1][0]);
      }
      else if(!x1Done)
      {
        dispX = edgePoints[3][0];
        n = 0;
        c = 0;
        x2Done = true;
      }
      else
      {
        println("You chose parallel lines! Poor choice.");
        dispX = 0;
        dispY = 0;
      }
      if (!x1Done && !x2Done)
      {
        b = (edgePoints[0][1] - m*edgePoints[0][0]);
        c = (edgePoints[1][1] - n*edgePoints[1][0]);
        dispX = (c-b)/(m-n);
        dispY = m*dispX + b; 
      }
      else if (x1Done && !x2Done)
      {
        c = (edgePoints[1][1] - n*edgePoints[1][0]);
        dispY = n*dispX + c;
      }
      else if (!x1Done && x2Done)
      {
        b = (edgePoints[0][1] - m*edgePoints[0][0]);
        dispY = m*dispX + b;
      }
     
    if (!won) {
      fill(100);
      ellipse(dispX, dispY, shapeSize, shapeSize);
      fill(0,0,100);
      rect(gX, gY, 10, 10);
    }
    if (mX >= gX - 10 && mX <= gX + 20 && mY >= gY - 10 && mY <= gY + 20) {
      fill(0,0,0);
      won = true;
      if (shapeSize/2 < width) {
        shapeSize += 5;
        ellipse(mX, mY, shapeSize, shapeSize);
      }
      
    }
    mdX *= (1-friction);
    mdY *= (1-friction);
    if (mX > 0 && mY > 0 && mX < 640 && mY < 480 && !won) {
      mdX += gradient[int(mX)][int(mY)][0]/(4*(abs(mdX) + 1));
      mdY += gradient[int(mX)][int(mY)][1]/(4*(abs(mdY) + 1));
    }
  
    if(!won) {
      mX += mdX;
      mY += mdY;
    }
  }
 }

}





void mouseClicked()
{
  mX = mouseX;
  mY = mouseY;
  mdX = 0;
  mdY = 0;
}

void keyPressed ()
{
    if ( key == '1' )
    {
        zscale += 5;
        println(zscale);
    }
    else if ( key == '2' )
    {
        zscale -= 5;
        println(zscale);
    }

    if ( key == '3' )
    {
        //avgd += .25;
        avgd += .5; //JBT
        println(avgd);
    }
    else if ( key == '4' )
    {
        //avgd -= .25;
        avgd -= .5; //JBT
        println(avgd);
    }
  
    else if ( key == '5')
    {
      keystone_correct += 10;
      println (keystone_correct);
    }
    else if (key == '6')
    {
      keystone_correct -= 10;
      println (keystone_correct);
    }

    if ( key == 'c' && windowMode != 3 )
    {
        windowMode = 3;
    }
    
    /*if (key == 'C') {
        println("Saving min and max heights...");
        absoluteCalibrate();
    }*/
    
    if (key == 'h')
    {
      windowMode = 4;
    }
    /*if ( key == 's' )
    {
        saveAFrame = true;   
    }
    */
    if (key == 'a')
    {
      displayType = (displayType + 1) % 4;
      setImage = false;
    }
    if (key == ' ' && windowMode != 1)
    {
      windowMode = 1;
    }
    if (key == 'j')
    {
      m.settings();
    }
    if (keyCode == LEFT)
    {
      mX -= 10;
      mdX = 0;
      mdY = 0;
    }
    if (keyCode == RIGHT)
    {
      mX += 10;
      mdX = 0;
      mdY = 0;
    }
    if (keyCode == UP)
    {
      mY -= 10;
      mdX = 0;
      mdY = 0;
    }
    if (keyCode == DOWN)
    {
      mY += 10;
      mdX = 0;
      mdY = 0;
    }
      
    if (key == 'u')
    {
      PImage average3 = new PImage(XRES,YRES);
      for (int x=0;x<XRES;x++)
      {
        for (int y=0;y<YRES;y++)
        {
          float avg = 0;
          avg = (red(p1.get(x,y)) + red(p2.get(x,y)) + red(p3.get(x,y)))/3;
          average3.set(x,y,color(avg,avg,avg));
        }
      }
      average3.save(savePath("average.png"));
    }
}

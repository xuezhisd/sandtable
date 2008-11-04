import processing.opengl.*;

int numPatchesX = 640;
int numPatchesY = 480;

//sun coors BAL
float eX = 60;
float eY = 10;
//center and radius of circle about which sun moves
float cX = 60;
float cY = 60;
float cRadius = 50;

float patchSizeX, patchSizeY;
float gWorldLeft = -0.5;
float gWorldRight = numPatchesX + 0.5;
float gWorldTop = -0.5;
float gWorldBottom = numPatchesY + 0.5;

ArrayList flames = new ArrayList();
ArrayList water = new ArrayList();
PImage dem;
Patch[] patches = new Patch[numPatchesX * numPatchesY];

float fuelDensity = .75;
float windVelocityX = 0.307;
float windVelocityY = 0.307;
int[] windDisplay = {
  60,60};
float windDisplayLength = 30;
boolean running = false;
boolean patchesDirty = true;
boolean hillshadeOn = true;
boolean isDragging = false;
boolean snowOn = true;
int N = 0; int E = 1; int S = 2; int W = 3;
int NE = 4; int SE = 5; int SW = 6; int NW = 7;

void setup(){
  size(1024,768, OPENGL);
  // size(1400,1050, OPENGL);
  patchSizeX = width /  (float) (numPatchesX);
  patchSizeY = height / (float)(numPatchesY);
  dem = loadImage("heightmap.png");
  importDrawing(dem);
  frameRate(60);
  smooth();
  setupPatches();
  importElevation(dem);
  if (hillshadeOn) hillshadePatches();
}

void setupPatches(){
  for (int i = 0; i < numPatchesY; i++){
    for (int j = 0; j < numPatchesX; j++){
      patches[i*numPatchesX + j] = new Patch(j,i);
    }
  }
  for (int i = 0; i < numPatchesY; i++){
    for (int j = 0; j < numPatchesX; j++){
      patches[i*numPatchesX + j].setNeighbors();
    }
  }

}

void importElevation(PImage anImage){
  noSmooth();
  PImage scaleDEM = new PImage(numPatchesX, numPatchesY);
  scaleDEM.copy(dem,0,0,dem.width, dem.height, 0,0,numPatchesX, numPatchesY);
  for(int i=0; i<scaleDEM.pixels.length;i++){
    patches[i].mElevation = brightness(scaleDEM.pixels[i]);
  }
  //image(scaleDEM, 0,0, width, height);
  for (int i = 1; i < numPatchesY - 1; i++){
    for (int j = 1; j < numPatchesX - 1; j++){
      patches[i*numPatchesX + j].setSlope();
      patches[i*numPatchesX + j].setAspect();
    }
  }
}

void importDrawing(PImage anImage){
  //image(anImage, 0,0, width, height);
}

void displayPatches(){
  noStroke();
  for (int i=0; i<patches.length;i++){
    patches[i].display();
  }
}

void displaySun() {
  fill(255,255,0);
  ellipse(eX, eY, 15, 15);
}

void displayWind(){
  pushMatrix();
  translate(windDisplay[0],windDisplay[1]);
  fill(50);
  stroke(255,150);
  rectMode(RADIUS);
  ellipse(0,0,120,120);
  ellipse(0,0,60,60);
  scale(windDisplayLength); 
  rotate(atan2(windVelocityY , windVelocityX));
  line(0,0,dist(0,0, windVelocityX, windVelocityY),0);
  translate(dist(0,0, windVelocityX, windVelocityY), 0);
  fill(255,255,0);
  triangle(-.2,-.1,0,0,-.2,.1);
  rectMode(CORNER); // set it back to default
  popMatrix();
}

void redrawPatches(){

}
void reset(){
  running = true;  // will let draw() set to running = false
  for (int i=0; i<flames.size(); i++){
    ( (Flame) flames.get(i)).die();
  }
  water.clear();
  flames.clear();
  //background(0);
  for (int i=0; i<patches.length;i++){
    patches[i].setFuel();
  }
  patchesDirty = true;
  loop();

}

void draw(){
  pushMatrix();
  scale(patchSizeX, patchSizeY);
  translate(0.5,0.5);
  if (patchesDirty) {
    displayPatches();
    patchesDirty = false;
  }

  for (int i=0; i<flames.size(); i++){
    ( (Flame) flames.get(i)).display();
  }
  if (water.size() > 0){  
    for (int i = 0; i<water.size(); i++){

      Water myWater = (Water) water.get(i);
      /* uncomment to not have water trace
       myWater.mPatch.display();
       for (int j = 0; j<8; j++){
       myWater.mPatch.neighborArray[j].display();
       }
       */
      myWater.display();
    }
    int numPatchesToErase = (int) (0.002 * patches.length);
    for (int k = 0; k < numPatchesToErase; k++){
      patches[(int) random(patches.length)].display();
    }
  }
  popMatrix();
  if (flames.size()==0 && water.size() ==0){
    noLoop();
    running = false;
  } 
  displayWind();
  displaySun();
}

void mousePressed(){
  if (mouseButton == RIGHT){
    azimuth = atan2(height / 2 - mouseY, mouseX - width/2);
    hillshadePatches();
    loop();
  } 
  else if (dist(windDisplay[0], windDisplay[1], mouseX, mouseY) < windDisplayLength)  {
    windVelocityX = (mouseX - windDisplay[0]) / windDisplayLength;
    windVelocityY = (mouseY - windDisplay[1]) / windDisplayLength;
    loop();
  }
  else if (dist(eX, eY, mouseX, mouseY) < 10) {
    isDragging = true;
    loop();
  }
  else if (dist(cX, cY, mouseX, mouseY) > 60){
    mouseIgnite();
  }
}
//dragging the sun
void mouseDragged() {
  if (isDragging) {
    float leng = dist(cX, cY, mouseX, mouseY);
    eX = ((mouseX - cX) / leng) * cRadius + cX;
    eY = ((mouseY - cY) / leng) * cRadius + cY;
    println("" + eX + "," + eY);
    loop();
  }
}

void mouseReleased() {
  if (isDragging) {
    azimuth = atan2(cY - eY, eX - cX);
    hillshadePatches();
    isDragging = false;
    loop();  
  }
}

void mouseIgnite(){
  Patch curPatch = getPatch(constrain(mouseX, 0, width) / patchSizeX, constrain(mouseY, 0, height - 1) / patchSizeY);
  curPatch.ignite();
  if (flames.size() > 0){
    running = true; 
    loop();
    redraw();
  }
}

void createWater(){
  for (int i=0; i<2000; i++){
    water.add(new Water(random(numPatchesX), random(numPatchesY)));
  }
  loop();
}

void keyPressed(){
  switch(key) {
    case (' '):
    running = !running;
    if (running) {
      loop();
    } 
    else {
      noLoop();
    }
    break;
    case('i'):
    hillshadeOn = !hillshadeOn;
    patchesDirty = true;
    loop();
    break;
    case('I'):
    hillshadeOn = !hillshadeOn;
    patchesDirty = true;
    loop();
    break;
    case('p'):
    patchesDirty = true;
    loop();
    break;
    case('s'):
    snowOn = !snowOn;
    patchesDirty = true;
    loop();
    break;
    case ('r'):
    reset();
    break;
    case ('R'):
    running = true;
    break;
    case('w'):
    createWater();
  }  
}

Patch getPatch(float anX, float aY){
  return patches[floor(aY) * numPatchesX + floor(anX)];
}


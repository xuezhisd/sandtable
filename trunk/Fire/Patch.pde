class Patch {
  int mX, mY;
  float mElevation;
  color mColor;
  float mHillshade;
  float mFuel;
  float dzdx, dzdy;
  float mSlope;
  float mAspect;
  ArrayList neighbors = new ArrayList();


  Patch(int aX, int aY){
    mX = aX;
    mY = aY;
    mElevation = 0;
    mHillshade = -1;
    setFuel();
  }

  void setFuel(){
    this.mFuel = (random(1) < fuelDensity) ? 1 : 0;
    this.mColor = (mFuel == 1) ? color(0,255,0) : color(0,0,0);
  }

  void ignite(){
    if (mFuel == 1) {
      flames.add(new Flame(mX, mY));
    }
  }

  void display(){
    if (hillshadeOn) {
      colorMode(RGB);
      fill(blendColor(this.getColor(), color(mHillshade, 150), MULTIPLY));
    } 
    else {
      colorMode(HSB);
      fill(this.getColor());
    }
    noStroke();
    pushMatrix();
    translate(mX, mY);
    rectMode(CENTER);
    rect(0,0,1,1);
    popMatrix();
    colorMode(RGB);
  }

  void setNeighbors(){
    // set 8 neighbors
    //NORTH
    if (mY > 0) {
      neighbors.add(patches[(mY - 1) * numPatchesX + mX]);
    }
    //EAST
    if (mX < numPatchesX - 1) {
      neighbors.add(patches[mY * numPatchesX + mX + 1]);
    }
    //SOUTH
    if (mY < numPatchesY - 1) {
      neighbors.add(patches[(mY + 1) * numPatchesX + mX]);  
    }
    //WEST
    if (mX > 0)  {
      neighbors.add(patches[mY * numPatchesX + mX - 1]);
    }
    //NE
    if (mX < numPatchesX - 1 && mY > 0) {
      neighbors.add(patches[(mY - 1) * numPatchesX + mX + 1]);
    }
    //SE
    if (mY < numPatchesY - 1 && mX < numPatchesX - 1) {
      neighbors.add(patches[(mY + 1) * numPatchesX + mX + 1]);
    }
    //SW
    if (mY < numPatchesY - 1 && mX > 0) {
      neighbors.add(patches[(mY + 1) * numPatchesX + mX - 1]);
    }
    //NW
    if (mY > 0 && mX > 0) {
      neighbors.add(patches[(mY - 1) * numPatchesX + mX - 1]);
    }
    //neighborArray = neighbors.toArray();
  }

  String toString(){
    return "Patch: " + mX + " " + mY + " fuel:" + mFuel + " color:" + mColor + " elevation:" + mElevation;
  }


  void setSlope(){
    this.dzdx = ((((Patch)neighbors.get(NE)).mElevation + 2 * ((Patch)neighbors.get(E)).mElevation + ((Patch)neighbors.get(SE)).mElevation) - (((Patch)neighbors.get(NW)).mElevation + 2 * ((Patch)neighbors.get(W)).mElevation + ((Patch)neighbors.get(SW)).mElevation)) / 8;
    this.dzdy = ((((Patch)neighbors.get(SW)).mElevation + 2 * ((Patch)neighbors.get(S)).mElevation + ((Patch)neighbors.get(SE)).mElevation) - (((Patch)neighbors.get(NW)).mElevation + 2 * ((Patch)neighbors.get(N)).mElevation + ((Patch)neighbors.get(NE)).mElevation)) / 8;
    this.mSlope = atan(sqrt(this.dzdx * this.dzdx + this.dzdy * this.dzdy));
  }

  void setAspect(){
    if (this.dzdx != 0) {
      this.mAspect = atan2(dzdy, -dzdx);
      if (this.mAspect < 0) {
        this.mAspect += 2 * PI;
      }
    }
    else {
      if (this.dzdy > 0) {
        this.mAspect = PI / 2;
      }
      else if (this.dzdy < 0) {
        this.mAspect = 2 * PI - PI / 2;
      }
    }
  }



  color getColor(){
    if (snowOn) {
      colorMode(RGB);
      if (mHillshade == -1) return color(0);
      //snow
      if (mElevation > 160 && abs(mAspect) < PI) return color(255,255,255);
      // too steep for vegetation, return brown
      if (mSlope > 1.2) return color(255,155,0);
      // below tree line and facing south, add vegetation green
      if (abs(mAspect) > 0.8 * PI && mElevation < 150) return color(0,255,0);
      // slope is flat and below treeline
      if (mSlope < .8 && mElevation < 150) return color(0,255,0);
      // return brown for everything else
      return  color(255,155,0);
    }
    else {
      colorMode(HSB);
      return color(mElevation,255,255);
    }
  }
}

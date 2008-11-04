

class Flame {

  int mAge;
  //float mHeading;
  float mVelocity;
  float mX, mY;
  float mVX, mVY;
  color mColor;
  float mSize;

  Patch mPatch; 

  Flame(float xPos, float yPos){
    mSize = random(2);
    mAge = 0;
    mX = xPos;
    mVelocity = 0;
    mY = yPos; 
    mColor = color(255, 255, 0, 200);
    mPatch = getPatch(mX, mY);
    mPatch.mFuel = 0;
  }

  public void step(){
    mAge++;

    if (mAge > 4) {
      this.mColor = color(100 + norm(mAge, 75, 4) * 155,0,0);
    }
    if (mAge == 3){
      for (int i=0; i<this.mPatch.neighbors.size();i++){
        Patch tPatch = (Patch) this.mPatch.neighbors.get(i);
        if (tPatch.mFuel > 0){
          float slope = tPatch.mElevation - this.mPatch.mElevation;
         if (0.50 * random(1) < (.2 + 0.4 * windVelocityX * (tPatch.mX - mX) + 0.4 * windVelocityY * (tPatch.mY - mY) + 0.2 * slope / 2) ){ 
            ((Patch) this.mPatch.neighbors.get(i)).ignite();         
          }          
        }
      }
    }

    if (mAge == 75) {
      this.die();
    }
  }

  void die(){
    this.mPatch = null;
    flames.remove(flames.indexOf(this));
  }
  String toString(){
    return "Flame: x:" + mX + " y:" + mY; 
  }

  public void display(){
    if (!isDragging) {
    this.step();
    }
    fill(mColor,200);
    pushMatrix();
    translate(mX, mY);
    noStroke();
    rectMode(CORNERS);
    rect(0,0,1,1);
    popMatrix();
  }
}

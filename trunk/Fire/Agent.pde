class Agent {
  int mAge;
  float mHeading;
  //float mVelocity;
  float mX, mY;
  float mVX, mVY;
  color mColor;
  float mSize;
  Patch mPatch;
  
  Agent (float xPos, float yPos){
    this.mSize = random(6);
    this.mAge = 0;
    this.mX = xPos;
    //this.mVelocity = 0;
    this.mY = yPos; 
    this.mColor = color(255, 255, 0, 200);
    this.mPatch = getPatch(mX, mY);
  }
}

// toDo

class Water extends Agent {
  Water (float xPos, float yPos){
    super(xPos, yPos);
    this.mAge = (int) random(width); //we reset water to random points based on age
    colorMode(HSB,1.0);
    //set color a random color between cyan to blue
    this.mColor = color(.55 + random(.20), 1,1);
    colorMode(RGB,255);
  }


  void step(){
    this.mAge++;
    // face downhill
    this.mHeading = this.mPatch.mAspect;
    // move forward
    this.mVX = -.2 * this.mPatch.dzdx;
    this.mVY = -.2 * this.mPatch.dzdy;
    if (this.mVX == 0 && this.mVY == 0){
      float myJiggleAmt = 1.0;
      this.mVX = random(-myJiggleAmt, myJiggleAmt);
      this.mVY = random(-myJiggleAmt, myJiggleAmt);
    }
    this.mX += this.mVX;
    this.mY += this.mVY;
    if (this.mAge > width || this.mX < 1 || this.mY < 1 || this.mX > numPatchesX - 1 || this.mY > numPatchesY - 1 ) {
      this.mAge = 0;
      this.mX = random(numPatchesX);
      this.mY = random(numPatchesY);

    }
    this.mPatch = getPatch(this.mX, this.mY);
  }

  //refactor translate and rotate to the world before step is called.
  void display(){
    if (!isDragging) {
      this.step();
    }
    fill(this.mColor,100);
    pushMatrix();
    translate(this.mX, this.mY);
    rotate(this.mHeading);
    //stroke(this.mColor);
    noStroke();
    rectMode(CENTER);
    rect(0,0,1.25,1.25);
    stroke(0, 100);
    strokeWeight(0.5);
    line(0,0,.5,0);
    popMatrix();
  }

}

float zenith = PI / 4;
float azimuth = PI / 2;

void hillshadePatches() {
  for (int i = 1; i < numPatchesY - 1; i++){
    for (int j = 1; j < numPatchesX - 1; j++){
      Patch aPatch = patches[i*numPatchesX + j];
      aPatch.mHillshade = 255.0 * ((cos(zenith) * cos(aPatch.mSlope)) + (sin(zenith) * sin(aPatch.mSlope) * cos(azimuth - aPatch.mAspect)));
    }
  }
  patchesDirty = true;
}

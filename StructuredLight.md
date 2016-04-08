## Introduction ##

How to use Structured Light

  1. load StructuredLight.pde in Process (http://www.processing.org)
  1. run full screen
  1. point projector at a non-glossy / non-reflective surface.
  1. place camera about below projector
> > the angle offset should be around 15-20 degrees
  1. if this is the first time running, flatten the surface and press "c" to calibrate
  1. press spacebar to scan
  1. press "a" key to change modes
    * normal scan
    * relative difference to known USGS heightmap
    * downhill ball roller
    * layer reveal based on height. Currently Kittens, Puppies and Lions, oh my
  1. manipulate the sand surface


## Details ##

Many details need to be filled in. Here's some blurb from our initial project page at
http://www.sandtable.org/structuredLight/index.html:

Steps to making a 3D scanner:

  1. generate a sinusoidal grayscale banded image in Processing or any graphics application. The pixels brightness will look like:
> > pixelBrightness = cos(y) `*` 128.0 + 128
  1. Project the striped image three times on 3D subject. Scroll the image 1/3 of the width of a stripe (120 degrees) each time. Capture images with a webcam placed above projector. (Place webcam to the side of projector if using vertical stripes)
> > Here's our undocumented Processing sketch that creates these stripes and offsets.
  1. Average all three striped images together into one image. This will be used as a texture map on the 3D model to be generated next.
  1. For each pixel in image, infer the phase shifts in grayscale images based on intensity ratio calculations as described in the paper Zhang and Huang (2006) below. From the phase shifts, one can triangulate the z-values for each pixel. A full Implementation of algorithm is available in Processing by Florian (fjenett). Florian's code assumes the 3 striped images are already availabe in the "data" folder.
> > View the 3D applet in your browser
  1. Come to the Santa Fe Complex to figure out what we can combine this with to make something fun!

## References and Credits: ##

Song Zhang's PhD Thesis, "High-resolution, Real-time 3-D Shape Measurement"

Zhang and Huang (2006) "High-resolution, real-time three-dimensional shape measurement" Optical Engineering

implemented C++ code by Alex at MediaMolecule
translated to Processing by fjenett

Modified May 1, 2008 at Redfish Group by Stephen Guerin, Ben Goldsmith, Ben Lichtner, Shawn Barr and Simon Mehalek. Additional thanks to Carl Diegert and Roger Critchlow.

Earlier sandtable explorations performed by Stephen Guerin and Joshua Thorp.
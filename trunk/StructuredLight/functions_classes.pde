void calcHeights(boolean calibrate)
{

    // input images must be XRES,YRES res color RGB png files
    //p2 = loadImage("image1.png");
    //p1 = loadImage("image2.png");
    //p3 = loadImage("image3.png");
    gr = new PImage(p1.width, p1.height);
    o2 = new PImage(p1.width, p1.height);

    for (int y=cropValue;y<YRES-cropValue;++y)
    {
        for (int x=cropValue;x<XRES-cropValue;++x)
        {
            float fix=0;
            float fixhi=0;

            float ph1=((p1.get(x,y) & 255)/255.0-fix)/(1.0-fix-fixhi);
            float ph2=((p2.get(x,y) & 255)/255.0-fix)/(1.0-fix-fixhi);
            float ph3=((p3.get(x,y) & 255)/255.0-fix)/(1.0-fix-fixhi);
            if (ph1<0) ph1=0;
            if (ph2<0) ph2=0;
            if (ph3<0) ph3=0;
            /*ph1=ph1*ph1;		ph2=ph2*ph2;		ph3=ph3*ph3;
             ph1=sqrtf(ph1);		ph2=sqrtf(ph2);		ph3=sqrtf(ph3);*/
            //float colo;
            float idash = (ph1+ph2+ph3) + 0.5f/255.0;
            float iddash = max( max(ph1,ph2), ph3 ) - min( min(ph1,ph2), ph3 );
            float gamma = iddash/(idash+0.4)*2;

            if (gamma<0.2) gamma = 0;

            float r = unwrapphase( ph1, ph2, ph3, x+y*p1.width );

            _wrapphase[y][x] = r;
            _gamma[y][x]=gamma;

        }
    }


    for (int y=cropValue;y<YRES-cropValue;++y)
    {
        for (int x=cropValue;x<XRES-cropValue;++x)
        {
            int k=0; // this sets the kernel size for the variance map
            int x1=x-k;
            int y1=y-k;
            int x2=x+k+1;
            int y2=y+k+1;

            if (x1<0) x1=0;
            if (y1<0) y1=0;
            if (x2>XRES) x2=XRES;
            if (y2>YRES) y2=YRES;
            float dx=0,dy=0,dx2=0,dy2=0,w=0;

            for (int yy=y1;yy<y2;++yy)
            {
                for (int xx=x1;xx<x2;++xx)
                {
                    //if (_gamma[yy][xx]>0) {
                    float _w=1;//_gamma[yy][xx];
                    w+=_w;
                    dx+=_w* _dx[yy][xx];
                    dx2+=_w* _dx[yy][xx]*_dx[yy][xx];
                    dy+=_w* _dy[yy][xx];
                    dy2+=_w* _dy[yy][xx]*_dy[yy][xx];
                    // }
                }
            }

            if (w == 1)
            {
                dx/=w;
                dy/=w;
                dx2/=w;
                dy2/=w;
            }

            dx=dx*dx;
            dy=dy*dy;

            if (dx2<dx)
            {
                int i=1;
            }

            float var = 1.0 / ( 1+ 200*( (dy2-dy)+(dx2-dx) ) ); //_gamma[y][x]
            // this seems to allways be 1.0 ..? 

            if (_gamma[y][x]==0) var=0;

            _var[y][x]=var;
            _ovar[y][x]=var;

            float d = sqrt(dx+dy);

            avgdw += var;
            avgd += var*d;

            float cdx=(x/float(XRES-40))-0.5f;
            float cdy=(y/float(YRES-40))-0.5f;

            float cen = var*(1-sqrt(cdx*cdx+cdy*cdy));

            if (cen>best)
            {
                best=cen;
                bestx=x;
                besty=y;
            }
        }
    }

    //bestx=XRES/2; besty=YRES/2;
    //println( avgd );
    //println( avgdw );
    avgd = avgdw / avgd; // fudge the 2.1 if the output mesh appears to be skewed along z

    // trial'n'error value .. not sure why it's not set correctly
    avgd = SET_AVGD;

    // avgd is now the average size (in pixels) of one complete 'fringe' wrap.

    pix = new Vector();
    pix.add(  new int[]{  //new Float(-_var[besty][bestx]),
        bestx,besty                } 
    );
    _var[besty][bestx] = -1;

    while ( !pix.isEmpty() )
    {
        // unwrap & insert n/e/s/w if their _var is >0; set their _var to -1 as we do so to avoid revisiting.

        int[] xy = (int[])pix.remove(0);
        int x = xy[0];
        int y = xy[1];

        float r = _wrapphase[y][x];

        if (y>0 && _var[y-1][x]>0)
        {
            unwrap(r,x,y-1);
        }

        if (y<YRES-1 && _var[y+1][x]>0)
        {
            unwrap(r,x,y+1);
        }
        if (x>0 && _var[y][x-1]>0)
        {
            unwrap(r,x-1,y);
        }

        if (x<XRES-1 && _var[y][x+1]>0)
        {
            unwrap(r,x+1,y);
        }

        //if (idxx>10000) { println("break! ("+pix.size()+")"); break; }
    }


    // hole fill
    for (int iter=0;iter<HOLE_FILL_ITER;++iter)
    {
        for (int y=21;y<YRES-21;++y)
            for (int x=21;x<XRES-21;++x)
            {
                if (_var[y][x]>=0)
                {
                    // is this a hole?
                    boolean gotx=false,goty=false;
                    float rx=0,ry=0;
                    if (_var[y][x-1]==-1 && _var[y][x+1]==-1)
                    {
                        gotx=true;
                        rx=(_wrapphase[y][x-1]+_wrapphase[y][x+1])*0.5;					
                    }
                    else if (_var[y][x-1]==-1 && x>=2 && _var[y][x-2]==-1)
                    {
                        rx=_wrapphase[y][x-1]*2-_wrapphase[y][x-2];
                        gotx=true;
                    }
                    else if (_var[y][x+1]==-1 && x<XRES-42 && _var[y][x+2]==-1)
                    {
                        rx=_wrapphase[y][x+1]*2-_wrapphase[y][x+2];
                        gotx=true;
                    }

                    if (_var[y-1][x]==-1 && _var[y+1][x]==-1)
                    {
                        goty=true;
                        ry=(_wrapphase[y-1][x]+_wrapphase[y+1][x])*0.5;
                    }
                    else if (_var[y-1][x]==-1 && y>=2 && _var[y-2][x]==-1)
                    {
                        ry=_wrapphase[y-1][x]*2-_wrapphase[y-2][x];
                        goty=true;
                    }
                    else if (_var[y+1][x]==-1 && y<YRES-42 && _var[y+2][x]==-1)
                    {
                        ry=_wrapphase[y+1][x]*2-_wrapphase[y+2][x];
                        goty=true;
                    }

                    float r=0;
                    if (gotx) r+=rx; 
                    if (goty) r+=ry;
                    if (gotx && goty) r*=0.5;
                    if (gotx || goty)
                    {
                        _var[y][x]=-2;
                        _wrapphase[y][x]=r;
                    }
                }
            }
        for (int y=21;y<YRES-21;++y)
            for (int x=21;x<XRES-21;++x)
            {
                if (_var[y][x]==-2) _var[y][x]=-1;
            }
    }
   maxHigh = -1000;
   minHigh = 1000;
   offset = 0;
   scalingVal = 1;
   float[][] heights = new float[YRES][XRES];
   for (int y=cropValue;y<YRES-cropValue;++y)
   {
     for (int x=cropValue;x<XRES-cropValue;++x)
     {
       float planephase = 0.5-(y-besty)/avgd;
       float flatFactor = (255-red(flat.get(x, y)))/flatScale + flatOffset;
       if (calibrate) flatFactor = 0;
       heights[y][x] = _wrapphase[y][x]-planephase-flatFactor;
       if (heights[y][x] > maxHigh)
         maxHigh = heights[y][x];
       if (heights[y][x] < minHigh)
         minHigh = heights[y][x];
     }
   }
   println(heights[470][320] + ", " + heights[240][320]);
   offset = minHigh;
   if (!calibrate) scalingVal = 255.0/(.7024 - -0.4963);
   else scalingVal = 255.0/(maxHigh - minHigh);
   println(minHigh + "," + maxHigh + "," + scalingVal);
   for (int y=cropValue;y<YRES-cropValue;++y)
    {
        for (int x=cropValue;x<XRES-cropValue;++x)
        {
            float planephase = 0.5-(y-besty)/avgd;
            
            //if (_var[y][x]>=0) _wrapphase[y][x]=-1000;
            //o2.set( x, y, v4_to_u32( new v4( ((_wrapphase[y][x]-planephase)*0.1+0.2) , _owrap[y][x] , frac(_unwraporder[y][x]/float(idxx)) , 1 ) ) );
      
            int h = 255 - int((heights[y][x] - offset)*scalingVal);
            color c;
            if (!calibrate)
            {
               colorMode(HSB);
               c = color(h, 255, 255);
            }
            else
            {
              colorMode(RGB);
              c = color(h, h, h);
            }
            
            //color c = color(h, h, h);
            o2.set(x, y, c);
            /* if (_var[y][x]==-1)
             {
             _isconf[y][x] = ++idx;
             fout += "v " + float(x) + " " + -float(y) + " " + ((_wrapphase[y][x]-planephase)*zscale)+"\n";
             }
             */
        }
    }
    //blur code
    if (blur && !calibrate) {
      for (int x = cropValue; x < XRES - cropValue; x++) {
        for (int y = cropValue; y < YRES - cropValue; y++) {
          for (int z = -5; z < 5; z++) {
              futureColors[x - cropValue][y - cropValue] += (hue(o2.get(x, y + z)));
          }
          futureColors[x - cropValue][y - cropValue] /= 11; //generating values of colors-to-be with equal waits to z neighbors above, z nbours below, and self
        }
      }
      colorMode(HSB);
      for (int x = cropValue; x < XRES - cropValue; x++) {
        for (int y = cropValue; y < YRES - cropValue; y++) {
          color c = color(futureColors[x- cropValue][y - cropValue], 255, 255);
          o2.set(x,y,c); //applying the colors-to-be
        }
      }
    }
    if (displayType == 2) {
      for (int x = 0; x < o2.width; x++) {
       for (int y = 0; y < o2.height; y++) {
         colorMode(HSB,100);
         heightsMarb[x][y] = hue(o2.get(x,y)); 
       }
     }
     gradient = calcGrad(heightsMarb);
    }
    if (displayType == 3) {
      loadPixels();
      for (int x = cropValue; x < XRES - cropValue; x++) {
        for (int y = cropValue; y < YRES - cropValue; y++) {
          if (hue(o2.get(x,y)) < 85) {
            slicedPix[x][y] = slice1.get(x, y);
          }
          else if (hue(o2.get(x,y)) < 145) {
            slicedPix[x][y] = slice2.get(x, y);
          }
          else {
            slicedPix[x][y] = slice3.get(x, y);
          }
        }
      }
      for (int x = 0; x < 1024; x++) {
        for (int y = 0; y < 768; y++) {
          pixels[y*width + x] = slicedPix[int(x/2)][int(y/2)];
          //color c = color(red(slicedPix[x][y]), green(slicedPix[x][y]), blue(slicedPix[x][y]));
          //o2.set(x, y, c);
        }
      }
    updatePixels();  
    }
    
    if (!calibrate)
    {
      o2.save(savePath("img_o2.png"));
    }
    else
    {
      println(offset + ", " + scalingVal);
      o2.save(savePath("flat.png"));
      flat = o2;
      
      calibrate = false;
      flatOffset = offset;
      flatScale = scalingVal;
      
      output = createWriter("flat.txt");
      output.println(flatOffset);
      output.println(flatScale);
      output.flush();
      output.close();
      
      background(0);
      textFont(font, 32);
      textAlign(CENTER, CENTER);
      text("Calibration complete\n Press space to scan", width/2, height/2);
    }
    int idx=0;
    String fout = "";
}
float[][][] calcGrad(float[][] hMap)
{
  float[][][] retGrad = new float[640][480][2];
  for (int x = cropValue; x < XRES - cropValue; x++)
  {
    for (int y = cropValue; y < YRES - cropValue; y++)
    {
      if (x != XRES-cropValue-1 && y!= YRES-cropValue-1)
      {
        retGrad[x - cropValue][y - cropValue][0] = hMap[x-cropValue+1][y-cropValue] - hMap[x-cropValue][y-cropValue];
        retGrad[x - cropValue][y - cropValue][1] = hMap[x-cropValue][y-cropValue+1] - hMap[x-cropValue][y-cropValue];
      }
      else
      {
        retGrad[x-cropValue][y-cropValue][0] = 0;
        retGrad[x-cropValue][y-cropValue][1] = 0;
      }
    }
  }
  return retGrad;
  
}

PImage heightCompare()
{
  PImage display = new PImage(640,480);
  for (int x=cropValue;x<XRES - cropValue;++x)
       {
         for (int y=cropValue;y<YRES - cropValue;++y)
         {
           colorMode(RGB);
           float h1 = red(heightMold.get(x, y));
           colorMode(HSB, 255);
           float h2 = 255 - hue(o2.get(x,y));
           float hdiff = (h1-h2 + 255)/2;
           color c = color(0,0,0);
           //abs(128-hdiff)*1.5 + 64  
           if (abs(128-hdiff) < 7)
             c = color(int(hdiff + 40), 255, 255);
           else if (hdiff < 121)
             c = color(hdiff*(42.5/121), 255, 255);
           else if (hdiff > 135)
             c = color(hdiff*(64/121) + 64, 255, 255);
           display.set(x, y, c);
         }
       }
       return display;
}

float unwrapphase(float ph1, float ph2, float ph3, int indx )
{
    // unwrap phase
    // 6 sections:  (biggest to smallest)
    //     MAX  MED  MIN
    // 0 = ph1, ph3, ph2
    // 1 = ph3, ph1, ph2
    // 2 = ph3, ph2, ph1
    // 3 = ph2, ph3, ph1
    // 4 = ph2, ph1, ph3
    // 5 = ph1, ph2, ph3
    int N;
    float minph = min(ph1,min(ph2,ph3));
    float maxph = max(ph1,max(ph2,ph3));
    float medph;
    if (maxph==ph1 && minph==ph2)
    {
        N=0;
        medph=ph3;
    } 
    else if (maxph==ph3 && minph==ph2)
    {
        N=1;
        medph=ph1;
    } 
    else if (maxph==ph3 && minph==ph1)
    {
        N=2;
        medph=ph2;
    } 
    else  if (maxph==ph2 && minph==ph1)
    {
        N=3;
        medph=ph3;
    } 
    else if (maxph==ph2 && minph==ph3)
    {
        N=4;
        medph=ph1;
    } 
    else // max==ph1, min==ph3	
    {
        N=5;
        medph=ph2;
    }
    
    float r=(medph-minph)/(maxph-minph+0.0001f);

    // correct for sinwavey-ness
    if (r < 1) 
        r = -0.5 - 0.5 / PI * ( 6.0 * atan( scalefac * ( 1+r ) / ( r-1 ) ) );

    if ( (N & 1) == 1 ) // every uneven 
        r = -r;

    r = (2 * ((N+1) / 2) + r);

    gr.pixels[indx] = color( (ph1+ph2+ph3) / 3.0 * 255 );

    return r/6.0;
}

int v4_to_u32 ( v4 vec )
{
    int r=int(vec.x*255.f+0.5f);
    int g=int(vec.y*255.f+0.5f);
    int b=int(vec.z*255.f+0.5f);
    int a=int(vec.w*255.f+0.5f);
    if (r<0) r=0; 
    else if (r>255) r=255;
    if (g<0) g=0; 
    else if (g>255) g=255;
    if (b<0) b=0; 
    else if (b>255) b=255;
    if (a<0) a=0; 
    else if (a>255) a=255;
    return (r<<0) | (g<<8) | (b<<16) | (a<<24);
}

class v4 {
    float x,y,z,w;

    v4 (float _x, float _y, float _z, float _w)
    {
        x = _x; 
        y = _y; 
        z = _z; 
        w = _w;
    }   
}

float frac(float f)
{
    return f-floor(f);
}

//#define IDX(x,y) _isconf[y][x],_isconf[y][x]
int[] IDX (int x, int y)
{
    return new int[]{ _isconf[y][x],_isconf[y][x] };
}

void unwrap( float r, int x, int y )
{
    float myr = _wrapphase[y][x] - frac(r);
    //if (myr>0.5 && myr<0.75) return;
    //if (myr<-0.5 && myr>-0.75) return;
    if (myr >  0.5f)
        myr -= 1.f;
        
    if (myr < -0.5f)
        myr += 1.f;
        
    _wrapphase[y][x] = myr + r;
    _unwraporder[y][x] = idxx++;

    pix.add( new int[]{x,y} );
    _var[y][x]=-1;
}

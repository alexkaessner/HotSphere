/**
 * Track2Mouse
 * This sketch translates the tracking data of the HotBox into a mouse input
 *
 * It uses the OpenCV for Processing library by Greg Borenstein
 * https://github.com/atduskgreg/opencv-processing
 * 
 * @author: Kevin Schiffer @kschiffer
 * @modified: 13/09/2014
 * 
 * University of Applied Sciences Potsdam, 2014
 */
 
int gameMode = 0;
boolean mouseInput = true; 
import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;

int i;
float a;
float s;
int r;
float[][] values = new float[1280/3][3];

OpenCV opencv;
Capture video;
PImage src, preProcessedImage, processedImage, contoursImage;
ArrayList<Contour> contours;

float contrast = 1.35;
int brightness = 0;
int threshold = 75;
boolean useAdaptiveThreshold = false; // use basic thresholding
int thresholdBlockSize = 489;
int thresholdConstant = 45;
int blobSizeThreshold = 20;
int blurSize = 4;
PImage levelImage;

int xInc;
int yInc;

void setup() {
  if (!mouseInput){
  frameRate(25);

  video = new Capture(this, 640, 480);
  //video = new Capture(this, 640, 480, "USB2.0 Camera");
  video.start();

  opencv = new OpenCV(this, 1024, 576);
  contours = new ArrayList<Contour>();

  size(opencv.width, opencv.height, P2D);
  } else {
    size(1024,576);
  }
  background(0);
  gameMode = 0;
  drawLevel();
  save("level.tif");
}

void draw() {

  if (mouseInput){
    xInc = mouseX;
    yInc = mouseY;
  }
  
  //////////
  // MENU //
  //////////
  if (gameMode == 0){
    background(0);
    textSize(32);
    fill(255,255,255);
    text("MENU", width/2, 40);
    if (xInc > 0) {
      arc(80, 80, 80, 80, 0, (height / yInc)*PIE, PIE);
    }
  }
  
  ////////////
  // INGAME //
  ////////////
  if (gameMode == 1){
    levelImage = loadImage("level.tif");
    image(levelImage,0,0);
    if (get(xInc,yInc) != -1) {
      println("GAME OVER");
    } else {
      println("good!");
    }
  }
  
    fill(255,0,0);
    stroke(255);
    ellipse(xInc,yInc,20,20);

}

/////////////////////
// Display Methods
/////////////////////

void displayImages() {

  pushMatrix();
  //scale(1);
  //image(src, 0, 0);
  popMatrix();

  stroke(255);
  fill(255);
  rect(0,0,width,height);

}

void drawLevel(){
  for (int i = 0; i < width/3;i++){
    a = a + random(-40,40);
    if (a < -(height/2) + s){
      a = a + random(0,40);
    }
    if (a > height/2 - s){
      a = a + random(-40,0);
    }
    s = random(30,60);
    values[i][0] = i;
    values[i][1] = height/2+a;
    values[i][2] = s;
    //println(i +": "+ values[1]);
    ellipse(values[i][0]*3,values[i][1],values[i][2],values[i][2]);
  }
  filter(BLUR,10);
  filter(THRESHOLD,0.3);
}

void trackPosition(){
  // Read last captured frame
  if (video.available()) {
    video.read();
  }

  // Load the new frame of our camera in to OpenCV
  opencv.loadImage(video);
  src = opencv.getSnapshot();

  ///////////////////////////////
  // <1> PRE-PROCESS IMAGE
  // - Grey channel 
  // - Brightness / Contrast
  ///////////////////////////////

  // Gray channel
  opencv.gray();

  //opencv.brightness(brightness);
  opencv.contrast(contrast);

  // Save snapshot for display
  preProcessedImage = opencv.getSnapshot();

  ///////////////////////////////
  // <2> PROCESS IMAGE
  // - Threshold
  // - Noise Supression
  ///////////////////////////////

  // Adaptive threshold - Good when non-uniform illumination
  if (useAdaptiveThreshold) {

    // Block size must be odd and greater than 3
    if (thresholdBlockSize%2 == 0) thresholdBlockSize++;
    if (thresholdBlockSize < 3) thresholdBlockSize = 3;

    opencv.adaptiveThreshold(thresholdBlockSize, thresholdConstant);

    // Basic threshold - range [0, 255]
  } else {
    opencv.threshold(threshold);
  }

  // Invert (black bg, white blobs)
  opencv.invert();

  // Reduce noise - Dilate and erode to close holes
  opencv.dilate();
  opencv.erode();

  // Blur
  opencv.blur(blurSize);

  // Save snapshot for display
  processedImage = opencv.getSnapshot();

  ///////////////////////////////
  // <3> FIND CONTOURS  
  ///////////////////////////////

  // Passing 'true' sorts them by descending area.
  contours = opencv.findContours(true, true);

  // Save snapshot for display
  contoursImage = opencv.getSnapshot();

  // Draw
  pushMatrix();

  // Display images
  //displayImages();

  // Display contours in the lower right window
  pushMatrix();

  //displayContours();
  displayContoursBoundingBoxes();

  popMatrix(); 
  popMatrix();
}

void displayContours() {

  for (int i=0; i<contours.size (); i++) {

    Contour contour = contours.get(i);

    noFill();
    stroke(0, 255, 0);
    strokeWeight(3);
    //contour.draw();
  }
}

void displayContoursBoundingBoxes() {

  for (int i=0; i<contours.size (); i++) {

    Contour contour = contours.get(i);
    Rectangle r = contour.getBoundingBox();
    int x = 0;
    int y = 0;

    if (//(contour.area() > 0.9 * src.width * src.height) ||
    (r.width < blobSizeThreshold || r.height < blobSizeThreshold))
      continue;

    stroke(255, 0, 0);
    fill(255, 0, 0, 150);
    strokeWeight(2);
    rect(r.x, r.y, r.width, r.height);
    println("X: " + r.x + "; Y: " + r.y);
    x = r.x - 347;
    y = r.y - 212;
    if (x > 10 || x < -10) xInc = xInc - x / 4;
    if (y > 10 || y < -10) yInc = yInc - y / 4;
    
    fill(0);
    ellipse(xInc,yInc,20,20);
  }
}

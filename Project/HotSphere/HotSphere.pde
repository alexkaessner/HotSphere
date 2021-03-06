/**
 * HotSphere
 * This sketch translates the tracking data of the HotSphere Device into a input
 * and uses these input data to control a hotwire game.
 *
 * It uses the OpenCV for Processing library by Greg Borenstein
 * https://github.com/atduskgreg/opencv-processing
 * 
 * @authors: Kevin Schiffer (@kschiffer), Alexander Käßner (@alexkaessner), Alvaro Garcia Weissenborn (@varusgarcia)
 * @modified: 17/10/2014
 * 
 * University of Applied Sciences Potsdam, 2014
 */

int gameMode = 0;
int sensitivity = 12;
boolean readyToGame = false;
boolean mouseInput = true;  // set to false to use camera as input
import gab.opencv.*;
import java.awt.Rectangle;
import processing.video.*;

PFont Avenir;

PImage [] animation = new PImage [5];
PImage [] animationInvert = new PImage [5];
int currentFrame = 1;

Movie titleMovie;

int i;
float a;
float s;
int r;
float[][] values = new float[1280/3][3];

OpenCV opencv;
Capture video;
PImage src, preProcessedImage, processedImage, contoursImage;
ArrayList<Contour> contours;



int paddingTop = 60;
int currentStage = 1;
float contrast = 0.66; //was 1.35
int brightness = 0;
int threshold = 82; // was 75
boolean useAdaptiveThreshold = false; // use basic thresholding
int thresholdBlockSize = 489;
int thresholdConstant = 45;
int blobSizeThreshold = 20;
int blurSize = 4;
PImage levelImage;

color thatRed = color(210, 67, 53);
PImage menuImage;
int waitingRepeatGame;
int waitingStartAgain;
int startTextSize = 200;
int startTextNumber = 0;

boolean gameOverAnimation=false;
int fadeGameOverRed = 0;
int fadeGameOverBlack = 0;

int choosingSpeed = 20;
int finderSize = 80;
int startingTime;
int endingTime;
int printLevelWait = 0;

int xInc = 500;
int yInc= 500;
int lastX;
int lastY;
int imageWidth;
int imageHeight;
float rotation = 0;

void setup() {
  frameRate(25);
  size(1024, 768);
  titleMovie = new Movie(this, "title.mov");
  titleMovie.loop();

  for (int i=1; i < 5; i++) {
    String imageNameInvert = "frame" +i+".png";
    animationInvert[i] = loadImage(imageNameInvert);
    animationInvert[i].filter(INVERT);
  }
  for (int i=1; i < 5; i++) {
    String imageName = "frame" +i+".png";
    animation[i] = loadImage(imageName);
  }
  if (!mouseInput) {

    video = new Capture(this, 640, 480, "USB2.0 Camera");
    video.start();

    opencv = new OpenCV(this, 640, 480);
    contours = new ArrayList<Contour>();

    //size(opencv.width, opencv.height, P2D);
  }
  drawLevel(1, "level");
  Avenir = createFont("Avenir LT Std", 32);
  textFont(Avenir);
}

void draw() {

  if (mouseInput) {
    xInc = mouseX;
    yInc = mouseY;
  } else {
    if (readyToGame || gameMode == 0) {
      trackPosition();
    }
  }
  if (gameMode == -1) {
    drawLevel(4, "three");
    noLoop();
  }

  //////////
  // MENU //
  //////////
  if (gameMode == 0) {
    background(255);
    image(titleMovie, 0, 0);

    drawMenuButtons();

    // HEADER GRAPHIC
    menuImage = loadImage("Menu.png");
    image(menuImage, (width-552)/2, (height-496)/2, 552, 496); //552 496
  }

  ////////////
  // INGAME //
  ////////////
  if (gameMode == 1) {

    if (!readyToGame) {
      image(levelImage, 0, 0);
      fill(thatRed);
      textSize(startTextSize);
      textAlign(CENTER);

      // Ready, Set, Go! - Text Animation
      if (startTextNumber == 0) {
        text("STAGE "+ currentStage, width/2, height/2);
        if (startTextSize <= 20) {
          startTextNumber = 1;
          startTextSize = 200;
        }
      }
      if (startTextNumber == 1) {
        text("HOLD STILL!", width/2, height/2);
        if (startTextSize <= 20) {
          startTextNumber = 2;
          startTextSize = 200;
        }
      }
      if (startTextNumber == 2) {
        text("GO!", width/2, height/2);
        if (startTextSize <= 20) {
          xInc = 20;
          yInc = height/2;
          readyToGame = true;
          startTextSize = 200;
        }
      }
      startTextSize += -8;
    } else {
      image(levelImage, 0, 0);

      printLevelWait++;
      if (xInc > width-5 && !gameOverAnimation) {
        println("success!");
        drawLevel(currentStage++, "level");
        readyToGame = false;
        startTextNumber = 0;

        xInc = 20;
        yInc = height/2;
      }

      ///////////////
      // GAME OVER //
      ///////////////
      if (get(xInc+5, yInc+5) == -16777216 || get(xInc+25, yInc+25) == -16777216 || get(xInc, yInc+25) == -16777216 || get(xInc+25, yInc) == -16777216) {
        println("GAME OVER");
        gameOverAnimation = true;
      }
      if (gameOverAnimation == true) {
        noStroke();
        fill(210,67,53, fadeGameOverRed);
        rect(0, 0, width, height);
        fadeGameOverRed += 10;

        fill(0);
        textSize(100);
        text("GAME OVER", width/2, height/2);

        if (fadeGameOverRed >= 255) {
          fadeGameOverRed = 255;
        }
      }
    }

    if (fadeGameOverRed == 255) {
      fill(0, 0, 0, fadeGameOverBlack);
      rect(0, 0, width, height);
      fadeGameOverBlack += 20;

      if (fadeGameOverBlack >= 255) {
        fadeGameOverBlack = 255;
      }
    }

    if (fadeGameOverBlack == 255) {
      readyToGame = false;
      gameOverAnimation = false;
      gameMode = 0;
      startTextNumber = 0;
      fadeGameOverRed = 0;
      fadeGameOverBlack = 0;
    } else {
      //println("good!");
    }
  }

if (readyToGame || gameMode == 0) {
  pushMatrix();
  imageWidth = animation[currentFrame].width;
  imageHeight = animation[currentFrame].height;
  translate(xInc + imageWidth/2, yInc + imageHeight/2);
  rotation = getAngle(lastX, lastY, xInc, yInc);
  //println("lastX: "+lastX+"; lastY: "+lastY+"; x: "+xInc+" y:"+yInc+"; rotation: "+rotation);
  rotate(rotation);
  translate(-imageWidth/2, -imageHeight/2);
  
  int repeatButtonX = 316;
  int startAgainButtonX = 708;
  int buttonsY = 552;
  
  float distRepeatButton= dist(xInc,yInc,repeatButtonX,buttonsY);
  float distStartAgainButton= dist(xInc,yInc,startAgainButtonX,buttonsY);
  if (gameMode == 0 && distRepeatButton > (160/2) && distStartAgainButton > (160/2) ) image(animationInvert[currentFrame], 0, 0);
  else image(animation[currentFrame], 0, 0);
  popMatrix();
} else {
  image(animation[currentFrame], 20, height/2);
}


//rotate(degrees(-rotation));
currentFrame++;
if (currentFrame >= 5) {
  currentFrame = 1 ;
}
}

void movieEvent(Movie m) {
  m.read();
}

float getAngle (int x1, int y1, int x2, int y2)
{
  int dx = x2 - x1;
  int dy = y2 - y1;
  return atan2(dy, dx);
}


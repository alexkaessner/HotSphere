int i;
float a;
float s;
int r;
float[][] values = new float[1280/3][3];
void setup() {
  size(1280,400);
  fill(0);
  //background(255);
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

void draw(){
  if(get(mouseX,mouseY)!=-1){
      println("over");
  } else {
      println("not over");
  }

}

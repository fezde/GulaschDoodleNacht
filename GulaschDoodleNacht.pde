/*********************************************************************************************************************************
*
* GulaschDoodleNacht
*
* This project was created during #gpn19 in Karlsruhe
*
*********************************************************************************************************************************/
import geomerative.*;


import gohai.simpletweet.*;
import megamu.mesh.*;

import twitter4j.Query;
import twitter4j.QueryResult;
import twitter4j.Status;
import twitter4j.TwitterException;
import twitter4j.User;
import java.util.*;

ArrayList<PVector> voroPoints;
Voronoi myVoronoi;
float[][] points;                    // TODO: Do we really need these
ArrayList<Integer> regionsOnCanvas;  // Contains indexes of those voronois that are completely visible on screen

/**
* Settings
* Most of them can be toggled by keyboard
* see help
**/
boolean showHelp = false;
boolean showPoints = false;
boolean showVoronois = false;
boolean showName = false;
int breakDurationInSeconds = 5;
boolean saveOutput = false;

PVector currentPos = new PVector(1, 1, 1);

ArrayList<Integer> currentSentence = new ArrayList<Integer>();

SimpleTweet simpletweet;
ArrayList<Status> tweets;
User currentUser;
String currentMessage;

String fontFile;
RShape usernameGeo;
long pauseBis;

String helpText = ""+
  "  h - Toggle this help \n"+
  "  p - Toggle Point visibility\n"+
  "  v - Toggle Voronoi visibility\n"+
  "\n"+
  "ESC - Quit";

/**
 * Stuff used for rendering the tweet text in the backgorund
 **/
PFont tweetFont; 
PGraphics tweetGraphics;


/**
* Plasma background
**/
PGraphics plasma;
float plasmaMinColor = 80;  // Grey values only
float plasmaMaxColor = 200; // Grey values only


/**
* Renders (and scales correctly) the tweet text onto the background layer
**/
public void createTweetGraphics() {
  String text = currentMessage;
  tweetGraphics = createGraphics(width, height);
  tweetGraphics.beginDraw();
  
  tweetGraphics.textAlign(CENTER, CENTER);
  tweetGraphics.fill(255);
  
  float textSize = -1;
  int newLineCount = 0;

  tweetGraphics.textFont(tweetFont);

  while (textSize < 50 && newLineCount < 10) {
    text = currentMessage;
    if (newLineCount > 0) {
      for (int i=newLineCount-1; i>=0; i--) {
        int pos = (text.length() / newLineCount) * (i+1);
        text = new StringBuilder(text).insert(pos, "\n").toString();
      }
    }

    textSize = min(tweetFont.getSize()*(width-50)/tweetGraphics.textWidth(text), height);
    newLineCount++;
  }

  tweetGraphics.textSize(textSize);
  tweetGraphics.textLeading(textSize + (textSize/10));
  tweetGraphics.text(text, width/2, height/2);
  tweetGraphics.filter(BLUR, 1);
  tweetGraphics.endDraw();
}

/********************************************************
* SETUP
********************************************************/
void setup() {
  //size(800, 800);
  fullScreen();
  frameRate(10);
  smooth(8);

  voroPoints = new ArrayList<PVector>();
  regionsOnCanvas = new ArrayList<Integer>();

  RG.init(this); // Initialize geomerative

  fontFile = "/Users/felix.kratzer/Documents/Development/Other/gpn19/fonts/MAWNS' Graffiti Filled.ttf";
  fontFile = "/Users/felix.kratzer/Documents/Development/Other/gpn19/fonts/Arial Black.ttf";

  tweetFont = createFont("Arial Black", 7);

  simpletweet = new SimpleTweet(this);

  /*
   * Create a new Twitter app on https://apps.twitter.com/
   * then go to the tab "Keys and Access Tokens"
   * copy the consumer key and secret and fill the values in below
   * click the button to generate the access tokens for your account
   * copy and paste those values as well below
   */
  simpletweet.setOAuthConsumerKey("TODO-READ-THIS-FROM-FILE");
  simpletweet.setOAuthConsumerSecret("TODO-READ-THIS-FROM-FILE");
  simpletweet.setOAuthAccessToken("TODO-READ-THIS-FROM-FILE");
  simpletweet.setOAuthAccessTokenSecret("TODO-READ-THIS-FROM-FILE");

  tweets = search("#gpn19");
  println("Tweets loaded");
  processMessage(tweets.remove(0));
  generatePlasma(3);
  println("Plasma generated");
}

/********************************************************
* DRAW
********************************************************/
void draw() {


  if (currentSentence.size() > 2) {
    currentPos.x = ((currentPos.x * currentSentence.remove(0)) % width) + 1;
    currentPos.y = ((currentPos.y * currentSentence.remove(0)) % height) + 1;
    currentPos.z = ((currentPos.z * currentSentence.remove(0)) % 255) + 1;
    voroPoints.add(new PVector(currentPos.x, currentPos.y, currentPos.z));
    //println(currentPos);
    createVoronoi();
  } else {
    //println("Neuer Satz erforderlich");
    if (pauseBis == 0) {
      println("Uhr aufziehen");
      pauseBis = millis() + breakDurationInSeconds*1000;
    }
    if (millis() > pauseBis) {
      println("Uhr abgelaufen");
      pauseBis = 0;
      if (tweets.size() > 0) {
        processMessage(tweets.remove(0));
      }
    }
  }


  clear();

  PGraphics resultPlasma = createGraphics(width, height);
  float x = frameCount % width;
  float y = frameCount % height;
  resultPlasma.beginDraw();
  resultPlasma.image(plasma, x, y);
  resultPlasma.image(plasma, x-width, y);
  resultPlasma.image(plasma, x, y-height);
  resultPlasma.image(plasma, x-width, y-height);
  resultPlasma.endDraw();
  
  resultPlasma.mask(tweetGraphics);
  image(resultPlasma, 0, 0);
  //image(tweetGraphics, 0, 0);
  
  
  strokeWeight(1);
  stroke(80, 50);


  // Draw the voronoi
  MPolygon[] myRegions = myVoronoi.getRegions();

  for (int i=0; i<myRegions.length; i++) {
    if (regionsOnCanvas.contains(i)) {
      fill(voroPoints.get(i).z);
    } else {
      fill(230);
    }

    if (showVoronois) {
      myRegions[i].draw(this); // draw this shape
    }



    if (regionsOnCanvas.contains(i)) {
      // Now we doodle this
      float[][] regionCoordinates = myRegions[i].getCoords();


      Polygon p = new Polygon();
      for (int j=0; j<regionCoordinates.length; j++) {
        p.addBasePoint(regionCoordinates[j][0], regionCoordinates[j][1]);
      }
      stroke(255);
      p.draw(this);
    }
  }


  if (showPoints) {
    fill(255);
    strokeWeight(6);
    stroke(0);
    for (int i=0; i<voroPoints.size(); i++) {
      point(voroPoints.get(i).x, voroPoints.get(i).y);
    }
  }

  if (showName) {
    pushMatrix();
    translate(width/2, height-50);


    stroke(123);
    strokeWeight(8);
    strokeJoin(ROUND);
    usernameGeo.draw();

    //blendMode(DIFFERENCE);
    noStroke();
    fill(255);
    usernameGeo.draw();
    //blendMode(BLEND);

    popMatrix();
  }


  if (showHelp) help();
  if (saveOutput) {
    saveFrame("output/output-#####.png");
  }
}

void generatePlasma(int frequency){
  float scaleX = (2*PI) / width;
  float scaleY = (2*PI) / height;
  
  plasma = createGraphics(width, height);
  
  plasma.beginDraw();
  for(float y=0; y<height; y++){
    for(float x=0; x<width; x++){
      plasma.stroke(((plasmaMaxColor-plasmaMinColor) * ((sin(x*scaleX*frequency)+1)+(cos(y*scaleY*frequency)+1))/4) + plasmaMinColor);
      //plasma.stroke(255);
      plasma.point(x,y);
    }
  }
  plasma.endDraw();
}

void processMessage(Status message) {

  currentSentence = new ArrayList<Integer>();
  voroPoints.clear();
  currentPos = new PVector(1, 1, 1);
  currentUser = message.getUser();
  currentMessage = message.getText();
  usernameGeo = RG.getText("@"+currentUser.getScreenName(), fontFile, 72, CENTER);
  println("New message: " + currentMessage);

  for (int i=0; i<currentMessage.length(); i++) {
    currentSentence.add((int)currentMessage.charAt(i));
  }
  createTweetGraphics();
  createVoronoi();
}

void keyReleased() {
  if (key == 'h') showHelp = !showHelp;
  if (key == 'p') showPoints = !showPoints;
  if (key == 'v') showVoronois = !showVoronois;
}

void createVoronoi () {
  points = new float[voroPoints.size()][2];
  for (int i=0; i<voroPoints.size(); i++) {
    points[i][0] =(int) voroPoints.get(i).x;
    points[i][1] =(int) voroPoints.get(i).y;
  }
  myVoronoi = new Voronoi( points );

  regionsOnCanvas = new ArrayList<Integer>();


  MPolygon[] myRegions = myVoronoi.getRegions();
  for (int i=0; i<myRegions.length; i++) {
    boolean completelyOnCanvas = true;


    // an array of points
    PVector mainPoint = voroPoints.get(i);
    String main = mainPoint.x + " " + mainPoint.y;
    float[][] regionCoordinates = myRegions[i].getCoords();
    for (int j=0; j<regionCoordinates.length; j++) {
      PVector coord = new PVector(regionCoordinates[j][0], regionCoordinates[j][1]);
      if (coord.x > width || coord.x < 1) completelyOnCanvas = false;
      if (coord.y > height || coord.y < 1) completelyOnCanvas = false;
    }
    if (completelyOnCanvas) {
      regionsOnCanvas.add(i);

      //println("------------");
      for (int j=0; j<regionCoordinates.length; j++) {
        PVector coord = new PVector(regionCoordinates[j][0], regionCoordinates[j][1]);
        //float angle = PVector.angleBetween(mainPoint,coord.sub(mainPoint));
        PVector t = coord.sub(mainPoint);
        float angle = PVector.angleBetween(new PVector(0, 0), t);
        //println(main + "\t-> (" + t.x + " " + t.y + ") ==> " + angle );
      }
    }
  }
}

/**************************************************
 * LOAD TWEETS
 ***************************************************/
ArrayList<Status> search(String keyword) {
  // request 100 results
  Query query = new Query(keyword);
  query.setCount(100);

  try {
    QueryResult result = simpletweet.twitter.search(query);
    ArrayList<Status> tweets = (ArrayList)result.getTweets();
    // return an ArrayList of Status objects
    return tweets;
  } 
  catch (TwitterException e) {
    println(e.getMessage());
    return new ArrayList<Status>();
  }
}

void help() {
  noStroke();
  fill(128, 128);
  rect(0, 0, 200, 150);
  fill(255);
  text(helpText + "\n\nFPS: " + frameRate, 10, 20);
}








/************************************
 * Polygon
 ************************************/
class Polygon {

  /**
   * Die Außenpunkte des Polygons
   **/
  Vector<PVector> basePoints;

  Vector<PVector> points;

  float minRad = 100;
  float maxRad = 1;

  int col=0;

  public Polygon() {
    basePoints = new Vector<PVector>();
  }

  /**
   * Fügt einen basePoint hinzu
   **/
  public void addBasePoint(PVector p) {
    this.basePoints.add(p);
  }
  public void addBasePoint(float x, float y) {
    this.basePoints.add(new PVector(x, y));
  }

  public void draw(PApplet p) {
    Vector<PVector> allPoints = new Vector<PVector>();
    for (int i=0; i<this.basePoints.size(); i++) {
      allPoints.add(this.basePoints.get(i));
    }
    float len = 1000;
    int currentIdx = 0;
    while (len > 1) {
      PVector p1 = allPoints.get(currentIdx);
      PVector p2 = allPoints.get(currentIdx+1);

      PVector pn = new PVector(p2.x, p2.y);
      pn.sub(p1); 
      pn.mult(0.2);
      pn.add(p1);

      len = p1.dist(pn);


      //println(p1 + " -> " + p2 + " : " + len + " ==> " + pn);
      //len = 9;
      //p.ellipse(pn.x, pn.y, 10, 10);

      allPoints.add(pn);
      currentIdx++;
    }

    for (int i=0; i<allPoints.size()-1; i++) {
      line(allPoints.get(i).x, allPoints.get(i).y, allPoints.get(i+1).x, allPoints.get(i+1).y);
    }

    for (int i=0; i<this.basePoints.size()-1; i++) {
      PVector start = this.basePoints.get(i);
      PVector end = this.basePoints.get(i+1);
      //p.line(start.x, start.y, end.x, end.y);
    }
    p.line(this.basePoints.get(0).x, this.basePoints.get(0).y, this.basePoints.get(this.basePoints.size()-1).x, this.basePoints.get(this.basePoints.size()-1).y);
  }
}

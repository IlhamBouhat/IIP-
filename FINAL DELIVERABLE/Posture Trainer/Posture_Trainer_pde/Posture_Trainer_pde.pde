/**
 * Training code for the posture determiner code
 * @author Ilham El Bouhattaoui, Luuk Stavenuiter, Nadine Schellekens
 * @id 1225930, 
 * date: 31/05/2020
 * 
 * The baseline for this code is the same as the Posture code
 * It will load the dataset made in the posture set
 * It will then train a model with that set and save it
 * It also shows the predictions in real time
 * Uses example codes from Rong Hao Liang's github library for the course DBB220 Interactive Intelligent Products topic 2.2and 8.2
 * Links to the source code: 
 * https://github.com/howieliang/IIP1920/tree/master/Example%20Codes/2_2_Serial_Communication/Processing/p2_2c_SaveSerialAsARFF_A012
 * https://github.com/howieliang/IIP1920/tree/master/Example%20Codes/8_2_Camera_Based_Activity_Recognition/t3_FaceDetection/HAARCascade
 * https://github.com/howieliang/IIP1920/tree/master/Example%20Codes/8_2_Camera_Based_Activity_Recognition/t3_FaceDetection/SaveARFF_FaceRecognition
 * https://github.com/howieliang/IIP1920/tree/master/Example%20Codes/8_2_Camera_Based_Activity_Recognition/t3_FaceDetection/TrainLSVC_FaceRecognition
 *
 *
 *
 **/

import processing.serial.*;
Serial port; 

import gab.opencv.*;
import processing.video.*;
import java.awt.*;

Capture video;
OpenCV opencv;

int div = 2;
PImage src, threshBlur, dst;
int blurSize = 12;
int grayThreshold = 80;


boolean dataUpdated = false;
ArrayList<Contour> contours;
String featureText = "Face";

int dataNum = 100;
int dataIndex = 0;
int sensorNum = 4;
int[][] rawData = new int[sensorNum][dataNum];

/**
 * Setup for the training code set
 * Defines libraries used, and which features are selected
 * Initialises serial communication
 * Loads the training set and the model
 * Evaluates the training set 
 **/

void setup() {
  size(640, 480);
  for (int i = 0; i < Serial.list().length; i++) println("[", i, "]:", Serial.list()[i]);
  String portName = Serial.list()[Serial.list().length-1];
  port = new Serial(this, portName, 115200);
  port.bufferUntil('\n'); // arduino ends each data packet with a carriage return 
  port.clear(); 

  //when the code is run, the webcam is loaded
  video = new Capture(this, 640/div, 480/div);
  opencv = new OpenCV(this, 640/div, 480/div);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  
  video.start();

  loadTrainARFF(dataset="accData.arff"); //load a ARFF dataset
  println(train);
  trainLinearSVR(epsilon=0.1);               //train a KNN classifier
  evaluateTrainSet(fold=5, isRegression = true, showEvalDetails=true);  //5-fold cross validation
  saveModel(model="LinearSVC.model"); //save the model

  background(52);
}


void draw() {
  background(0);
  pushMatrix();
  scale(2);

  //https://github.com/atduskgreg/opencv-processing/blob/master/src/gab/opencv/OpenCV.java

  featureText = "Face";   
  opencv.loadImage(video);
  opencv.useColor();
  src = opencv.getSnapshot();
  image(src, 0, 0);

  Rectangle[] features = opencv.detect();

  // draw detected face area(s)
  for ( int i=0; i<features.length; i++ ) {
    for(int n=0; n<dataNum; n++){
    noFill();
    stroke(255, 0, 0);
    rect( features[i].x, features[i].y, features[i].width, features[i].height );
    noStroke();
    fill(255);
    text(featureText, features[i].x, features[i].y-20);


    //predicts the label and reads it out real time on the screen 
    float[] X = {features[i].width, rawData[3][n]}; 
    String Y = getPrediction(X);
    textSize(11);
    textAlign(CENTER, CENTER);
    String text = "Prediction: "+Y+
      "\n X="+X;

    text(text, 40, 50);
    switch(Y) {
    case "A": 
      port.write('a'); 
      break;
    case "B": 
      port.write('b'); 
      break;
    default: 
      break;
    }

    println(features[i].width, rawData, Y);
  }
  }
  popMatrix();
}

void serialEvent(Serial port) {
  String inData = port.readStringUntil('\n');
  if (dataIndex<dataNum) {
    if (inData.charAt(0) == 'A') {
      rawData[0][dataIndex] = int(trim(inData.substring(1)));
    }
    if (inData.charAt(0) == 'B') {
      rawData[1][dataIndex] = int(trim(inData.substring(1)));
    }
    if (inData.charAt(0) == 'C') {
      rawData[2][dataIndex] = int(trim(inData.substring(1)));
    }
    if (inData.charAt(0) == 'D') {
      rawData[3][dataIndex] = int(trim(inData.substring(1)));
      ++dataIndex;
    }
  }
  return;
}

void captureEvent(Capture c) {
  c.read();
}

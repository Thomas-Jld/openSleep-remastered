import processing.sound.*;
import processing.serial.*;
import processing.video.*; 

import com.hamoid.*;

VideoExport video;
Capture cam; 
SoundFile audio;

/*
HR: Heart Rate
PC: Confidence of the heart rate
ST: State (0: Nothing detected, 1: object detected, 2: finger detected, 3: reading finger)
SC: Skin Conductivity
FX: Flex Sensor
*/

boolean started = false;

int n = 100;
int channels = 5;
int mod = 4;
int[] maxs = {120, 100, 4, 4200, 4200};
int[] prec = {10, 10, 4, 10, 10};

//Marker when pressing some keys to mark a key moment (Like 1 to 9 special markers)

String[] columns = {"HR", "PC", "ST", "SC", "FX"};
String[] complete_columns = {"Heart_Rate", "Confidence_percentage", "Status", "Skin_Conductivity", "Flex_Sensor"};

float[][] data = new float[channels][n];
String[] line_info = new String[channels];

String name = ("result_" + String.valueOf(month()) + "_" + String.valueOf(day()) + "_" + String.valueOf(year()) +  "_" 
+ String.valueOf(hour()) + ":" + String.valueOf(minute()) + ":" + String.valueOf(second()));

Serial port;
String val;

int counter = 0;

int winSizeX = 300;
int winSizeY = 250;
int offset = 40;
int background_color = 255;

Table results;
TableRow newRow;

int rec_time = 20;

public void settings() {
  size(mod * (winSizeX + offset), (channels/mod + 1) * (winSizeY + 2 * offset));
}

void setup()
{
  // Setting csv headers for saving files
  results = new Table();
  results.addColumn("Date");
  for(int i = 0; i < channels; i++){
    results.addColumn(columns[i]);
  }
  
  
  smooth();
  try{
    port = new Serial(this, "/dev/ttyUSB0", 115200);
  } catch (RuntimeException e) {
    e.printStackTrace();
    port = new Serial(this, "/dev/ttyUSB1", 115200);
  }
  cam = new Capture(this);
  cam.start();
  video = new VideoExport(this, "videos/" + name + ".mp4", cam);
  
  audio = new SoundFile(this, "06.mp3");
}

void draw()
{
  if (port.available() > 0) // Checking if we can access the hardware
  {
    val = port.readStringUntil('\n'); //Read the data
    background(background_color);
    
    if(val != null){
      line_info = split(val, ';');
      
      if (started){
        newRow = results.addRow();
        newRow.setString("Date", String.valueOf(hour()) + ":" + String.valueOf(minute()) + ":" + String.valueOf(second())+ ":" + String.valueOf(millis()));
      }
      for(int i = 0; i < channels; i++){
        for(int j = 0; j < n-1; j++){
          data[i][j]= data[i][j+1];
        }
        float sval = float(split(line_info[i], ":")[1]);
        if (started){
          newRow.setFloat(columns[i], sval);
        }
        data[i][n-1] = sval;
      }
    }
    
    // Saving every folders every 10*60*rec_time sample (~ 10 samples per second)
    if(started){
      if(counter > 10*60*rec_time){
        save_data();
      }
      else{
        counter = counter + 1;
      }
    }
      
    // Horizontal separation line
    stroke(255 - background_color);
    strokeWeight(4);
    line(0, winSizeY + 2*offset, (winSizeX + offset)*mod, winSizeY + 2*offset);
    
    // Verctical separation lines
    for (int i = 0; i < mod; i++) {
      strokeWeight(2);
      line((winSizeX + offset)*(1 + i), 0, (winSizeX + offset)*(1 + i), height);
    }
    
    // Lines of the graph + scale
    for (int i=0; i < channels; i++) {
      for(int k = 0; k <= prec[i];k++){
        textAlign(CENTER, CENTER);
        textSize(12);  
        fill(25, 147, 155);
        text(k*maxs[i]/prec[i], offset*(i%mod + 0.5) + winSizeX*(i%mod), offset * (2*(i/mod) + 1) + winSizeY*(1 + i/mod) - k*winSizeY/prec[i]);
        stroke(25, 147, 155, 100);
        strokeWeight(1);
        line(offset*(i%mod + 1) + winSizeX*(i%mod), offset * (2*(i/mod) + 1) + winSizeY*(1 + i/mod) - k*winSizeY/prec[i],
             offset*(i%mod + 1) + winSizeX*(i%mod + 1), offset * (2*(i/mod) + 1) + winSizeY*(1 + i/mod) - k*winSizeY/prec[i]);
        
      }
      
      //Name of the data under the graph
      textAlign(CENTER, CENTER);
      textSize(20);
      fill(25, 147, 155);
      text(complete_columns[i], offset*(i%mod + 1) + winSizeX*(i%mod + 0.5), offset * (2*(i/mod) + 1.5) + winSizeY*(1 + i/mod));
      
      // Drawing the graphs
      for (int j=1; j< data[0].length; j++) {
        stroke(204,25,94);
        strokeWeight(2);
        line(offset*(i%mod + 1) + winSizeX*(i%mod) + j*winSizeX/n, offset * (2*(i/mod) + 1) + winSizeY*(1 + i/mod) - winSizeY*data[i][j]/maxs[i], 
             offset*(i%mod + 1) + winSizeX*(i%mod) + (j-1)*winSizeX/n, offset * (2*(i/mod) + 1) + winSizeY*(1 + i/mod) - winSizeY*data[i][j-1]/maxs[i]);
      }
      
      // Display raw value
      textAlign(CENTER, CENTER);
      textSize(20);
      fill(25, 147, 155);
      text(columns[i] + " : " + data[i][data[0].length-1], (winSizeX + offset)*2.5, (winSizeY + 2.25*offset)*(1.2 + 0.6*i/channels));
    }
  
    // Recording circle
    stroke(25, 147, 155);
    if(started){
      fill(255, 0, 0);
    }
    else{
      fill(background_color);
    }
    ellipse((winSizeX + offset)*2.5, (winSizeY + 2.1*offset)* 1.1 , 30.0, 30.0);
  }
  
  // Read the camera input
  if (cam.available()) { 
    cam.read(); 
  }
  // Display the cam input
  image(cam, (winSizeX + 1.5*offset), (winSizeY + 2.5*offset),  winSizeX, winSizeY + offset);

  if(started){ // Save the frame if the recording has started
    video.saveFrame();
  }
}


void keyPressed(){
  if(key == 'n'){
    save_data();
  }
  if(key == 's'){
    started = true;
    video.startMovie();
    audio.play();
  }
  if(key == 'q'){
    end_recording();
    exit();
  }
}

void save_data(){
    counter = 0;
    saveTable(results, "results/" + name + ".csv");
    results.clearRows();
    video.endMovie();
    name = ("result_" + String.valueOf(month()) + "_" + String.valueOf(day()) + "_" + String.valueOf(year()) +  "_" 
    + String.valueOf(hour()) + ":" + String.valueOf(minute()) + ":" + String.valueOf(second()));
    video = new VideoExport(this, "videos/" + name + ".mp4", cam);
    video.startMovie();
}

void end_recording(){
    counter = 0;
    saveTable(results, "results/" + name + ".csv");
    results.clearRows();
    video.endMovie();
}

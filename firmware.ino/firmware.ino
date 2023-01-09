#include <SparkFun_Bio_Sensor_Hub_Library.h>
#include <Wire.h>

#define skin_cond 13
#define flex_sensor 12

int resPin = 25;
int mfioPin = 26;

SparkFun_Bio_Sensor_Hub bioHub(resPin, mfioPin); 

bioData body;  

void setup(){

  Serial.begin(115200);

  Wire.begin();
  int result = bioHub.begin();
  if (result == 0) // Zero errors!
    Serial.println("Sensor started!");
  else
    Serial.println("Could not communicate with the sensor!!!");
 
  Serial.println("Configuring Sensor...."); 
  int error = bioHub.configBpm(MODE_ONE); // Configuring just the BPM settings. 
  if(error == 0){ // Zero errors!
    Serial.println("Sensor configured.");
  }
  else {
    Serial.println("Error configuring sensor.");
    Serial.print("Error: "); 
    Serial.println(error); 
  }

  // Data lags a bit behind the sensor, if you're finger is on the sensor when
  // it's being configured this delay will give some time for the data to catch
  // up. 
  Serial.println("Start");
  delay(4000); 
  
}

void loop(){

    // Information from the readBpm function will be saved to our "body"
    // variable.  
    body = bioHub.readBpm();
    Serial.print("HR:");
    Serial.print(body.heartRate); 
    Serial.print(";PC:");
    Serial.print(body.confidence); 
    Serial.print(";ST:");
    Serial.print(body.status); 
    Serial.print(";SC:");
    Serial.print(analogRead(skin_cond));
    Serial.print(";FX:");
    Serial.println(analogRead(flex_sensor));
    delay(100); 
    
    
}

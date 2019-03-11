/*
      Ce programme destiné à un Arduino Nano embarqué sur le drone a pour but de récupérer les valeurs du
    capteur de pression BMP180 du magnétomètre GY-271 du gyroscope MPU6050 et du capteur de tension, 
    de rassembler toutes ces données dans une structure de 9 octets sans fil en 2.4Ghz avec le module nRF24L01+ 
    et de les envoyer à un autre Arduino Nano relié à un ordinateur via le port USB. La plupart des fonctions
    vienne des sketchs d'exemples des librairies de chacun des modules, car la plupart font intervenir des 
    notions et des calculs très complexes (transformations d'Euler, des communications via I²C) et bien
    qu'il soit possible de s'en passer, l'étude minutieuse des fiches techniques des constructeurs de 
    chacun des modules serait nécessaire, ce qui prendrait énormément de temps et requièrerait de nombreuses
    connaissances. Cela n'étant pas l'objet de notre projet, nous nous contentons d'utiliser ces librairies 
    qui fonctionnent très bien, malgré qu'elles ne soient peut-être pas optimisées pour notre usage spécifique
    (J'ai par ailleurs laissé certains commentaires de ces librairies afin de faciliter leurs compréhension).

*/
//#############NRF24L01##########
#include <Arduino.h>
#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

const uint64_t adresse =  12345;     //Adresse de la radio

RF24 radio(7, 8);         // Déclaration de la radio et affectation des pins 7 (CE) et 8 (CS) de l'arduino 

typedef struct {          //Structure du paquet de 9 octets fixes qui sera transmis
  short roulis = 255;
  short tangage = 255;
  short lacet = 255;
  short pression = 255;
  byte pourcentage_batterie = 255;
  byte orientation = 255;
}
MyData;
MyData paquet;
//######### BMP 180 #########   //Insertion des bibliothèques de chacun des capteurs / module
#include <SFE_BMP180.h>
#include <Wire.h>
SFE_BMP180 pressure;
double baseline;

//######### GY-271 ###########
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_HMC5883_U.h>
Adafruit_HMC5883_Unified mag = Adafruit_HMC5883_Unified(12345);

//######### MPU6050 ##########
#include "I2Cdev.h"
#include "MPU6050_6Axis_MotionApps20.h"
#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
#include "Wire.h"
#endif
MPU6050 mpu;
#define OUTPUT_READABLE_YAWPITCHROLL
#define LED_PIN 13 // (Arduino is 13, Teensy is 11, Teensy++ is 6)
bool blinkState = false;

bool dmpReady = false;  // set true if DMP init was successful
uint8_t mpuIntStatus;   // holds actual interrupt status byte from MPU
uint8_t devStatus;      // return status after each device operation (0 = success, !0 = error)
uint16_t packetSize;    // expected DMP packet size (default is 42 bytes)
uint16_t fifoCount;     // count of all bytes currently in FIFO
uint8_t fifoBuffer[64];

Quaternion q;           // [w, x, y, z]         quaternion container
VectorInt16 aa;         // [x, y, z]            accel sensor measurements
VectorInt16 aaReal;     // [x, y, z]            gravity-free accel sensor measurements
VectorInt16 aaWorld;    // [x, y, z]            world-frame accel sensor measurements
VectorFloat gravity;    // [x, y, z]            gravity vector
float euler[3];         // [psi, theta, phi]    Euler angle container
float ypr[3];           // [yaw, pitch, roll]   yaw/pitch/roll container and gravity vector
struct structure {
  int r;
  int t;
  int l;
};
structure data;
uint8_t teapotPacket[14] = { '$', 0x02, 0, 0, 0, 0, 0, 0, 0, 0, 0x00, 0x00, '\r', '\n' };
volatile bool mpuInterrupt = false;     // indicates whether MPU interrupt pin has gone high
void dmpDataReady() {
  mpuInterrupt = true;
}
//#######################################  SETUP  ##########################################################

void setup() {          //Initialisation des capteurs et du module de transmission
  Serial.begin(9600);


  //#######BMP180######
  baseline = getPressure();
  if (!pressure.begin()){
    Serial.println("BMP180 crash");    //Ces écritures sur le port de série permettent de trouver plus rapidement une éventuelle erreur de branchement
}
  baseline = getPressure();
  //#######GY-271#######
 if(!mag.begin()){
    Serial.println("GY-271 crash");    //Ces écritures sur le port de série permettent de trouver plus rapidement une éventuelle erreur de branchement
  }
  //#######MPU6050#######
  #if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
  Wire.begin();               //Début de la communication I²C, tous les capteurs (sauf celui de tension) fonctionnent avec ce protocole
                              //Heureusemet la carte maitresse peut parler jusqu'à 128 cartes esclaves en même temps du moment qu'elles ont des adresses différentes
  TWBR = 24; // 400kHz I2C clock (200kHz if CPU is 8MHz). Comment this line if having compilation difficulties with TWBR.
#elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE
  Fastwire::setup(400, true);
#endif
  mpu.initialize();
  if (mpu.testConnection() == 0) {
    Serial.println("MPU6050 crash");      //Ces écritures sur le port de série permettent de trouver plus rapidement une éventuelle erreur de branchement
  }
  devStatus = mpu.dmpInitialize();
  mpu.setXGyroOffset(220);
  mpu.setYGyroOffset(76);
  mpu.setZGyroOffset(-85);
  mpu.setZAccelOffset(1788); // 1688 factory default for my test chip

  if (devStatus == 0) {           //Initialisation du gyroscope
    mpu.setDMPEnabled(true);
    attachInterrupt(0, dmpDataReady, RISING);
    mpuIntStatus = mpu.getIntStatus();
    dmpReady = true;
    packetSize = mpu.dmpGetFIFOPacketSize();
  } else {
    Serial.print(F("DMP Initialization failed (code "));
    Serial.print(devStatus);
    Serial.println(F(")"));
  }
      //#######NRF24L01#######    //Initialisation du module de transmission
  radio.begin();
  radio.setPALevel(RF24_PA_MIN);   //Définit le gain de la radio
  //radio.setChannel(108);
  radio.setAutoAck(false);        //L'AutoAck est un protocole qui permet de demander le renvoi d'un paquet si ce dernier est perdu,
                                  //mais il est plus intéressant dans notre cas d'en envoyer le plus possible pour que le receveur en ait le maximum
  radio.setDataRate(RF24_250KBPS);//Définition du débit, plus de débit -> moins de portée et vice versa

  radio.openWritingPipe(adresse);//Ouverture du tunnel d'écriture

  if(!radio.available()){
    //Serial.println("Nrf24l01 crash");       //Ces écritures sur le port de série permettent de trouver plus rapidement une éventuelle erreur de branchement
  }

}

//############MPU6050############

structure MPU6050(){            //Lecture des valeurs yaw pitch roll (roulis tangage et lacet) du gyroscope, cette fonction supprime les effets gravitationnels, stocke les valeurs dans un buffeur avant de les retourner
  while (!mpuInterrupt && fifoCount < packetSize) {
    
  }
  // reset interrupt flag and get INT_STATUS byte
  mpuInterrupt = false;
  mpuIntStatus = mpu.getIntStatus();
  // get current FIFO count
  fifoCount = mpu.getFIFOCount();
  // check for overflow (this should never happen unless our code is too inefficient)
  if ((mpuIntStatus & 0x10) || fifoCount == 1024) {
    // reset so we can continue cleanly
    mpu.resetFIFO();
    Serial.println("FIFO overflow");
    // otherwise, check for DMP data ready interrupt (this should happen frequently)
  } else if (mpuIntStatus & 0x02) {
    //Serial.println("118");
    // wait for correct available data length, should be a VERY short wait
    while (fifoCount < packetSize) fifoCount = mpu.getFIFOCount();
    // read a packet from FIFO
    mpu.getFIFOBytes(fifoBuffer, packetSize);
    mpu.resetFIFO();
    // track FIFO count here in case there is > 1 packet available
    // (this lets us immediately read more without waiting for an interrupt)
    fifoCount -= packetSize;
    // display Euler angles in degrees
    mpu.dmpGetQuaternion(&q, fifoBuffer);
    mpu.dmpGetGravity(&gravity, &q);
    mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);
    data.r = ypr[0] * 180 / 3.14;
    data.t = ypr[1] * 180 / 3.14;
    data.l = ypr[2] * 180 / 3.14;
   
    
    return(data);
    
      
  }
}

//#########BMP180#########
double getPressure()
{
  char status;
  double T,P,p0,a;
  status = pressure.startTemperature();
  if (status != 0)
  {
    delay(status);
    status = pressure.getTemperature(T);
    if (status != 0)
    {
      status = pressure.startPressure(3);
      if (status != 0)
      {
        delay(status);
        status = pressure.getPressure(P,T);
        if (status != 0)
        {
          return(P);
        }
      }}}}

//##########GY-271##########

int magsensor(){                //Lecture de la valeur du magnétomètre
  sensors_event_t event; 
  mag.getEvent(&event);
  float heading = atan2(event.magnetic.y, event.magnetic.x);
  float declinationAngle = 0.22;
  heading += declinationAngle;
  if(heading < 0)
    heading += 2*PI;    //Ces lignes permettent de pouvoir faire un tour en bouclant
  if(heading > 2*PI)
    heading -= 2*PI;
  float headingDegrees = heading * 180/M_PI; 
  return(headingDegrees);
  
  
}

//##########Capteur tension########
int pourcentage_batterie(){
  int pourcentage = analogRead(0);   
  return(pourcentage);
}


//#######################################    LOOP    ########################################################
void loop() {
  MPU6050();
  double a,P;
  P = getPressure();
  a = pressure.altitude(P,baseline);       //Lecure des valeurs grâce aux fonctions
  int orientation = magsensor();
  float batterie = pourcentage_batterie() * 0.0228 + 0.065;
  
  paquet.roulis = data.r % 180;   //Les données du gyroscope sont mit au modulo pour pouvoir faire un tour complet
  paquet.tangage = data.t % 180;
  paquet.lacet = data.l % 180;
  paquet.pression = short(a);
  paquet.pourcentage_batterie = int(map(batterie, 10.5,12.6,0,100));
  paquet.orientation = int(map(orientation, 0, 360, 0,255));
  /*Serial.print(paquet.roulis);            //Affichage des valeurs sur le moniteur de série (facultatif)
  Serial.print(",");
  Serial.print(paquet.tangage);
  Serial.print(",");
  Serial.print(paquet.lacet);
  Serial.print(",");
  Serial.print(paquet.pression);
  Serial.print(",");
  Serial.print(paquet.pourcentage_batterie);
  Serial.print(",");
  Serial.print(paquet.orientation);
  Serial.println(" ");
  */
  radio.write(&paquet, 10);          //Transfert de la structure de 9 octet
  
  Serial.println(batterie);
}

#include <Arduino.h>
#include <SPI.h>       //Librairies nécessaires pour le transfert
#include <nRF24L01.h>
#include <RF24.h>


const uint64_t adresse = 12345;    //Adresse de la radio

RF24 radio(7, 8);  // Déclaration de la radio et affectation des pins 7 (CE) et 8 (CS) de l'arduino 

typedef struct {
  short roulis = 0;
  short tangage = 0;
  short lacet = 0;                //Structure du paquet de 9 octets envoyés, les 3 shorts sont nécessaires car les valeures sont des entiers relatifs
  short pression = 0;
  byte pourcentage_batterie = 0;
  byte orientation = 0;
}
MyData;
MyData paquet;


/**************************************************/

void setup()
{    Serial.begin(9600);    //Initialisation du port de série
  radio.begin();  
  radio.setPALevel(RF24_PA_MIN);
  radio.setDataRate(RF24_250KBPS); // Initialisation de la radio
  radio.setAutoAck(false);

  radio.openReadingPipe(1,adresse);
  radio.startListening();

}

/**************************************************/


void loop()
{
  if(radio.available() != 0){
   radio.read(&paquet, 10);        //Lecture des paquets entrants
  }


    
 
  Serial.print(paquet.roulis);      //Transmission des données via le port de Série
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
  Serial.print(",");
  Serial.print("&");
  Serial.println("");
  delay(150);

}

/**************************************************/







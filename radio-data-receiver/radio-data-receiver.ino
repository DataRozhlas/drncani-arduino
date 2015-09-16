/* YourDuinoStarter Example: nRF24L01 Receive Joystick values

 - WHAT IT DOES: Receives data from another transceiver with
   2 Analog values from a Joystick or 2 Potentiometers
   Displays received values on Serial Monitor
 - SEE the comments after "//" on each line below
 - CONNECTIONS: nRF24L01 Modules See:
 http://arduino-info.wikispaces.com/Nrf24L01-2.4GHz-HowTo
   1 - GND
   2 - VCC 3.3V !!! NOT 5V
   3 - CE to Arduino pin 9
   4 - CSN to Arduino pin 10
   5 - SCK to Arduino pin 13
   6 - MOSI to Arduino pin 11
   7 - MISO to Arduino pin 12
   8 - UNUSED

 - V1.00 11/26/13
   Based on examples at http://www.bajdi.com/
   Questions: terry@yourduino.com */

/*-----( Import needed libraries )-----*/
#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>
/*-----( Declare Constants and Pin Numbers )-----*/
#define CE_PIN   8
#define CSN_PIN 53 // 53 Mega, 10 Nano

// NOTE: the "LL" at the end of the constant is "LongLong" type
const uint64_t pipe = 0xE8E8F0F0E2LL; // Define the transmit pipe

// 0xE8E8F0F0E1LL 0xE8E8F0F0E2LL
/*-----( Declare objects )-----*/
RF24 radio(CE_PIN, CSN_PIN); // Create a Radio
/*-----( Declare Variables )-----*/
#define PAYLOAD_SIZE 32
byte data[PAYLOAD_SIZE];
unsigned long lastTime = NULL;

void setup()   /****** SETUP: RUNS ONCE ******/
{
  Serial.begin(115200);
  Serial.println("Receiver Starting");
  radio.begin();
  radio.openReadingPipe(1, pipe);
  radio.setDataRate(RF24_2MBPS);
  radio.startListening();
  radio.setAutoAck(true);
  radio.setPayloadSize(PAYLOAD_SIZE);
  //  pinMode(3, INPUT);
}//--(end setup )---


void loop()   /****** LOOP: RUNS CONSTANTLY ******/
{
  if ( radio.available() )
  {
    unsigned long time = micros();
    radio.read( data, PAYLOAD_SIZE);
    for (uint8_t i = 0; i < PAYLOAD_SIZE; i ++) {
      Serial.write(data[i]);
    }
//    for (uint8_t i = 0; i < PAYLOAD_SIZE; i += 2) {
//      int16_t AcX = data[i] << 8 | data[i + 1];
//      Serial.println(AcX);
//    }
  }
}

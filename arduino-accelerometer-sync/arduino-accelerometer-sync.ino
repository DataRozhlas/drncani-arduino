// MPU-6050 Short Example Sketch
// By Arduino User JohnChi
// August 17, 2014
// Public Domain

#include <Wire.h>
#include <TimerOne.h>
#include <SPI.h>
#include <nRF24L01.h>
#include <RF24.h>

#define CE_PIN   8
#define CSN_PIN 10

const uint64_t pipe = 0xE8E8F0F0E1LL; // Define the transmit pipe
RF24 radio(CE_PIN, CSN_PIN); // Create a Radio

const int MPU=0x68;  // I2C address of the MPU-6050


volatile byte buf1[32];
volatile byte buf2[32];
volatile byte buf3[32];
volatile byte buf4[32];
volatile byte buf5[32];
volatile byte buf6[32];

volatile uint8_t counter1;

volatile uint8_t counter2;

volatile bool secondBuffer = false;
volatile bool overflow = false;

void setup(){
  Serial.begin(115200);
  Serial.println("Transmitter starting");
  radio.begin();
  radio.openWritingPipe(pipe);
  radio.setRetries(5,2);
  radio.setDataRate(RF24_2MBPS);
  pinMode(13, OUTPUT);
  Wire.begin();
  Wire.beginTransmission(MPU);
  Wire.write(0x6B);  // PWR_MGMT_1 register
  Wire.write(0);     // set to zero (wakes up the MPU-6050)
  Wire.endTransmission(true);
  
  Wire.beginTransmission(MPU);
  Wire.write(0x1C); // accelerometer config
  Wire.write(24); // set sensitivity 16g
  Wire.endTransmission(true);
  
  Timer1.initialize(1000);
  Timer1.attachInterrupt(readData);
}


void loop() {
//  if (overflow) {
//    noInterrupts();
//    while(1) {};
//  }
  
  if (counter1 >= 96 || counter2 >= 96) {
    noInterrupts();
    byte data1[32];
    byte data2[32];
    byte data3[32];
    if (counter1 >= 96) {
      memcpy((char*)data1, (char*)buf1, 32);
      memcpy((char*)data2, (char*)buf2, 32);
      memcpy((char*)data3, (char*)buf3, 32);
      counter1 = 0;
    } else {
      memcpy((char*)data1, (char*)buf4, 32);
      memcpy((char*)data2, (char*)buf5, 32);
      memcpy((char*)data3, (char*)buf6, 32);
      counter2 = 0;
    }
    interrupts();
    radio.writeFast(&data1, 32);
    radio.writeFast(&data2, 32);
    radio.writeFast(&data3, 32);
    radio.txStandBy(1000);
    int16_t AcX = data1[0] << 8 | data1[1];
//    Serial.println(AcX);
    Serial.println(millis());
  }
}

void readData(){
  interrupts();
  Wire.beginTransmission(MPU);
  Wire.write(0x3B);  // starting with register 0x3B (ACCEL_XOUT_H)
  Wire.endTransmission(false);
  Wire.requestFrom(MPU,2,true);
  byte acc_msb = Wire.read();
  byte acc_lsb = Wire.read();
  noInterrupts();

  if (secondBuffer == false) {
    if (counter1 == 96) {
      overflow = true;
    } else {
      uint8_t bufferPosition = counter1 % 32;
      if (counter1 < 32) {
        buf1[bufferPosition] = acc_msb;
        buf1[bufferPosition + 1] = acc_lsb;
      } else if (counter1 < 64) {
        buf2[bufferPosition] = acc_msb;
        buf2[bufferPosition + 1] = acc_lsb;
      } else {
        buf3[bufferPosition] = acc_msb;
        buf3[bufferPosition + 1] = acc_lsb;
      }
      counter1 += 2;
      if (counter1 == 96) {
        secondBuffer = true;
      }
    }
  } else {
    if (counter2 == 96) {
      overflow = true;
    } else {
      uint8_t bufferPosition = counter2 % 32;
      if (counter2 < 32) {
        buf4[bufferPosition] = acc_msb;
        buf4[bufferPosition + 1] = acc_lsb;
      } else if (counter2 < 64) {
        buf5[bufferPosition] = acc_msb;
        buf5[bufferPosition + 1] = acc_lsb;
      } else {
        buf6[bufferPosition] = acc_msb;
        buf6[bufferPosition + 1] = acc_lsb;
      }
      counter2 += 2;
      if (counter2 == 96) {
        secondBuffer = false;
      }
    }
  }
}


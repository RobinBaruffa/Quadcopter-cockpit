# Quadcopter-cockpit

A homemade quadcopter recreating a real aircraft cockpit with embedded Arduino, FPV stream, Processing ground interface

Here is the end result : 


# Cockpit

![](https://raw.githubusercontent.com/RobinBaruffa/Quadcopter-cockpit/master/ezgif-5-6fd5f79d7679.gif)



# The quadcopter itself

![](https://raw.githubusercontent.com/RobinBaruffa/Quadcopter-cockpit/master/P1080888.JPG)

The quadcopter is entirely custom built from scratch, with a 3S 5'500mAh, MarsPower 920kv motors, 1045 propellers & CC3D flight controller

The quadcopter has an electronic circuit embedded with an Arduino microcontroller sending telemetry data from different sensor (accelerometer MPU6050, gyroscope GY-271, altimeter/pressure sensor BMP180). All the informations are encapsulated in a csv format packet to be sent by a NRF24l01+ 2.4Ghz module to an Arduino on the ground.
The Arduino then transfer the data to the Processing program via serial protocol. In parallel an embedded camera streams using a 5.8 Ghz transmitter/receiver that is fed to the Processing program through an RCA to USB adapter.
Then the code manages the real time display of the quadcopter instruments.

# PCB design

I have designed a PCB with Eagle to support all the sensors and the microcontroller, /!\ this is not tested 

![](https://raw.githubusercontent.com/RobinBaruffa/Quadcopter-cockpit/master/Capture-4.png)

# Improved radio transmitter

![](https://raw.githubusercontent.com/RobinBaruffa/Quadcopter-cockpit/master/IMG_20160310_191556.jpg)

The radio receiver and transmitter has been modified to improve range and battery life



Realized during the ISN course taught at Centre International de Valbonne, CIV, 2016

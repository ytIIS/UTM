// wartosc[1] = droga pokonana wartosc[3]= sila wartosc[4 i 5]=ADC0
// wartosc[6 i 7]=DIG input
//
import processing.serial.*;  // zwiazane z portem RS232
import java.util.*;          // zwiazane z data
import java.text.*;          // zwiazane z tekstem
import controlP5.*;          // jakas grafika 

Serial myPort;  // Create object from Serial class
//short portIndex = 2;  // numer portu com w tabilizy i tak 0 = COM1 1= COM2 itd 
int portIndex=2;        //
PrintWriter output;
BufferedReader ustawienia;       // plik do odczytu 
String NazwaPort;
DateFormat fnameFormat= new SimpleDateFormat("yyMMdd_HHmm");
DateFormat timeFormat = new SimpleDateFormat("hh:mm:ss");
String fileName;
String val;     // Data received from the serial port
Chart myChart;
Chart myChart1;

float knobValue = 219;
Knob myKnobA;
float knobValue1 = 1219;
Knob myKnobB;

float setTravel=-1;
float setSpeed=10;

int status_maszyny;
float wartosci[]={1,1,1,1,1,1,1,1};
int licznik=0;
// blok danych skopiowanych z przykladu nie wiem co to
ControlP5 cp5;
int myColor = color(255);
int c1,c2;
float n,n1;
// koniec skopiowanych 


void setup()
{
  //
  size(1050,800);
  noStroke();
  cp5 = new ControlP5(this);
  // ###################################
  // ### Plik konfiguracji
  ustawienia=createReader("data/Ustawienia.txt");
  try{
  NazwaPort = ustawienia.readLine();
  }catch (IOException e) {
    e.printStackTrace();
    NazwaPort = null;
    }
  if (NazwaPort == null) {
    // Stop reading because of an error or file is empty
    noLoop();  
  } else {
    String[] pieces = split(NazwaPort,';');
    portIndex = int(pieces[0]);
    setSpeed = float(pieces[1]);
    
  //  short portIndex = x;
  //  int y = int(pieces[1]);
   // point(x, y);
  }
  //
  // włacanie komunikacji 
  cp5.addToggle("Zapisz_do_pliku")
     //.setValue(0)          // wysyłana wartosc 
     .setPosition(10,10)  // X a potem Y d gornego rogu lewego
     .setSize(100,40)
     .setValue(true)
     .setMode(ControlP5.SWITCH)
     ;
   // funkcja przygotowania pomiaru tzw homing  
     cp5.addButton("Homing")
     .setValue(0)
     .setPosition(10,80)
     .setSize(100,19)
     ;  
    // funkcja ESTOP 
     cp5.addButton("EStop")
     .setValue(0)
     .setPosition(10,120)
     .setSize(100,19)
     ;  
     // funkcja przygotowania pomiaru tzw homing  
     cp5.addButton("Test")
     .setValue(0)
     .setPosition(10,160)
     .setSize(100,19)
     ;  
     
    // funkcja przygotowania pomiaru szybki zjazd w miejsce itd
     cp5.addButton("Set_Test")
     .setValue(0)
     .setPosition(10,200)
     .setSize(100,40)
     ; 
     
    // funkcja odczytu live  bez zapisu
     cp5.addButton("Read_OUT")
     .setValue(0)
     .setPosition(10,240)
     .setSize(100,40)
     ; 
   // wykres 
    myChart = cp5.addChart("TravelForce")
               .setPosition(10, 350)
               .setSize(600, 300)
               .setRange(0, 200)
               .setView(Chart.LINE) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
               .setStrokeWeight(1.5)
               .setColorCaptionLabel(color(40))
               ;
  myChart.addDataSet("incoming");
  myChart.setData("incoming", new float[100]);
  
     // wykres 
    myChart1 = cp5.addChart("Force")
               .setPosition(630, 350)
               .setSize(400, 300)
               .setRange(-800, 800)
               .setView(Chart.LINE) // use Chart.LINE, Chart.PIE, Chart.AREA, Chart.BAR_CENTERED
               .setStrokeWeight(0.5)
               .setColorCaptionLabel(color(170))
               ;
  myChart1.addDataSet("incoming");
  myChart1.setData("incoming", new float[100]);
  
// gałka
  myKnobA = cp5.addKnob("Travel")
               .setRange(0,219)
               .setValue(50)
               .setPosition(290,10)
               .setRadius(160)
               .setDragDirection(Knob.VERTICAL)
               ;
  myKnobB = cp5.addKnob("Speed")
               .setRange(0,160)
               .setValue(setSpeed)
               .setPosition(610,10)
               .setRadius(160)
               .setDragDirection(Knob.VERTICAL)
               ;
                                 
  println("Power UP");
  String portName = Serial.list()[portIndex];
  println(Serial.list());
  println(" Connecting to -> " + Serial.list()[portIndex]);
  myPort = new Serial(this, portName, 115200);
  myPort.clear();        // wyczyśc port ze smieci
  myPort.clear();        // wyczyśc port ze smieci
}

// ########################################################
// # File creaton 
// ########################################################
void tworzenie_pliku(){
  Date now = new Date();
  fileName = fnameFormat.format(now);
  output = createWriter(fileName + ".csv"); // save the file in the sketch folder
}

// ###########################################
// #  Funkcja rysuje obiekty na ekranie GUI
// ###########################################
void draw()
{  
  background(1);
  // ##########################################
  // ## wyswietlamy wartosci na zywo
   String WartoscText=str(wartosci[1]);
     text(WartoscText,130, 30);
   String WartoscText2=str(wartosci[3]);
     text(WartoscText2,190, 30);
   String WartoscText3=str(wartosci[4]);
     text(WartoscText3,240, 30);
   String WartoscText4=str(wartosci[6]);
     text(WartoscText4,290, 30);
     // ####################################
     // ######## potrzebne do wykresu 
     // to ponizej pszewua w osi X 
     float droga=wartosci[1]*(-1);  // zamieniamy droge z - na +
     myChart.push("incoming",droga); 
     
     float sila=wartosci[3];  // 
     myChart1.push("incoming",sila); 
   
 if (status_maszyny==1){ 
    if (frameCount % 19 == 0) {  // Every 18 frames request new data
      thread("requestData");
    }
 }
 
  if (status_maszyny==2){ 
    if (frameCount % 19 == 0) {  // Every 18 frames request new data
      thread("requestData2");
    }
 }
 
}

public void controlEvent(ControlEvent theEvent) {
  println(theEvent.getController().getName());
  n = 0;
}

// homing
public void Homing() {
  println("Performing Homing function - wait  ");
  myPort.write("^RD");   // wysyłamy do maszyny funkcje zerowanie - 
  delay(4000);            // odczekaj 4 sekundy 
  myPort.clear();
}

// ################################## 
// ##  emerg STOP
// ##################################
public void EStop() {
  println("EStop move");
  myPort.write("^CT");   // wysyłamy sterowanie
   delay(500);
   myPort.write(0x18);   // wysyłamy do grbl bajt 18
    delay(1000);
  myPort.write("^CT");   // wyjdz z trybu sterowania reuchem
  delay(100);
  myPort.clear();
}

//  ##############################################################################
//  ## wchodzi w tryb sterowania maszyny , wysyła dane , tworzy plik , czysci port
// ruch testowy - przykład zachowania
public void Test() {
     if (status_maszyny == 2 ){ 
       status_maszyny=0;
   }
  print("Move G1 ");
  myPort.write("^CT");   // wysyłamy sterowanie
   delay(480);
   myPort.write("G1 X"); //X-30 F30\n");   // wysyłamy sterowanie
   String trS=nf(setTravel);
   myPort.write(trS);
   myPort.write(" F");
   String spS=nf(setSpeed);
   myPort.write(spS);
   myPort.write("\n");
   print(trS);
   print(" F");
   print(spS);
   println(" <lf>");
   delay(250);
   // pausa przy punkcie zerowym 2 sekundy
   //myPort.write("G4P2");        // #############################################
  // myPort.write("\r");         // ## PAUSA 2 sekundy !!!!!!!!!!!!!!!!!!!!!!!!!
   //myPort.write("\n");         // #######################
   //delay(100);
   // ruch wstecz o 3 mm
   myPort.write("G1 X"); //X-30 F30\n");   // wysyłamy sterowanie  
   String trSb=nf(setTravel+13);
   myPort.write(trSb);
   delay(10);
   myPort.write(" F");
   myPort.write(spS);
   //myPort.write("\r");
   myPort.write("\n");
   delay(680);
  myPort.write("^CT");   // wyjdz z trybu sterowania reuchem
   //delay(680);
  myPort.clear();        // wyczyśc port ze smieci
  tworzenie_pliku();      // funkcja tworząca plik z datą
  status_maszyny=1;
}


//  ##############################################################################
//  ## wchodzi w tryb sterowania maszyny , wysyła dane  NIE tworzy pliku        ##
//  ## Ustawiamy pozycję                                                       ###
public void Set_Test() {
   if (status_maszyny == 2 ){ 
       status_maszyny=0;
   } 
  myPort.clear();        // wyczyśc port ze smieci
  print("Move G1 ");
  myPort.write("^CT");   // wysyłamy sterowanie
   delay(900);
   myPort.write("G1 X"); //X-30 F30\n");   // wysyłamy sterowanie
   String trS=nf(setTravel);
   delay(10);
   myPort.write(trS);
   myPort.write(" F");
   String spS=nf(setSpeed+900);
   myPort.write(spS);
   //delay(10);
   myPort.write("\n");
   delay(900);
   myPort.write("^CT");   // wyjdz z trybu sterowania reuchem
  // print(trS);
  // print(" F");
  // print(spS);
  // println(" <lf>");
  // delay(80);
   //delay(100);
   myPort.clear();        // wyczyśc port ze smieci
  //tworzenie_pliku();      // funkcja tworząca plik z datą
  //status_maszyny=1;

}
// #####################################################################
// ## wlaczenie odczytu na zywi                                       ##
// ## ##################################################################
public void Read_OUT() {

 if (status_maszyny !=2 ){ 
  myPort.clear();        // wyczyśc port ze smieci
  print("Move G1 ");
  myPort.write("^CT");   // wysyłamy sterowanie
  delay(900);
   myPort.write("G1 X"); //X-30 F30\n");   // wysyłamy sterowanie
   String trS=nf(setTravel);
   myPort.write(trS);
   myPort.write(" F");
   String spS=nf(setSpeed);
   myPort.write(spS);
   //myPort.write("\r");
   myPort.write("\n");
   //delay(1);
   print(trS);
   print(" F");
   print(spS);
   println(" <lf>");
   delay(800);
  myPort.write("^CT");   // wyjdz z trybu sterowania reuchem
  delay(400);
  myPort.clear();        // wyczyśc port ze smieci
 }
 
  if (status_maszyny ==2 ){ 
  status_maszyny=3;
   myPort.clear();        // wyczyśc port ze smieci
  print("Move G1 ");
  myPort.write("^CT");   // wysyłamy sterowanie
  delay(500);
   myPort.write("G1 X"); //X-30 F30\n");   // wysyłamy sterowanie
   String trS=nf(setTravel);
   myPort.write(trS);
   myPort.write(" F");
   String spS=nf(setSpeed);
   myPort.write(spS);
   //myPort.write("\r");
   myPort.write("\n");
   //delay(1);
   print(trS);
   print(" F");
   print(spS);
   println(" <lf>");
   delay(800);
  myPort.write("^CT");   // wyjdz z trybu sterowania reuchem
   delay(500);
  myPort.clear();        // wyczyśc port ze smieci
 
 }
  status_maszyny=2;
}

// ####################################################
// zapytanie o wartosci do pliku
void requestData() {
  myPort.write("^ST");   // wysyłamy zapytanie o wartosci 
   delay(5);
   if ( myPort.available() > 0) 
      {
        val = myPort.readStringUntil('#');
        //val=val.replace("!;MOVE_END#","");
        val = val.replace("!", "");        // usuwamy zbedne znaki
        val = val.replace("#", "");        // usuwamy zbedne znaki
        wartosci=float(split(val,';'));
        output.print(val);
        output.print('\r');
        output.print('\n');
        println(val);
      }
}

// ####################################################
// ## zapytanie o wartosci do livep
// ##########################################
void requestData2() {
  //delay(100);
  myPort.write("^ST");   // wysyłamy zapytanie o wartosci 
    delay(2);
   if ( myPort.available() > 0) 
      {
        val = myPort.readStringUntil('#');
        //delay(20);
        val = val.replace("!", "");        // usuwamy zbedne znaki
        val = val.replace("#", "");        // usuwamy zbedne znaki
        wartosci=float(split(val,';'));
        println(val);
      }
}




// wlacznik i wylacznik - w zamysle ma otwierac port i plik zamykac 
// podłączanie do portu przycisk togle
void Zapisz_do_pliku(boolean theFlag) {
  status_maszyny=0;
  output.flush();  // Writes the remaining data to the file
  output.close();  // Finishes the file
  println("Writing to file OK!");
  
  if(theFlag==true) {
    if ( myPort.available() > 0) 
      {  
        val = myPort.readStringUntil('#');         // read it and store it in val
        if (val.equals("!PWR#") == true) {
              delay(1000);
              //println("Połączenie OK!");
              val="";
            }
      }
    } else {
    // tu trzeba port zamknąć !!!!!!!!!!!!!!!!!!
    }

}

// #######################################
// # Zmiana koncowego punktu z + na -
// ######
void Travel(float theValue) {
  setTravel = theValue*(-1);
  println("Zmiana punkut koncowego do "+setTravel);
}

void Speed(float theValue2) {
  setSpeed = theValue2;
  println("Zmiana predkosci na "+setSpeed);
}

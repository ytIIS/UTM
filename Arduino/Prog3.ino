// TEN SOFT TO TO SAMO CO Prog2 ale ma stoper do pomiaru czasu odpowiedzi !!!
// ^ST = status systemu - bez znaku konca linii
// ^CT = wejscie/wyjscie w sterowanie GRBL port nr 1 bez znaku
//
//char inData[20]; // Allocate some space for the string
//char inChar = -1; // Where to store the character read
//byte index = 0; // Index into array; where to store the character
//
// Wystartuj i Zatrzymaj - zmienne do pomiaru
unsigned long Wystartuj,Zatrzymaj;
int wynik;

byte Licznik=0;
byte stat = 0; // status programu

String buf = "";
String grb = "";
String frc = "";
// statusy analogowe i digital
int sensVal0 =0;
int sensVal1 =0;
int digi2 = 0;
int digi3 = 0;
int digi4 = 0;
int digi5 = 0;
//

void setup() {
  // initialize both serial ports:
  Serial.begin(115200);
  Serial1.begin(115200);
  Serial2.begin(115200);
  Serial.setTimeout(10);              // limit czasu 1s
  Serial1.setTimeout(10);              // limit czasu 1s
  Serial2.setTimeout(100);              // limit czasu 1s
  pinMode(2,INPUT_PULLUP);
  pinMode(3,INPUT_PULLUP);
  pinMode(4,INPUT_PULLUP);
  pinMode(5,INPUT_PULLUP);
  //Serial.print("!PWR#");
  //Serial.print('\n');
}



void loop() {

  if (Serial.available()) {
    buf = Serial.readString();       // odczytaj 4 bajty
    // memset("/0", buf, sizeof(buf));    // czyszcenie tablicy charow do 0
    if (buf == "^ST") {
       Wystartuj=millis();
     //  buf="";
      czytaj();                         // przeskocz do funkcji odczytywania
      Zatrzymaj=millis();
      Licznik=1;
    }
    if (buf == "^CT") {
      stat = 1;
      steruj();// przeskocz do funkcji odczytywania
    }

   if (buf == "^TT") {
      Licznik=0;
      wynik=Zatrzymaj-Wystartuj;
      Serial.print("Wynik ");
      Serial.println(wynik);
      wynik=0;
      //Serial.println(Zatrzymaj);
              
    }
    if (buf == "^TR") {                         // zerowanie sily
      taruj();// przeskocz do funkcji tarowanoa
    }
    if (buf == "^RD") {                         // przygotowanie maszyny do startu
      rd();// przeskocz do funkcji tarowanoa
    }
     if (buf == "?") {
      pomoc();                         // przeskocz do funkcji odczytywania
    }
  }
}

// ########################################################################################
// ##   podprogram statusu systemu wysyla znak ? na port 1 i wkleja na port0 wyjscie to samo 
// ##  z portem 2 i statusami digital i analog
// ##########################
void czytaj() {
  Serial.print("!");
  Serial1.print("?");
  delay(10);
  if (Serial1.available()) {
    //int inByte = Serial1.read();
    grb = Serial1.readString();
    Serial.print(grb);
  }
  Serial2.print("?");
  delay(5);
  if (Serial2.available()) {
    //int inByte = Serial1.read();
    frc = Serial2.readString();
    Serial.print(frc);
  }
  sensVal0=analogRead(A0);
  sensVal1=analogRead(A1);
  digi2=digitalRead(2);
  digi3=digitalRead(3);
  digi4=digitalRead(4);
  digi5=digitalRead(5);
  Serial.print(sensVal0);
  Serial.print(";");
  Serial.print(sensVal1);
  Serial.print(";");
  Serial.print(digi2);
  Serial.print(";");
  Serial.print(digi3);
  Serial.print(";");
  Serial.print(digi4);
  Serial.print(";");
  Serial.print(digi5);
  Serial.print("#");    // println wylaczone nie potzebna
  buf="";
}

// ##################################################################
// ##   komunikacja ze GEBL
// ###################################################################
void steruj() {
  buf = "";
  while (stat == 1) {
    if (Serial.available()) {
      buf = Serial.readString();       // odczytaj
          if (buf == "^CT") {
           stat = 0;
           buf="";
          }
      
      Serial1.print(buf);
    }
    if (Serial1.available()) {
      grb = Serial1.readString();       // Zapisz
      Serial.print(grb);
    }

   //   Serial.print(";MOVE_END#");
    
  }
}

// ##################################################################
// ##   komunikacja ze tensometrem - wyslanie na port nr 2 wykrzyknika do tarowania
// ###################################################################
void taruj() {
  Serial.println("!ZERO");
  Serial2.print("!");
   Serial.print(";ZERO_END#");
}


// ##################################################################
// ##   zerowanie maszyny do stanu gotwy do uzycia
// ###################################################################
void rd() {
  Serial.println("!REDY");
  Serial2.print("!");
  Serial1.write(0x18);
  delay(1250);
  //delay(250);
  grb = Serial1.readString();       // 
  grb = Serial1.readString();       // 
  grb = Serial1.readString();       // 
  Serial1.println("$h");
  //delay(2250);
  delay(1250);
  grb = Serial1.readString();       // czysc bufor
  Serial.print(";REDY_END#");
}


// ##################################################################
// ##   help
// ###################################################################
void pomoc() {
  Serial.println("!HELP");
  Serial.println("^CT = move control GRBL1.1");
  Serial.println("   $h <lf> = home machine");
  Serial.println("   $x <lf> = unlock");
  Serial.println("   G1 X-2 F100 <lf> - examp move");
  Serial.println("   0x18 - reset ");
  Serial.println("   ? - status x ");
  Serial.println("^ST = status readout");
  Serial.println("^TR = force zero");
  Serial.println("^TT = czas reakcji na odczyt - ostatni");
  Serial.println("^RD = machine redy grbl zero , homing on , force zero");
  Serial.println(";HELP_END#");
}

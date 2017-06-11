import processing.serial.*;

Serial port;
String texto = "Testando!       Twitter Hardwarepor:Bruno Soares:-)";

void setup() {
  println(Serial.list());
  port = new Serial(this, Serial.list()[1], 9600);
}

void draw() { }

void mousePressed () {
  port.write('^'); // MESSAGE_START
  for (int i = 0; i < texto.length(); i++) {
    port.write(texto.charAt(i));
  }
  port.write('~'); // MESSAGE_END
  delay(2000);
}

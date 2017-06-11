/**
 * Twitter Hardware
 * 
 * @author   Bruno Soares
 * @link     http://www.bsoares.com.br
 * @date     27/10/2008
 * @language Arduino / C++
 */

// Includes
#include <LiquidCrystal.h>

// Defines
#define DEBUG_PIN                 13

#define COMMAND_RIGHT             0
#define COMMAND_LEFT              1
#define QUANTITY_COMMANDS         2

#define ANALOG_PIN_COMMAND_RIGHT  0
#define ANALOG_PIN_COMMAND_LEFT   1
#define ANALOG_PIN_SPEED          2

#define MESSAGE_START             94  //  94 = ^
#define MESSAGE_END               126 // 126 = ~

#define SERIAL_BOUND              9600

#define LCD_LINES                 2
#define LCD_COLUMNS               16

#define ANIMATE_CMD_WIDTH         4

// Global variables
unsigned long time;

// LiquidCrystal display with:
// rs on pin 12
// rw on pin 11
// enable on pin 2
// dbs 3, 4, 5, 6, 7, 8, 9, 10
LiquidCrystal lcd(12, 11, 2, 3, 4, 5, 6, 7, 8, 9, 10);

// Analog configuration
unsigned int analogCmd[QUANTITY_COMMANDS];
unsigned int analogSpeed = 0;

// Control commands
boolean changingSpeed = true;
boolean readingSerial = false;
boolean pressedCmd[QUANTITY_COMMANDS];
unsigned int lastSpeed = 0;

// Massages
char currentMessage[400] = "No messages.";
unsigned int currentMessageLenght;

// ------------------------------------------------------------------------ \\
// Program
void setup() {
  Serial.begin(SERIAL_BOUND);
  pinMode(DEBUG_PIN, OUTPUT);
  
  smartDelay(10);
  lastSpeed = analogSpeed;
  
  presentation();
  changingSpeed = false;
}

void loop() {
  
  // Show current message
  clearLcd();
  writeLongTextInLcd(currentMessage);
  smartDelay(applySpeed(7000));
  
}

void presentation() {
  lcd.clear();
  writeLongTextInLcd("Twitter Hardwareby Bruno Soares");
  smartDelay(3000);
}

void refreshAnalogVars() {
  analogCmd[COMMAND_RIGHT] = analogRead(ANALOG_PIN_COMMAND_RIGHT);
  analogCmd[COMMAND_LEFT]  = analogRead(ANALOG_PIN_COMMAND_LEFT);
  analogSpeed              = analogRead(ANALOG_PIN_SPEED);
}

// ------------------------------------------------------------------------ \\
// [INI] Commands
void detectCommand() {
  unsigned int i = 0;
  while (i < QUANTITY_COMMANDS) {
    if (analogCmd[i] > 500 && !pressedCmd[i]) {
      executeCommand(i);
    }
    i++;
  }
}

void executeCommand(int command) {
  pressedCmd[command] = true;
  digitalWrite(DEBUG_PIN, 1);
  
  if (command == 0) {
    animateNext();
  } else {
    animatePrevious();
  }
  
  currentMessage[0] = 'L';
  currentMessage[1] = 'o';
  currentMessage[2] = 'a';
  currentMessage[3] = 'd';
  currentMessage[4] = 'i';
  currentMessage[5] = 'n';
  currentMessage[6] = 'g';
  currentMessage[7] = '\0';
  currentMessageLenght = 7;
  
  Serial.print(command);
  
  while (analogCmd[command] > 500) {
    smartDelay(4);
  }
  
  pressedCmd[command] = false;
  digitalWrite(DEBUG_PIN, 0);
}

void animateNext()  {
  for (unsigned int i = 0; i < LCD_COLUMNS + ANIMATE_CMD_WIDTH; i++) {
    if (i < LCD_COLUMNS) {
      lcd.setCursor(i, 0);
      lcd.print(">");
      lcd.setCursor(i, 1);
      lcd.print(">");
    }
    delay(5);
    if (i - ANIMATE_CMD_WIDTH >= 0) {
      lcd.setCursor(i - ANIMATE_CMD_WIDTH, 0);
      lcd.print(" ");
      lcd.setCursor(i - ANIMATE_CMD_WIDTH, 1);
      lcd.print(" ");
    }
    delay(30);
  }
}

void animatePrevious() {
  for (int i = LCD_COLUMNS; i >= -ANIMATE_CMD_WIDTH; i--) {
    if (i >= 0 && i < LCD_COLUMNS) {
      lcd.setCursor(i, 0);
      lcd.print("<");
      lcd.setCursor(i, 1);
      lcd.print("<");
    }
    delay(5);
    if (i + ANIMATE_CMD_WIDTH < LCD_COLUMNS && i + ANIMATE_CMD_WIDTH >= 0) {
      lcd.setCursor(i + ANIMATE_CMD_WIDTH, 0);
      lcd.print(" ");
      lcd.setCursor(i + ANIMATE_CMD_WIDTH, 1);
      lcd.print(" ");
    }
    delay(30);
  }
}
// [END] Commands

// ------------------------------------------------------------------------ \\
// [INI] Messages
void detectSerialMessage() {
  if (Serial.available() > 0 && !readingSerial) {
    if (Serial.read() == MESSAGE_START) {
      serialReadMessage();
    }
  }
}

void serialReadMessage() {
  digitalWrite(DEBUG_PIN, 1);
  readingSerial = true;
  currentMessageLenght = 0;
  
  iniReading:
  if (Serial.available() > 0) {
    unsigned int _char = Serial.read();
    if (_char == MESSAGE_END) {
      goto endReading;
    } else {
      currentMessage[currentMessageLenght++] = _char;
      delay(2);
      goto iniReading;
    }
  }
  goto iniReading;
  
  endReading:
  currentMessage[currentMessageLenght] = '\0';
  digitalWrite(DEBUG_PIN, 0);
  readingSerial = false;
}
// [END] Messages

// ------------------------------------------------------------------------ \\
// [INI] LCD manipulation
void writeLongTextInLcd(char text[]) {
  writeInit:
  clearLcd();
  unsigned int cml = currentMessageLenght;
  int loops = -1;
  unsigned int chars = 1;
  while (text[loops++ + 1] != 0) {
    if (chars == 17) {
      lcd.setCursor(0, 1);
      smartDelay(applySpeed(600));
      if (cml != currentMessageLenght) goto writeInit;
    } else if (chars == 33) {
      smartDelay(applySpeed(3000));
      clearLcd();
      if (cml != currentMessageLenght) goto writeInit;
      chars = 1;
    }
    lcd.print(text[loops]);
    smartDelay(applySpeed(60));
    if (cml != currentMessageLenght) goto writeInit;
    chars++;
  }
  Serial.print(2);
}

void writeInLcd(char text[], int quantity) {
  for (unsigned int i = 0; i < quantity; i++) {
    if (text[i] == 0) {
      do {
        lcd.print(" ");
      } while (i++ < quantity);
      break;
    } else {
      lcd.print(text[i]);
    }
  }
  delay(2);
  //smartDelay(5);
}

void clearLcd() {
  lcd.setCursor(0, 0);
  smartDelay(5);
  lcd.print("                ");
  smartDelay(applySpeed(400));
  lcd.setCursor(0, 1);
  smartDelay(5);
  lcd.print("                ");
  lcd.setCursor(0, 0);
  smartDelay(applySpeed(0));
}
// [END] LCD manipulation

// ------------------------------------------------------------------------ \\
// [INI] Speed
void detectChangeSpeed() {
  if (changingSpeed) return;
  if (!(lastSpeed < analogSpeed + 6 && lastSpeed > analogSpeed - 6)) {
    showGraderSpeed();
  }
}

void showGraderSpeed() {
  changingSpeed = true;
  digitalWrite(DEBUG_PIN, 1);
  lcd.clear();
  writeInLcd("Speed:", LCD_COLUMNS);
  
  // Create display velocity
  showSpeed:
  for (unsigned int i = 0; i < 10; i++) {
    int charsSpeed = map(analogSpeed, 0, 1023, 0, LCD_COLUMNS);
    int percentSpeed = map(analogSpeed, 0, 1023, 0, 100);
    char* percentString;
    itoa(100 - percentSpeed, percentString, 10);
    percentString = strcat(percentString, "%");
    lcd.setCursor(7, 0);
    writeInLcd(percentString, 4);
    charsSpeed = LCD_COLUMNS - charsSpeed;
    lcd.setCursor(0, 1);
    for (unsigned int x = 1; x < LCD_COLUMNS + 1; x++) {
      if (x <= charsSpeed) {
        lcd.print(">");
      } else {
        lcd.print(" ");
      }
    }
    lastSpeed = analogSpeed;
    smartDelay(40);
  }
  
  // Verify
  for (unsigned int i = 0; i < 10; i++) {
    if (!(lastSpeed < analogSpeed + 6 && lastSpeed > analogSpeed - 6)) {
      goto showSpeed;
    }
    smartDelay(40);
  }
  
  // Finalize
  lcd.clear();
  changingSpeed = false;
  digitalWrite(DEBUG_PIN, 0);
}

long applySpeed (unsigned int value) {
  return map(analogSpeed, 0, 1023, 0, value);
}

// [END] Speed

// ------------------------------------------------------------------------ \\
// [INI] Milliseconds controller
void smartDelay(int milliseconds) {
  if (milliseconds < 2) {
    noDelayFunctions();
    delay(milliseconds);
    return;
  }
  do {
    delay(1);
    milliseconds -= noDelayFunctions();
    milliseconds -= 1;
  } while (milliseconds > 0);
}

int noDelayFunctions() {
  time = millis();
  
  // [INI] No delay functions here
  refreshAnalogVars();
  detectChangeSpeed();
  detectCommand();
  detectSerialMessage();
  // [END] No delay functions here
  
  return millis() - time;
}
// [END] Milliseconds controller

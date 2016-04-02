int ledPin0 = 2;
int ledPin1 = 3;
int ledPins[] = {2, 3, 5, 6, 9, 10, A0, A1};
#define ledArrayLength (sizeof(ledPins)/sizeof(int))


void setup() {
  for (int i=0; i<ledArrayLength; i++) {
    pinMode(ledPins[i], OUTPUT);
    delay(3);
  }
}

void loop() {
  for (int i=0; i<ledArrayLength; i++) {
    digitalWrite(ledPins[i], HIGH);
    delay(3);
  }

  delay(500);
  
  for (int i=0; i<ledArrayLength; i++) {
    digitalWrite(ledPins[i], LOW);
    delay(3);
  }
}

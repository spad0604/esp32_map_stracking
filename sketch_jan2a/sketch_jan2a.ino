#include "WiFi.h"
#include "SoftwareSerial.h"
#include "TinyGPS++.h"
#include "FirebaseESP32.h"

#define Rx 34
#define Tx 35

TinyGPSPlus gps;

const char* ssid = "Pixel 4XL";
const char* password = "06042004";

#define FIREBASE_HOST "esp32-tracking-c5aad-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "AIzaSyAeV_3moqByHDp8nGBNUr9tf8DdNAwDwng"

#define USER_EMAIL "giapbacvan@gmail.com"
#define USER_PASSWORD "06042004"

FirebaseData firebaseData;
FirebaseConfig firebaseConfig;
FirebaseAuth firebaseAuth;

SoftwareSerial mySerial = SoftwareSerial(Rx, Tx);

double savedLat = 21.00444;
double savedLon = 105.84678;
const float earthRadiusKm = 6371.0;
void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(1000);
  }

  mySerial.begin(9600);

  Serial.println(WiFi.localIP());

  firebaseConfig.host = FIREBASE_HOST;
  firebaseConfig.api_key = FIREBASE_AUTH;

  firebaseAuth.user.email = USER_EMAIL;
  firebaseAuth.user.password = USER_PASSWORD;

  Firebase.begin(&firebaseConfig, &firebaseAuth);
  Firebase.reconnectWiFi(true);
}

double timeSend = 0;

void loop() {
  while (mySerial.available() > 0) {
    char s = mySerial.read();
    Serial.print(s);
    if (gps.encode(s)) {
      if (gps.location.isValid()) {
        float latitude = gps.location.lat();
        float longitude = gps.location.lng();

        Serial.print("Vĩ độ: ");
        Serial.println(latitude, 6);
        Serial.print("Kinh độ: ");
        Serial.println(longitude, 6);
        
        double distance = haversineDistance(savedLat, savedLon, latitude, longitude);
        double speed = distance / timeSend;

        timeSend = 5;

        savedLat = latitude;
        savedLon = longitude;

        String path = "/data";
        
        Firebase.setFloat(firebaseData, path + "/LAT", latitude);
        Firebase.setFloat(firebaseData, path + "/LON", longitude);
        Firebase.setFloat(firebaseData, path + "/speed", speed);
        delay(5000);
      } else {
        delay(1000);
        timeSend += 1;
      }
    }
  } 
}

float haversineDistance(float lat1, float lon1, float lat2, float lon2) {
  float deltaLat = radians(lat2 - lat1);
  float deltaLon = radians(lon2 - lon1);

  float a = sin(deltaLat / 2) * sin(deltaLat / 2) +
            cos(radians(lat1)) * cos(radians(lat2)) *
            sin(deltaLon / 2) * sin(deltaLon / 2);
  
  float c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return earthRadiusKm * c * 1000.0; 
}

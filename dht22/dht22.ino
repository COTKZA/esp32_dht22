#include <WiFi.h>
#include <HTTPClient.h>
#include <DHT.h>
#include <ArduinoJson.h>

const char* ssid = "YOUR_SSID";
const char* password = "YOUR_PASSWORD";
const char* server_pin = "http://YOUR_SERVER/api_dht_pin.php";
const char* server_post = "http://YOUR_SERVER/api_dht_post.php";

DHT* dht;
int dht_pin = 2; // default

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("WiFi connected");

  // ดึง pin จาก database
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(server_pin);
    int code = http.GET();
    if (code == 200) {
      String payload = http.getString();
      DynamicJsonDocument doc(1024);
      deserializeJson(doc, payload);

      dht_pin = doc["pin"];
    }
    http.end();
  }

  dht = new DHT(dht_pin, DHT22);
  dht->begin();
}

void loop() {
  float h = dht->readHumidity();
  float t = dht->readTemperature();

  if (isnan(h) || isnan(t)) {
    Serial.println("Failed to read from DHT sensor!");
    delay(2000);
    return;
  }

  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(server_post);
    http.addHeader("Content-Type", "application/json");

    String payload = "{\"pin\":\"D" + String(dht_pin) + "\",\"temperature\":" + String(t) + ",\"humidity\":" + String(h) + "}";
    int httpResponseCode = http.POST(payload);

    if (httpResponseCode > 0) {
      Serial.println(http.getString());
    } else {
      Serial.println("Error sending POST");
    }

    http.end();
  }

  delay(10000);
}

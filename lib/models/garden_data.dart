import 'dart:convert';

class GardenData {
  double temperature = 0;
  double humidity = 0;
  double soilMoisture = 0;
  double distance = 0;
  bool isPumpOn = false;
  bool isBuzzerOn = false;
  bool isManualMode = false;
  String _buffer = ''; // Buffer to accumulate partial JSON data

  // Parse JSON data from Arduino
  void updateFromString(String data) {
    try {
      // Add incoming data to buffer
      _buffer += data;

      // Check if we have a complete JSON object
      if (_buffer.trim().startsWith('{') && _buffer.trim().endsWith('}')) {
        // Parse the complete JSON data
        final Map<String, dynamic> json = jsonDecode(_buffer);

        // Update values from JSON
        if (json.containsKey('temp')) {
          temperature = double.tryParse(json['temp'].toString()) ?? temperature;
        }

        if (json.containsKey('humidity')) {
          humidity = double.tryParse(json['humidity'].toString()) ?? humidity;
        }

        if (json.containsKey('soil')) {
          soilMoisture =
              double.tryParse(json['soil'].toString()) ?? soilMoisture;
        }

        if (json.containsKey('distance')) {
          distance = double.tryParse(json['distance'].toString()) ?? distance;
        }

        if (json.containsKey('pump')) {
          isPumpOn = json['pump'] == "ON";
        }

        if (json.containsKey('buzzer')) {
          isBuzzerOn = json['buzzer'] == "ON";
        }

        if (json.containsKey('mode')) {
          isManualMode = json['mode'] == "Manual";
        }

        // Clear buffer after successful parsing
        _buffer = '';
      }
    } catch (e) {
      // If we encounter an error, it might be due to incomplete JSON
      // Keep the buffer for the next data chunk
      print('Error parsing JSON data: $e');
    }
  }
}

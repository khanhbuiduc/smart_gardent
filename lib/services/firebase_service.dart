import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/garden_data.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save garden data to Firestore
  Future<void> saveGardenData(GardenData data) async {
    try {
      await _firestore.collection('garden_data').add({
        'temperature': data.temperature,
        'humidity': data.humidity,
        'soil_moisture': data.soilMoisture,
        'distance': data.distance,
        'pump_status': data.isPumpOn,
        'buzzer_status': data.isBuzzerOn,
        'mode': data.isManualMode ? 'Manual' : 'Auto',
        'moisture_threshold': data.moistureThreshold,
        'distance_threshold': data.distanceThreshold,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Data saved to Firebase');
    } catch (e) {
      print('Error saving data to Firebase: $e');
    }
  }

  // Get garden data from last 24 hours
  Future<List<Map<String, dynamic>>> getDataLast24Hours() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime oneDayAgo = now.subtract(const Duration(days: 1));

      final QuerySnapshot snapshot = await _firestore
          .collection('garden_data')
          .where('timestamp', isGreaterThan: oneDayAgo)
          .orderBy('timestamp', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Convert Firestore Timestamp to DateTime
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        return {
          ...data,
          'timestamp': timestamp,
        };
      }).toList();
    } catch (e) {
      print('Error getting data from Firebase: $e');
      return [];
    }
  }

  // Get average readings by day for the last week
  Future<List<Map<String, dynamic>>> getWeeklyAverages() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime oneWeekAgo = now.subtract(const Duration(days: 7));

      final QuerySnapshot snapshot = await _firestore
          .collection('garden_data')
          .where('timestamp', isGreaterThan: oneWeekAgo)
          .orderBy('timestamp', descending: false)
          .get();

      // Group by day and calculate averages
      final Map<String, List<Map<String, dynamic>>> groupedByDay = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final day =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

        if (!groupedByDay.containsKey(day)) {
          groupedByDay[day] = [];
        }

        groupedByDay[day]!.add(data);
      }

      // Calculate averages for each day
      final List<Map<String, dynamic>> result = [];

      groupedByDay.forEach((day, dataPoints) {
        double tempSum = 0;
        double humiditySum = 0;
        double soilSum = 0;

        for (var data in dataPoints) {
          tempSum += (data['temperature'] ?? 0).toDouble();
          humiditySum += (data['humidity'] ?? 0).toDouble();
          soilSum += (data['soil_moisture'] ?? 0).toDouble();
        }

        result.add({
          'date': day,
          'avg_temperature': tempSum / dataPoints.length,
          'avg_humidity': humiditySum / dataPoints.length,
          'avg_soil_moisture': soilSum / dataPoints.length,
          'count': dataPoints.length,
        });
      });

      return result;
    } catch (e) {
      print('Error getting weekly averages: $e');
      return [];
    }
  }
}

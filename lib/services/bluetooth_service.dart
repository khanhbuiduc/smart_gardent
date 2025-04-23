import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/garden_data.dart';
import '../services/firebase_service.dart';

class BluetoothService {
  // Bluetooth controller
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  // State variables
  List<BluetoothDiscoveryResult> discoveryResults = [];
  BluetoothDevice? connectedDevice;
  BluetoothConnection? connection;
  bool isScanning = false;
  bool isConnected = false;
  bool isPairing = false;
  bool _bluetoothPermissionGranted = false;
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSubscription;

  // Garden data
  final GardenData gardenData = GardenData();
  String lastMessage = "";

  // Firebase service
  final FirebaseService _firebaseService = FirebaseService();
  DateTime _lastDataSaved = DateTime.now().subtract(const Duration(minutes: 5));

  // Getters
  bool get bluetoothPermissionGranted => _bluetoothPermissionGranted;

  // Stream controller for state updates
  final _stateController = StreamController<void>.broadcast();
  Stream<void> get onStateChanged => _stateController.stream;

  // Timestamp for last button presses
  DateTime _lastPumpToggleTime =
      DateTime.now().subtract(const Duration(seconds: 1));
  DateTime _lastBuzzerToggleTime =
      DateTime.now().subtract(const Duration(seconds: 1));

  // Cooldown duration
  static const Duration _buttonCooldown = Duration(seconds: 1);

  // Request permissions and initialize Bluetooth
  Future<void> checkAndRequestPermissions(BuildContext context) async {
    // Request necessary permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    bool allGranted = true;
    for (var status in statuses.values) {
      if (!status.isGranted) {
        allGranted = false;
        break;
      }
    }

    _bluetoothPermissionGranted = allGranted;
    _stateController.add(null);

    if (!allGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Cần cấp quyền Bluetooth và vị trí để sử dụng ứng dụng này'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Initialize Bluetooth
    await _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    // Check if bluetooth is enabled
    bool? isEnabled = await _bluetooth.isEnabled;

    if (isEnabled != true) {
      // Request to enable bluetooth
      await _bluetooth.requestEnable();
    }
  }

  // Start scanning for Bluetooth devices
  void startScan() {
    discoveryResults = [];
    isScanning = true;
    _stateController.add(null);

    // Cancel previous discovery subscription if it exists
    _discoveryStreamSubscription?.cancel();

    // Start a new discovery process
    _discoveryStreamSubscription = _bluetooth.startDiscovery().listen(
      (result) {
        // We're looking for HC-05 or unknown devices that might be HC-05
        bool isRelevantDevice = result.device.name?.isEmpty == false;

        // Add or update the device in our list
        if (isRelevantDevice) {
          final existingIndex = discoveryResults
              .indexWhere((r) => r.device.address == result.device.address);

          if (existingIndex >= 0) {
            // Update existing device
            discoveryResults[existingIndex] = result;
          } else {
            // Add new device
            discoveryResults.add(result);
          }
          _stateController.add(null);
        }
      },
      onDone: () {
        isScanning = false;
        _stateController.add(null);
      },
      onError: (error) {
        isScanning = false;
        _stateController.add(null);
        print('Error scanning for devices: $error');
      },
    );

    // Auto-stop scanning after 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (isScanning) {
        _discoveryStreamSubscription?.cancel();
        isScanning = false;
        _stateController.add(null);
      }
    });
  }

  // Pair with a device before connecting
  Future<bool> pairWithDevice(
      BluetoothDevice device, BuildContext context) async {
    isPairing = true;
    _stateController.add(null);

    bool paired = false;
    try {
      paired = await FlutterBluetoothSerial.instance
              .bondDeviceAtAddress(device.address) ??
          false;

      if (!paired) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Ghép đôi không thành công, đang thử kết nối trực tiếp...')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã ghép đôi thành công!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi ghép đôi: $e')),
      );
    } finally {
      isPairing = false;
      _stateController.add(null);
    }
    return paired;
  }

  // Connect to selected device
  Future<void> connectToDevice(
      BluetoothDevice device, BuildContext context) async {
    try {
      // Show connecting dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(isPairing ? "Đang ghép đôi..." : "Đang kết nối..."),
            ],
          ),
        ),
      );

      // Check if device is bonded, if not try to bond first
      bool isBonded = device.isBonded;
      if (!isBonded) {
        isBonded = await pairWithDevice(device, context);
      }

      // Try to connect
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);

      // Update state
      this.connection = connection;
      connectedDevice = device;
      isConnected = true;
      _stateController.add(null);

      // Close dialog and show success message
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã kết nối với ${device.name ?? "HC-05"}'),
        ),
      );

      // Listen for incoming data
      connection.input?.listen((Uint8List data) {
        String incomingMessage = utf8.decode(data);
        print('Data incoming: $incomingMessage');

        lastMessage = incomingMessage;
        gardenData.updateFromString(incomingMessage);

        // Save data to Firebase every 5 minutes
        if (DateTime.now().difference(_lastDataSaved).inMinutes >= 5) {
          _firebaseService.saveGardenData(gardenData);
          _lastDataSaved = DateTime.now();
        }

        _stateController.add(null);
      });
    } catch (e) {
      // Close dialog and show error message
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể kết nối: $e')),
      );
    }
  }

  // Connect to a specific device directly (by address)
  Future<void> connectToSpecificDevice(
      String address, String name, BuildContext context) async {
    try {
      // Show connecting dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Đang kết nối..."),
            ],
          ),
        ),
      );

      // Create a BluetoothDevice instance for the specific device
      BluetoothDevice specificDevice = BluetoothDevice(
        address: address,
        name: name,
        type: BluetoothDeviceType.classic,
        bondState: BluetoothBondState.none,
        isConnected: false,
      );

      // Try to connect directly
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(address);

      // Update state
      this.connection = connection;
      connectedDevice = specificDevice;
      isConnected = true;
      _stateController.add(null);

      // Close dialog and show success message
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã kết nối với $name'),
        ),
      );

      // Listen for incoming data
      connection.input?.listen((Uint8List data) {
        String incomingMessage = utf8.decode(data);
        print('Data incoming: $incomingMessage');

        lastMessage = incomingMessage;
        gardenData.updateFromString(incomingMessage);

        // Save data to Firebase every 5 minutes
        if (DateTime.now().difference(_lastDataSaved).inMinutes >= 5) {
          _firebaseService.saveGardenData(gardenData);
          _lastDataSaved = DateTime.now();
        }

        _stateController.add(null);
      });
    } catch (e) {
      // Close dialog and show error message
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể kết nối: $e')),
      );
    }
  }

  // Helper methods to check if controls are enabled (for interaction)
  bool isPumpControlEnabled() {
    return isConnected &&
        gardenData.isManualMode &&
        DateTime.now().difference(_lastPumpToggleTime) >= _buttonCooldown;
  }

  bool isBuzzerControlEnabled() {
    return isConnected &&
        gardenData.isManualMode &&
        DateTime.now().difference(_lastBuzzerToggleTime) >= _buttonCooldown;
  }

  // Helper methods to get current device states (for UI display)
  bool isPumpActive() {
    return gardenData.isPumpOn;
  }

  bool isBuzzerActive() {
    return gardenData.isBuzzerOn;
  }

  // Send data to connected device
  Future<void> sendData(String data, BuildContext context) async {
    if (connection != null && connection!.isConnected && data.isNotEmpty) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(data + "\r\n")));
        await connection!.output.allSent;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi thành công!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gửi dữ liệu: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Không thể gửi dữ liệu. Vui lòng kết nối thiết bị và nhập dữ liệu.'),
        ),
      );
    }
  }

  // Send command to control pump
  Future<void> togglePump(bool turnOn, BuildContext context) async {
    if (connection != null && connection!.isConnected) {
      // Check if we're in manual mode
      if (!gardenData.isManualMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không thể điều khiển bơm ở chế độ tự động')),
        );
        return;
      }

      // Check if enough time has passed since last press
      final timeSinceLastToggle =
          DateTime.now().difference(_lastPumpToggleTime);
      if (timeSinceLastToggle < _buttonCooldown) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng đợi 1 giây trước khi nhấn lại')),
        );
        return;
      }

      try {
        String command = turnOn ? '1' : '0';
        connection!.output.add(Uint8List.fromList(utf8.encode(command)));
        await connection!.output.allSent;

        // Update local state immediately
        gardenData.isPumpOn = turnOn;
        _lastPumpToggleTime = DateTime.now();
        _stateController.add(null);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(turnOn ? 'Đã BẬT bơm' : 'Đã TẮT bơm')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi điều khiển bơm: $e')),
        );
      }
    }
  }

  // Send command to control buzzer
  Future<void> toggleBuzzer(bool turnOn, BuildContext context) async {
    if (connection != null && connection!.isConnected) {
      // Check if we're in manual mode
      if (!gardenData.isManualMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Không thể điều khiển còi ở chế độ tự động')),
        );
        return;
      }

      // Check if enough time has passed since last press
      final timeSinceLastToggle =
          DateTime.now().difference(_lastBuzzerToggleTime);
      if (timeSinceLastToggle < _buttonCooldown) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vui lòng đợi 1 giây trước khi nhấn lại')),
        );
        return;
      }

      try {
        String command = turnOn ? 'B' : 'b';
        connection!.output.add(Uint8List.fromList(utf8.encode(command)));
        await connection!.output.allSent;

        // Update local state immediately
        gardenData.isBuzzerOn = turnOn;
        _lastBuzzerToggleTime = DateTime.now();
        _stateController.add(null);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(turnOn ? 'Đã BẬT còi' : 'Đã TẮT còi')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi điều khiển còi: $e')),
        );
      }
    }
  }

  // Send command to switch modes
  Future<void> toggleMode(bool manualMode, BuildContext context) async {
    if (connection != null && connection!.isConnected) {
      try {
        String command = manualMode ? 'M' : 'A';
        connection!.output.add(Uint8List.fromList(utf8.encode(command)));
        await connection!.output.allSent;

        // Update local state immediately
        gardenData.isManualMode = manualMode;
        _stateController.add(null);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(manualMode
                  ? 'Đã chuyển sang chế độ thủ công'
                  : 'Đã chuyển sang chế độ tự động')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chuyển đổi chế độ: $e')),
        );
      }
    }
  }

  // Add these new methods to set thresholds
  Future<void> setMoistureThreshold(int threshold, BuildContext context) async {
    if (connection != null && connection!.isConnected) {
      try {
        String command = 'SM:$threshold';
        connection!.output.add(Uint8List.fromList(utf8.encode(command)));
        await connection!.output.allSent;

        // Update local state immediately for better user feedback
        gardenData.moistureThreshold = threshold;
        _stateController.add(null);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đặt ngưỡng độ ẩm đất: $threshold%')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đặt ngưỡng độ ẩm đất: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có kết nối Bluetooth')),
      );
    }
  }

  Future<void> setDistanceThreshold(int threshold, BuildContext context) async {
    if (connection != null && connection!.isConnected) {
      try {
        String command = 'SD:$threshold';
        connection!.output.add(Uint8List.fromList(utf8.encode(command)));
        await connection!.output.allSent;

        // Update local state immediately for better user feedback
        gardenData.distanceThreshold = threshold;
        _stateController.add(null);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đặt ngưỡng khoảng cách: $threshold cm')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đặt ngưỡng khoảng cách: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có kết nối Bluetooth')),
      );
    }
  }

  // Disconnect from device
  void disconnect(BuildContext context) async {
    if (connection != null) {
      try {
        await connection!.close();
        connection = null;
        connectedDevice = null;
        isConnected = false;
        _stateController.add(null);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã ngắt kết nối')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi ngắt kết nối: $e')),
        );
      }
    }
  }

  // Dispose resources
  void dispose() {
    _discoveryStreamSubscription?.cancel();
    if (connection != null) {
      connection!.dispose();
    }
    _stateController.close();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/bluetooth_service.dart';
import '../widgets/sensor_card.dart';
import '../widgets/control_widget.dart';
import 'analytics_screen.dart'; // Add this import

class BluetoothApp extends StatefulWidget {
  const BluetoothApp({Key? key}) : super(key: key);

  @override
  State<BluetoothApp> createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  // Bluetooth service
  final BluetoothService _bluetoothService = BluetoothService();

  // Specific device constants
  final String _specificDeviceAddress = '00:22:12:02:52:38';
  final String _specificDeviceName = 'SMART_GARDEN';

  // Controller for the text input
  final TextEditingController textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen for state changes in the service
    _bluetoothService.onStateChanged.listen((_) {
      if (mounted) setState(() {});
    });

    // Request permissions and initialize Bluetooth
    _bluetoothService.checkAndRequestPermissions(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Garden'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_bluetoothService.isConnected)
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen()),
                );
              },
              tooltip: 'Phân tích dữ liệu',
            ),
          if (_bluetoothService.isConnected)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: () => _bluetoothService.disconnect(context),
              tooltip: 'Ngắt kết nối',
            ),
        ],
      ),
      body:
          _bluetoothService.isConnected ? _buildConnectedUI() : _buildScanUI(),
    );
  }

  // UI when not connected to any device
  Widget _buildScanUI() {
    if (!_bluetoothService.bluetoothPermissionGranted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Cần cấp quyền Bluetooth để sử dụng ứng dụng',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  _bluetoothService.checkAndRequestPermissions(context),
              child: const Text('Cấp quyền Bluetooth'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Direct connection button for specific device
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bluetooth_connected, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _specificDeviceName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _specificDeviceAddress,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _bluetoothService.connectToSpecificDevice(
                        _specificDeviceAddress, _specificDeviceName, context),
                    icon: const Icon(Icons.link),
                    label: const Text('Kết nối trực tiếp'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Divider
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(thickness: 1),
        ),

        // Scan button header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Hoặc quét tìm thiết bị khác',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Scan button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _bluetoothService.isScanning
                ? null
                : _bluetoothService.startScan,
            icon: const Icon(Icons.bluetooth_searching),
            label: Text(_bluetoothService.isScanning
                ? 'Đang quét thiết bị...'
                : 'Quét tìm thiết bị HC-05'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),

        // Scanning indicator
        if (_bluetoothService.isScanning)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),

        // Help text
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(height: 8),
                  Text(
                    'Ứng dụng sẽ tự động kết nối với HC-05 mà không cần ghép đôi trước trong cài đặt.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Devices list header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Icon(Icons.bluetooth, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Thiết bị tìm thấy (${_bluetoothService.discoveryResults.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),

        const Divider(),

        // Devices list
        Expanded(
          child: _bluetoothService.discoveryResults.isEmpty
              ? Center(
                  child: _bluetoothService.isScanning
                      ? const Text('Đang tìm thiết bị...')
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Không tìm thấy thiết bị'),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: _bluetoothService.startScan,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Quét lại'),
                            ),
                          ],
                        ),
                )
              : ListView.builder(
                  itemCount: _bluetoothService.discoveryResults.length,
                  itemBuilder: (context, index) {
                    BluetoothDiscoveryResult result =
                        _bluetoothService.discoveryResults[index];
                    BluetoothDevice device = result.device;

                    String deviceName = device.name?.isNotEmpty == true
                        ? device.name!
                        : 'Thiết bị không tên';

                    return ListTile(
                      leading: Icon(
                        Icons.bluetooth,
                        color: device.isBonded ? Colors.green : Colors.blue,
                      ),
                      title: Text(deviceName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(device.address),
                          Text(
                            device.isBonded ? 'Đã ghép đôi' : 'Chưa ghép đôi',
                            style: TextStyle(
                              color: device.isBonded
                                  ? Colors.green
                                  : Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () =>
                            _bluetoothService.connectToDevice(device, context),
                        child: const Text('Kết nối'),
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // UI when connected to a device
  Widget _buildConnectedUI() {
    final gardenData = _bluetoothService.gardenData;
    final connectedDevice = _bluetoothService.connectedDevice;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connected device info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.bluetooth_connected,
                        color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Đã kết nối với ${connectedDevice!.name ?? "HC-05"}',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      connectedDevice.address,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Garden Title
            Center(
              child: Text(
                'VƯỜN THÔNG MINH',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
              ),
            ),

            // Garden Image
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  'assets/images/smart_garden.png',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Temperature Card
            SensorCard(
              title: 'Nhiệt độ',
              value: '${gardenData.temperature.toStringAsFixed(1)}°C',
              icon: Icons.thermostat,
              color: Colors.red,
            ),

            const SizedBox(height: 16),

            // Humidity Card
            SensorCard(
              title: 'Độ ẩm không khí',
              value: '${gardenData.humidity.toStringAsFixed(1)}%',
              icon: Icons.water_drop,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            // Soil Moisture Card
            SensorCard(
              title: 'Độ ẩm đất',
              value: '${gardenData.soilMoisture.toStringAsFixed(1)}%',
              icon: Icons.grass,
              color: Colors.brown,
            ),

            const SizedBox(height: 16),

            // Distance Card
            SensorCard(
              title: 'Động vật gần',
              value: '${gardenData.distance.toStringAsFixed(1)} cm',
              icon: Icons.pets,
              color: Colors.cyan,
            ),

            const SizedBox(height: 24),

            // Threshold Settings Card
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'CÀI ĐẶT NGƯỠNG',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Moisture Threshold Slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ngưỡng độ ẩm đất: ${gardenData.moistureThreshold}%',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _bluetoothService.setMoistureThreshold(
                                    gardenData.moistureThreshold, context);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Lưu'),
                            ),
                          ],
                        ),
                        Slider(
                          value: gardenData.moistureThreshold.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: gardenData.moistureThreshold.toString(),
                          onChanged: (value) {
                            setState(() {
                              gardenData.moistureThreshold = value.toInt();
                            });
                          },
                        ),
                        Text(
                          'Bơm sẽ hoạt động khi độ ẩm dưới ${gardenData.moistureThreshold}%',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),

                    const Divider(height: 24),

                    // Distance Threshold Slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ngưỡng khoảng cách: ${gardenData.distanceThreshold} cm',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _bluetoothService.setDistanceThreshold(
                                    gardenData.distanceThreshold, context);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Lưu'),
                            ),
                          ],
                        ),
                        Slider(
                          value: gardenData.distanceThreshold.toDouble(),
                          min: 5,
                          max: 100,
                          divisions: 95,
                          label: gardenData.distanceThreshold.toString(),
                          onChanged: (value) {
                            setState(() {
                              gardenData.distanceThreshold = value.toInt();
                            });
                          },
                        ),
                        Text(
                          'Còi báo sẽ kích hoạt khi phát hiện vật thể gần hơn ${gardenData.distanceThreshold} cm',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Control Panel
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'BẢNG ĐIỀU KHIỂN',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Mode Control
                    ControlWidget(
                      title: 'Chế độ thủ công',
                      isOn: gardenData.isManualMode,
                      icon: Icons.settings,
                      onToggle: (value) =>
                          _bluetoothService.toggleMode(value, context),
                    ),

                    const Divider(height: 24),

                    // Pump Control
                    ControlWidget(
                      title: 'Máy bơm nước',
                      isOn: gardenData.isPumpOn,
                      icon: Icons.water,
                      onToggle: (value) =>
                          _bluetoothService.togglePump(value, context),
                    ),

                    const Divider(height: 24),

                    // Buzzer Control
                    ControlWidget(
                      title: 'Còi báo động',
                      isOn: gardenData.isBuzzerOn,
                      icon: Icons.notifications_active,
                      onToggle: (value) =>
                          _bluetoothService.toggleBuzzer(value, context),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Raw data display (for debugging)
            if (_bluetoothService.lastMessage.isNotEmpty)
              Card(
                color: Colors.grey.shade200,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.data_array,
                              size: 18, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Dữ liệu nhận gần nhất:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _bluetoothService.lastMessage,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Manual command input
            ExpansionTile(
              title: const Text('Gửi lệnh thủ công'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: textController,
                        decoration: const InputDecoration(
                          labelText: 'Nhập dữ liệu cần gửi',
                          border: OutlineInputBorder(),
                          hintText: 'Nhập dữ liệu...',
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _bluetoothService.sendData(
                            textController.text, context),
                        icon: const Icon(Icons.send),
                        label: const Text('Gửi'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bluetoothService.dispose();
    textController.dispose();
    super.dispose();
  }
}

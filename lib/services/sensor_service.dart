import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class SensorService {
  final NetworkInfo _networkInfo = NetworkInfo();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Obtém o nome da rede Wi-Fi (SSID)
  Future<String?> getWifiSsid() async {
    try {
      return await _networkInfo.getWifiName();
    } catch (e) {
      debugPrint("Erro ao obter SSID: $e");
      return null;
    }
  }

  // Escaneia dispositivos Bluetooth Low Energy (BLE) próximos
  Future<int> scanBleDevices({int durationSeconds = 4}) async {
    if (!await FlutterBluePlus.isSupported) {
      debugPrint("Bluetooth não é suportado neste dispositivo.");
      return 0;
    }

    // Ativa o bluetooth
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        debugPrint("Erro ao ligar o Bluetooth: $e");
      }
    }

    final Set<String> discoveredDevices = {};
    try {
      await FlutterBluePlus.startScan(
          timeout: Duration(seconds: durationSeconds));
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          discoveredDevices.add(r.device.remoteId.toString());
        }
      });
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint("Erro ao escanear BLE: $e");
    }
    return discoveredDevices.length;
  }

  // Calcula a variância dos dados do acelerômetro
  Future<double> getAccelerometerVariance({int durationSeconds = 3}) async {
    final List<double> magnitudes = [];
    final streamSubscription = accelerometerEvents.listen((event) {
      final magnitude =
          sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
      magnitudes.add(magnitude);
    });

    await Future.delayed(Duration(seconds: durationSeconds));
    streamSubscription.cancel();

    if (magnitudes.isEmpty) return 0.0;

    final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance =
        magnitudes.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            magnitudes.length;

    return variance;
  }

  // Mede o nível de ruído ambiente (RMS)
  Future<double> getAudioRms() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Obtenha um diretório temporário para salvar o arquivo de áudio
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/temp_audio.m4a';

        await _audioRecorder.start(
          const RecordConfig(),
          path: tempPath,
        );
        final stream = _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 200));

        double maxAmplitude = -100; // O dBFS é geralmente negativo
        final completer = Completer<double>();

        late StreamSubscription<Amplitude> subscription;
        subscription = stream.listen(
          (amp) {
            if (amp.current > maxAmplitude) {
              maxAmplitude = amp.current;
            }
          },
          onDone: () {
            // Converte dBFS para uma escala mais linear para o RMS
            final linear = pow(10, maxAmplitude / 20);
            completer.complete(linear * 100); // Escala para 0-100
          },
        );

        // Para a gravação após um curto período
        Future.delayed(const Duration(seconds: 2), () async {
          await _audioRecorder.stop();
          await subscription.cancel();
        });

        return await completer.future;
      }
    } catch (e) {
      debugPrint("Erro ao medir áudio: $e");
    }
    return 0.0;
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}

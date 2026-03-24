import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:volume_controller/volume_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tilt Volume Simple',
      theme: ThemeData.dark(),
      home: const VolumeTilt(),
    );
  }
}

class VolumeTilt extends StatefulWidget {
  const VolumeTilt({super.key});

  @override
  State<VolumeTilt> createState() => _VolumeTiltState();
}

class _VolumeTiltState extends State<VolumeTilt> {
  double _volume = 0.5;
  double _tiltX = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  @override
  void initState() {
    super.initState();
    VolumeController().showSystemUI = false;
    VolumeController().getVolume().then((v) => setState(() => _volume = v));
    _accelSub = accelerometerEvents.listen((event) {
      setState(() {
        _tiltX = event.x;
        // Sinistra (x>2): abbassa, Destra (x<-2): alza
        if (_tiltX > 2.0) {
          _volume = (_volume - 0.01).clamp(0.0, 1.0);
        } else if (_tiltX < -2.0) {
          _volume = (_volume + 0.01).clamp(0.0, 1.0);
        }
        VolumeController().setVolume(_volume);  // Applica
      });
    });
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    VolumeController().showSystemUI = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perc = (_volume * 100).round();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Volume: $perc%', style: const TextStyle(fontSize: 48)),
            Text('Tilt X: ${_tiltX.toStringAsFixed(1)}', style: const TextStyle(fontSize: 24)),
            Slider(
              value: _volume,
              min: 0,
              max: 1,
              onChanged: (_) {},  // Solo visuale
            ),
            const Text('Inclina sinistra ← | destra →'),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:math';

/// Live status flag from standard electronic scale indicators (Yaohua, Toledo, Avery).
enum ScaleStability {
  stable, // Weight has settled (ST)
  motion, // Load is vibrating or moving on the bridge (US)
  overload, // Weight exceeds capacity (OL)
}

/// Snapshot of the digital scale reading.
class ScaleReading {
  final double weightKg;
  final ScaleStability stability;
  final bool isZero;
  final DateTime timestamp;

  const ScaleReading({
    required this.weightKg,
    this.stability = ScaleStability.stable,
    this.isZero = false,
    required this.timestamp,
  });

  /// Weight in Mandi Maunds (من = 40 KG)
  double get maunds => weightKg / 40.0;
}

/// Service providing digital weighbridge and electronic bench scale connectivity.
/// Supports both live hardware streaming interface and built-in Mandi scale simulator.
class ScaleService {
  static final ScaleService _instance = ScaleService._internal();
  factory ScaleService() => _instance;
  ScaleService._internal();

  bool _isSimulating = false;
  Timer? _simTimer;
  double _currentSimWeight = 0.0;
  final _readingController = StreamController<ScaleReading>.broadcast();

  Stream<ScaleReading> get readingStream => _readingController.stream;
  bool get isSimulating => _isSimulating;
  double get currentWeight => _currentSimWeight;

  /// Start the live weight stream simulator with realistic Mandi vehicle weights.
  void startSimulation({double targetWeightKg = 8450.0}) {
    _isSimulating = true;
    _currentSimWeight = 0.0;
    _simTimer?.cancel();

    final rnd = Random();
    int ticks = 0;

    _simTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      ticks++;
      if (ticks < 10) {
        // Truck driving onto weighbridge, weight climbs rapidly with vibration
        _currentSimWeight = (targetWeightKg * (ticks / 10)) + rnd.nextDouble() * 120 - 60;
        _readingController.add(
          ScaleReading(
            weightKg: double.parse(_currentSimWeight.toStringAsFixed(1)),
            stability: ScaleStability.motion,
            isZero: false,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        // Vehicle stationary, scale stabilizes
        _currentSimWeight = targetWeightKg + (rnd.nextDouble() * 2 - 1);
        _readingController.add(
          ScaleReading(
            weightKg: double.parse(_currentSimWeight.toStringAsFixed(1)),
            stability: ScaleStability.stable,
            isZero: false,
            timestamp: DateTime.now(),
          ),
        );
      }
    });
  }

  /// Stop live streaming
  void stopSimulation() {
    _simTimer?.cancel();
    _isSimulating = false;
  }

  /// Manually zero the scale indicator
  void zeroScale() {
    _simTimer?.cancel();
    _currentSimWeight = 0.0;
    _readingController.add(
      ScaleReading(
        weightKg: 0.0,
        stability: ScaleStability.stable,
        isZero: true,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Manually set scale weight (e.g., from keypad or test)
  void setManualWeight(double kg) {
    _currentSimWeight = kg;
    _readingController.add(
      ScaleReading(
        weightKg: kg,
        stability: ScaleStability.stable,
        isZero: kg == 0,
        timestamp: DateTime.now(),
      ),
    );
  }

  void dispose() {
    _simTimer?.cancel();
    _readingController.close();
  }
}

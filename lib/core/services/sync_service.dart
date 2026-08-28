// B.8 Offline queue - stub para WorkManager (se activa al recuperar conectividad)
// TODO: integrar flutter_workmanager + drift queue en siguiente iteración
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncService {
  static const taskName = 'tomato_sync_pending';
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    // Workmanager().initialize(callbackDispatcher, isInDebugMode: kDebugMode);
    _initialized = true;
  }

  static Future<void> registerPeriodicSync() async {
    // Workmanager().registerPeriodicTask(taskName, taskName, frequency: Duration(minutes: 15), constraints: Constraints(networkType: NetworkType.connected));
  }

  static Future<int> getPendingCount() async {
    // Leer de Drift/SQLite pending_diagnostics donde is_synced=0
    return 0;
  }

  static Stream<bool> connectivityStream() {
    return Connectivity().onConnectivityChanged.map((result) => result != ConnectivityResult.none);
  }
}

// @pragma('vm:entry-point')
// void callbackDispatcher() { Workmanager().executeTask(...) }

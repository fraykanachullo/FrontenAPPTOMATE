import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity = Connectivity();
  @override
  Future<bool> get isConnected async {
    try {
      final res = await _connectivity.checkConnectivity();
      // Soporta connectivity_plus 4.x (single) y 5.x+ (List)
      final str = res.toString();
      if (str.contains('none') && !str.contains('wifi') && !str.contains('mobile') && !str.contains('ethernet')) {
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }
}

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  late StreamController<ConnectivityResult> _connectivityController;

  ConnectivityService() {
    _connectivityController = StreamController<ConnectivityResult>.broadcast();
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _connectivityController.add(result);
    });
  }

  Stream<ConnectivityResult> get connectivityStream => _connectivityController.stream;

  Future<ConnectivityResult> checkConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  void dispose() {
    _connectivityController.close();
  }
}
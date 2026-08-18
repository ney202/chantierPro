import 'package:flutter/foundation.dart';

/// Bus de notification simple pour rafraîchir les écrans
/// après une mutation (création, suppression, etc.).
class RefreshBus extends ChangeNotifier {
  static final RefreshBus _instance = RefreshBus._internal();
  factory RefreshBus() => _instance;
  RefreshBus._internal();

  void ping() => notifyListeners();
}

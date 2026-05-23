import 'package:flutter/foundation.dart';

class SduiContextStore extends ChangeNotifier {
  Map<String, dynamic> _data = {};

  Map<String, dynamic> get snapshot => Map<String, dynamic>.unmodifiable(_data);

  void set(Map<String, dynamic> next) {
    _data = Map<String, dynamic>.from(next);
    notifyListeners();
  }

  void update(Map<String, dynamic> patch) {
    _data = {..._data, ...patch};
    notifyListeners();
  }

  dynamic getValue(String dotPath) {
    final parts = dotPath.split('.');
    dynamic cur = _data;
    for (final p in parts) {
      if (cur is Map && cur.containsKey(p)) {
        cur = cur[p];
      } else {
        return null;
      }
    }
    return cur;
  }
}

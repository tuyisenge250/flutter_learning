import 'package:flutter/foundation.dart';

/// State class that holds counter data and logic
/// Extends ChangeNotifier to notify widgets when state changes
class CounterModel extends ChangeNotifier {
  // Private variable to hold the count
  int _count = 0;

  // Getter to access count value
  int get count => _count;

  /// Increments the counter and notifies all listening widgets
  /// This triggers UI rebuild for widgets that consume this state
  void increment() {
    _count++;
    notifyListeners(); // Key: tells Flutter to rebuild widgets watching this state
  }

  /// Decrements the counter and notifies listeners
  void decrement() {
    _count--;
    notifyListeners();
  }

  /// Resets counter to zero
  void reset() {
    _count = 0;
    notifyListeners();
  }
}

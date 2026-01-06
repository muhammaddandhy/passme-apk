import 'dart:async';
import 'package:flutter/services.dart';

class ClipboardService {
  static Timer? _timer;

  /// Copy text to clipboard and clear it after [duration]
  static Future<void> copyAndAutoClear(String text, {Duration duration = const Duration(seconds: 30)}) async {
    // Cancel existing timer if any
    _timer?.cancel();

    // Set data
    await Clipboard.setData(ClipboardData(text: text));

    // Start timer to clear
    _timer = Timer(duration, () async {
      // Check if current clipboard content is still what we copied
      final currentData = await Clipboard.getData(Clipboard.kTextPlain);
      if (currentData?.text == text) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  static void dispose() {
    _timer?.cancel();
  }
}

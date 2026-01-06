import 'dart:math';

class PasswordGenerator {
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  static String generate({
    int length = 12,
    bool useLowercase = true,
    bool useUppercase = true,
    bool useNumbers = true,
    bool useSymbols = true,
  }) {
    if (length < 4) length = 4; // Minimum length
    
    String chars = '';
    if (useLowercase) chars += _lowercase;
    if (useUppercase) chars += _uppercase;
    if (useNumbers) chars += _numbers;
    if (useSymbols) chars += _symbols;

    if (chars.isEmpty) {
      // Default fallback if nothing selected
      chars = _lowercase + _uppercase + _numbers;
    }

    // Ensure at least one character from each selected set is included
    List<String> passwordChars = [];
    final rand = Random.secure();

    if (useLowercase) passwordChars.add(_lowercase[rand.nextInt(_lowercase.length)]);
    if (useUppercase) passwordChars.add(_uppercase[rand.nextInt(_uppercase.length)]);
    if (useNumbers) passwordChars.add(_numbers[rand.nextInt(_numbers.length)]);
    if (useSymbols) passwordChars.add(_symbols[rand.nextInt(_symbols.length)]);

    // Fill the rest
    while (passwordChars.length < length) {
      passwordChars.add(chars[rand.nextInt(chars.length)]);
    }

    // Shuffle the result
    passwordChars.shuffle(rand);

    return passwordChars.join();
  }
}

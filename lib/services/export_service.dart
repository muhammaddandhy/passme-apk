import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/password_model.dart';
import '../services/encryption_service.dart';

class ExportService {
  static Future<void> exportToCSV(List<PasswordModel> passwords) async {
    List<List<dynamic>> rows = [];

    // Header
    rows.add([
      "Service/Title",
      "Username/Email",
      "Password",
      "URL",
      "Category",
      "Notes",
      "Created At"
    ]);

    for (var password in passwords) {
      String? decryptedPass = EncryptionService.decrypt(password.password);
      
      rows.add([
        password.title,
        password.username,
        decryptedPass ?? "[Encryption Error]",
        password.url ?? "",
        password.category,
        password.notes ?? "",
        password.createdAt,
      ]);
    }

    String csvContent = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/passme_export_${DateTime.now().millisecondsSinceEpoch}.csv');
    
    await file.writeAsString(csvContent);

    // Share the file
    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], text: 'Ekspor Data Brankas PASSME');
  }
}

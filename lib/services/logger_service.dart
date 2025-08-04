import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:intl/intl.dart';

class LoggerService extends GetxController {
  static LoggerService? _instance;
  late File _logFile;

  LoggerService._();

  /// Singleton instance
  static Future<LoggerService> getInstance() async {
    _instance ??= LoggerService._();
    await _instance!._initLogFile();
    return _instance!;
  }

  Future<void> _initLogFile() async {
    final directory = await getApplicationDocumentsDirectory();
    _logFile = File('${directory.path}/log.txt');

    // Clear the file by writing an empty string
    await _logFile.writeAsString('');
  }

  /// Log a message
  Future<void> log(String message) async {
    // String timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    String logEntry = message;

    // print(logEntry); // Print to console
    await _logFile.writeAsString('$logEntry\n', mode: FileMode.append);
  }

  /// Get log file path
  String getLogFilePath() {
    return _logFile.path;
  }

  /// Read log file contents
  Future<String> readLogs() async {
    if (await _logFile.exists()) {
      return await _logFile.readAsString();
    }
    return "No logs found.";
  }
}

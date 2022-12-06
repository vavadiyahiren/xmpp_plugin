import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NativeLogHelper {
  static late SharedPreferences _prefs;
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  static Future initMySharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String logFilePath = '';
  static String logFileName = 'xmpp_logs.txt';
  static const String prefIsLogEnableKey = 'PREF_IS_LOG_ENABLE_KEY';

  Future<void> init() async {
    await getDefaultLogFilePath();
  }

  Future<String> getDefaultLogFilePath() async {
    if (isLogEnable()) {
      String dir = await getFilePath();
      logFilePath = '$dir/$logFileName';
      return dir;
    } else {
      return '';
    }
  }

  bool isLogEnable() {
    return true;
  }

  Future<void> toggleXmppFileLog(bool value) async {
    if (!value) {
      logFilePath = '';
    }
    await _prefs.setBool(prefIsLogEnableKey, value);
  }

  static Future<String> getFilePath() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        final sdkVersion = androidInfo.version.sdkInt;
        final status = await Permission.storage.status;
        if (status.isGranted) {
          return await _getAndroidFilePath(sdkVersion);
        }
      } else {
        final storageDirectory = await getApplicationDocumentsDirectory();
        return storageDirectory.path;
      }
    } catch (e) {
      print(e);
    }
    return '';
  }

  static Future<String> _getAndroidFilePath(int sdkVersion) async {
    final directory = await getExternalStorageDirectory();
    if (directory != null && !await directory.exists()) {
      await directory.create();
    }
    return '${directory?.path}';
  }

  Future<void> deleteLogFile() async {
    try {
      final path = await getFilePath();
      if (path.isNotEmpty) {
        if (await File('$path/$logFileName').exists()) {
          await File('$path/$logFileName').delete();
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<bool> isFileExist() async {
    return logFilePath.isEmpty ? false : await File(logFilePath).exists();
  }
}

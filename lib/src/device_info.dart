import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Collected device and app metadata attached to every event.
class DeviceMetadata {
  final String platform;
  final String model;
  final String osVersion;
  final bool isPhysicalDevice;
  final String appVersion;
  final String buildNumber;
  final String packageName;
  final String locale;

  const DeviceMetadata({
    required this.platform,
    required this.model,
    required this.osVersion,
    required this.isPhysicalDevice,
    required this.appVersion,
    required this.buildNumber,
    required this.packageName,
    required this.locale,
  });

  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'model': model,
      'os_version': osVersion,
      'is_physical_device': isPhysicalDevice,
      'app_version': appVersion,
      'build_number': buildNumber,
      'package_name': packageName,
      'locale': locale,
    };
  }
}

/// Collects device and app metadata using platform plugins.
///
/// Information is gathered once during SDK initialization and cached
/// for the lifetime of the app. No repeated platform channel calls.
class DeviceInfoCollector {
  DeviceMetadata? _info;

  /// Returns the collected device metadata, or null if not yet initialized.
  DeviceMetadata? get info => _info;

  /// Collects device and app information from platform plugins.
  Future<void> initialize() async {
    String appVersion = 'unknown';
    String buildNumber = 'unknown';
    String packageName = 'unknown';

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
      packageName = packageInfo.packageName;
    } catch (e) {
      debugPrint('Logpane: failed to collect package info: $e');
    }

    String platform = 'unknown';
    String model = 'unknown';
    String osVersion = 'unknown';
    bool isPhysicalDevice = true;

    try {
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        platform = 'android';
        model = androidInfo.model;
        osVersion = androidInfo.version.release;
        isPhysicalDevice = androidInfo.isPhysicalDevice;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        platform = 'ios';
        model = iosInfo.utsname.machine;
        osVersion = iosInfo.systemVersion;
        isPhysicalDevice = iosInfo.isPhysicalDevice;
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfoPlugin.macOsInfo;
        platform = 'macos';
        model = macInfo.model;
        osVersion =
            '${macInfo.majorVersion}.${macInfo.minorVersion}.${macInfo.patchVersion}';
        isPhysicalDevice = true;
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfoPlugin.linuxInfo;
        platform = 'linux';
        model = linuxInfo.prettyName;
        osVersion = linuxInfo.versionId ?? 'unknown';
        isPhysicalDevice = true;
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfoPlugin.windowsInfo;
        platform = 'windows';
        model = windowsInfo.productName;
        osVersion =
            '${windowsInfo.majorVersion}.${windowsInfo.minorVersion}.${windowsInfo.buildNumber}';
        isPhysicalDevice = true;
      }
    } catch (e) {
      debugPrint('Logpane: failed to collect device info: $e');
    }

    String locale = 'unknown';
    try {
      locale = PlatformDispatcher.instance.locale.toString();
    } catch (e) {
      debugPrint('Logpane: failed to get locale: $e');
    }

    _info = DeviceMetadata(
      platform: platform,
      model: model,
      osVersion: osVersion,
      isPhysicalDevice: isPhysicalDevice,
      appVersion: appVersion,
      buildNumber: buildNumber,
      packageName: packageName,
      locale: locale,
    );
  }
}

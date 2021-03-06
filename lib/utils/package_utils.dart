import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:package_info/package_info.dart';

import 'package:openjmu/constants/constants.dart';

class PackageUtils {
  const PackageUtils._();

  static PackageInfo _packageInfo;

  static PackageInfo get packageInfo => _packageInfo;

  static String get version => _packageInfo.version;

  static int get buildNumber => _packageInfo.buildNumber.toIntOrNull();

  static String get appName => _packageInfo.appName;

  static String get packageName => _packageInfo.packageName;

  static String remoteVersion = version;
  static int remoteBuildNumber = buildNumber;

  static Future<void> initPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  static void checkUpdate({bool isManually = false}) {
    NetUtils.get<String>(API.checkUpdate).then((Response<String> response) {
      final Map<String, dynamic> data =
          jsonDecode(response.data) as Map<String, dynamic>;
      updateChangelog(
        (data['changelog'] as List<dynamic>).cast<Map<dynamic, dynamic>>(),
      );
      final int _currentBuild = buildNumber;
      final int _remoteBuild = data['buildNumber'].toString().toIntOrNull();
      final String _currentVersion = version;
      final String _remoteVersion = data['version'] as String;
      final bool _forceUpdate = data['forceUpdate'] as bool;
      LogUtils.d('Build: $_currentVersion+$_currentBuild'
          ' | '
          '$_remoteVersion+$_remoteBuild');
      if (_currentBuild < _remoteBuild) {
        Instances.eventBus.fire(HasUpdateEvent(
          forceUpdate: _forceUpdate,
          currentVersion: _currentVersion,
          currentBuild: _currentBuild,
          response: data,
        ));
      } else {
        if (isManually) {
          showToast('已更新为最新版本');
        }
      }
      remoteVersion = _remoteVersion;
      remoteBuildNumber = _remoteBuild;
    }).catchError((dynamic e) {
      LogUtils.e('Failed when checking update: $e');
      if (!isManually) {
        Future<void>.delayed(30.seconds, checkUpdate);
      }
    });
  }

  static Future<void> tryUpdate() async {
    if (Platform.isIOS) {
      launch('https://itunes.apple.com/cn/app/id1459832676');
    } else {
      if (await canLaunch('coolmarket://apk/$packageName')) {
        launch('coolmarket://apk/$packageName');
      } else {
        launch(
          'https://www.coolapk.com/apk/$packageName',
          forceSafariVC: false,
          forceWebView: false,
        );
      }
    }
  }

  static Widget updateNotifyDialog(HasUpdateEvent event) {
    String text;
    if (event.currentVersion == event.response['version']) {
      text = '${event.currentVersion}(${event.currentBuild}) ->'
          '${event.response['version']}(${event.response['buildNumber']})';
    } else {
      text = '${event.currentVersion} -> ${event.response['version']}';
    }
    return Material(
      color: Colors.black26,
      child: Stack(
        children: <Widget>[
          if (event.forceUpdate)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: const Text(' '),
              ),
            ),
          ConfirmationDialog(
            child: Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Column(
                  children: <Widget>[
                    Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 6.h),
                        child: Text(
                          'OpenJmu has new version',
                          style: TextStyle(
                            color: currentThemeColor,
                            fontFamily: 'chocolate',
                            fontSize: 28.sp,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 6.h),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: currentThemeColor,
                            fontFamily: 'chocolate',
                            fontSize: 28.sp,
                          ),
                        ),
                      ),
                    ),
                    if (!event.forceUpdate)
                      Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            vertical: 6.h,
                          ),
                          child: MaterialButton(
                            color: currentThemeColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: maxBorderRadius,
                            ),
                            onPressed: () {
                              dismissAllToast();
                              navigatorState
                                  .pushNamed(Routes.openjmuChangelogPage);
                            },
                            child: Text(
                              '查看版本履历',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          event.response['updateLog'] as String,
                          style: TextStyle(fontSize: 18.sp),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            showConfirm: !event.forceUpdate,
            onConfirm: dismissAllToast,
            onCancel: tryUpdate,
            confirmLabel: '下次一定',
            cancelLabel: '前往更新',
          ),
          Positioned(
            top: Screens.height / 12,
            left: 0.0,
            right: 0.0,
            child: const Center(child: OpenJMULogo(radius: 15.0)),
          ),
        ],
      ),
    );
  }

  static Future<void> showUpdateDialog(HasUpdateEvent event) async {
    showToastWidget(
      updateNotifyDialog(event),
      dismissOtherToast: true,
      duration: 1.weeks,
      handleTouch: true,
    );
  }

  static Future<void> updateChangelog(List<Map<dynamic, dynamic>> data) async {
    final Box<ChangeLog> box = HiveBoxes.changelogBox;
    final List<ChangeLog> logs = data
        .map((Map<dynamic, dynamic> log) =>
            ChangeLog.fromJson(log as Map<String, dynamic>))
        .toList();
    if (box.values == null) {
      await box.addAll(logs);
    } else {
      if (box.values.toString() != logs.toString()) {
        await box.clear();
        await box.addAll(logs);
      }
    }
  }
}

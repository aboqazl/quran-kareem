#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
manifest = ROOT / 'android/app/src/main/AndroidManifest.xml'
if manifest.exists():
    s = manifest.read_text(encoding='utf-8')
    if 'xmlns:tools=' not in s:
        s = s.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">','<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools">')
    permissions = ['<uses-permission android:name="android.permission.INTERNET"/>','<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>','<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>','<uses-permission android:name="android.permission.WAKE_LOCK"/>','<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>','<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>']
    anchor = '<application'
    before, after = s.split(anchor, 1)
    for p in permissions:
        if p not in before: before += f'    {p}\n'
    s = before + anchor + after
    s = re.sub(r'android:label="[^"]*"', 'android:label="القرآن الكريم"', s, count=1)
    s = re.sub(r'android:name="\.MainActivity"', 'android:name="com.ryanheise.audioservice.AudioServiceActivity"', s, count=1)
    additions = '''
        <service android:name="com.ryanheise.audioservice.AudioService" android:foregroundServiceType="mediaPlayback" android:exported="true" tools:ignore="Instantiatable"><intent-filter><action android:name="android.media.browse.MediaBrowserService" /></intent-filter></service>
        <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver" android:exported="true" tools:ignore="Instantiatable"><intent-filter><action android:name="android.intent.action.MEDIA_BUTTON" /></intent-filter></receiver>
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"><intent-filter><action android:name="android.intent.action.BOOT_COMPLETED"/><action android:name="android.intent.action.MY_PACKAGE_REPLACED"/><action android:name="android.intent.action.QUICKBOOT_POWERON" /><action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/></intent-filter></receiver>
'''
    if 'com.ryanheise.audioservice.AudioService"' not in s:
        s = s.replace('</application>', additions + '    </application>')
    manifest.write_text(s, encoding='utf-8')

gradle = ROOT / 'android/app/build.gradle.kts'
if gradle.exists():
    s = gradle.read_text(encoding='utf-8')
    s = s.replace('compileSdk = flutter.compileSdkVersion', 'compileSdk = 36')
    s = s.replace('minSdk = flutter.minSdkVersion', 'minSdk = 24')
    if 'isCoreLibraryDesugaringEnabled = true' not in s:
        s = s.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
    if 'coreLibraryDesugaring(' not in s:
        if '\ndependencies {' in s: s = s.replace('\ndependencies {','\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")',1)
        else: s += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")\n}\n'
    gradle.write_text(s, encoding='utf-8')
print('Native host patches applied.')

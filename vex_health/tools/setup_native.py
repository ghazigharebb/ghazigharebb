#!/usr/bin/env python3
"""VEX Health — دانانی کۆدی ناتیڤی ئاگادارکردنەوەی هەنگاو (Android) بۆ ناو پڕۆژەکە.

بەکارهێنان (لە فۆڵدەری پڕۆژە، دوای `flutter create .`):
    python3 tools/setup_native.py

دووبارە جێبەجێکردنی بێ مەترسییە (هیچ شتێک دووبارە زیاد ناکات).
iOS: بەپێی NOTIFICATIONS.md لە Xcode دەکرێت (Widget Extension دەبێت لە Xcode دروست بکرێت).
"""
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'native', 'android')
APP = os.path.join(ROOT, 'android', 'app')
MAIN = os.path.join(APP, 'src', 'main')


def read(p):
    with open(p, encoding='utf-8') as f:
        return f.read()


def write(p, s):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, 'w', encoding='utf-8') as f:
        f.write(s)


def find_package():
    """ناوی package ـی Kotlin (namespace) لە build.gradle ـەوە"""
    for n in ('build.gradle.kts', 'build.gradle'):
        p = os.path.join(APP, n)
        if os.path.exists(p):
            m = re.search(r'namespace\s*=?\s*["\']([\w.]+)["\']', read(p))
            if m:
                return m.group(1)
    return None


def main():
    if not os.path.isdir(APP):
        sys.exit('پۆشەی android/ نییە. یەکەم جار لە فۆڵدەری پڕۆژە `flutter create .` جێبەجێ بکە.')
    pkg = find_package()
    if not pkg:
        sys.exit('namespace لە android/app/build.gradle نەدۆزرایەوە.')
    print('package:', pkg)

    kdir = os.path.join(MAIN, 'kotlin', *pkg.split('.'))
    jdir = os.path.join(MAIN, 'java', *pkg.split('.'))
    outdir = kdir
    # ئەگەر پڕۆژەکە MainActivity ـی لە java/ ـدا هەبێت
    for d in (kdir, jdir):
        if os.path.exists(os.path.join(d, 'MainActivity.kt')):
            outdir = d
    for name in ('StepService', 'StepReceiver', 'StepsChannel'):
        write(os.path.join(outdir, name + '.kt'), read(os.path.join(SRC, name + '.kt.tpl')).replace('__PKG__', pkg))
        print('  +', name + '.kt')

    # MainActivity: تەنها ئەگەر وەکو دیفۆڵت بێت بیگۆڕە
    ma = os.path.join(outdir, 'MainActivity.kt')
    tpl = read(os.path.join(SRC, 'MainActivity.kt.tpl')).replace('__PKG__', pkg)
    if os.path.exists(ma):
        cur = read(ma)
        if 'StepsChannel.register' in cur:
            print('  = MainActivity.kt (پێشتر ڕێکخراوە)')
        elif 'configureFlutterEngine' in cur:
            print('  ! MainActivity.kt کۆدی تایبەتی تێدایە. ئەم دێڕە بخەرە ناو configureFlutterEngine:')
            print('      StepsChannel.register(flutterEngine.dartExecutor.binaryMessenger, applicationContext)')
        else:
            write(ma, tpl)
            print('  + MainActivity.kt')
    else:
        write(ma, tpl)
        print('  + MainActivity.kt')

    # res
    for sub in ('layout', 'drawable'):
        sdir = os.path.join(SRC, 'res', sub)
        for f in os.listdir(sdir):
            os.makedirs(os.path.join(MAIN, 'res', sub), exist_ok=True)
            shutil.copy(os.path.join(sdir, f), os.path.join(MAIN, 'res', sub, f))
            print('  + res/%s/%s' % (sub, f))

    # AndroidManifest
    mp = os.path.join(MAIN, 'AndroidManifest.xml')
    m = read(mp)
    if 'vex_steps' in m:
        print('  = AndroidManifest.xml (پێشتر ڕێکخراوە)')
    else:
        perms = read(os.path.join(SRC, 'manifest_permissions.xml'))
        comps = read(os.path.join(SRC, 'manifest_components.xml'))
        i = m.find('<application')
        j = m.rfind('</application>')
        if i < 0 or j < 0:
            sys.exit('AndroidManifest.xml بە دروستی نەخوێندرایەوە.')
        m = m[:i] + perms.strip('\n') + '\n\n    ' + m[i:j] + comps.strip('\n') + '\n    ' + m[j:]
        write(mp, m)
        print('  + AndroidManifest.xml')

    # AndroidManifest — ئاگادارکەرەوەی Band (کاتژمێر / وەرزش / نوێژ)
    m = read(mp)
    if 'vex_alerts' in m:
        print('  = AndroidManifest.xml (ئاگادارکەرەوەکان پێشتر ڕێکخراون)')
    else:
        perms = read(os.path.join(SRC, 'manifest_alerts_permissions.xml'))
        comps = read(os.path.join(SRC, 'manifest_alerts_components.xml'))
        i = m.find('<application')
        j = m.rfind('</application>')
        if i < 0 or j < 0:
            sys.exit('AndroidManifest.xml بە دروستی نەخوێندرایەوە.')
        # مۆڵەتی INTERNET ئەگەر پێشتر هەبوو دووبارە مەکەرەوە
        lines = [l for l in perms.strip('\n').split('\n') if not ('android.permission.INTERNET' in l and 'android.permission.INTERNET' in m)]
        m = m[:i] + '\n'.join(lines) + '\n\n    ' + m[i:j] + comps.strip('\n') + '\n    ' + m[j:]
        write(mp, m)
        print('  + AndroidManifest.xml (ئاگادارکەرەوەکان)')

    print('\nتەواو بوو. دەتوانیت `flutter run` بکەیت.')
    print('ڕێکخستنی ڕاستەوخۆ: بۆ flutter_local_notifications دەبێت desugaring چالاک بکەیت (بڕوانە ALERTS.md).')
    print('تێبینی: compileSdk دەبێت 34 یان زیاتر بێت (flutter create ی نوێ خۆی وایە).')


if __name__ == '__main__':
    main()

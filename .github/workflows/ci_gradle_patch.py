# CI only: desugaring + minSdk for the build check (same as ALERTS.md)
import re
p = 'android/app/build.gradle.kts'
s = open(p).read()
s = s.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
s = re.sub(r'minSdk = [^\n]+', 'minSdk = 24', s)
s += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
open(p, 'w').write(s)
print(s)

# پلەگینە کۆنەکان (geocoding_android …) لەسەر compileSdk 33 ن؛ هەموویان ببە سەر 35
p = 'android/build.gradle.kts'
s = open(p).read()
s += '''
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            compileSdkVersion(35)
        }
    }
}
'''
open(p, 'w').write(s)

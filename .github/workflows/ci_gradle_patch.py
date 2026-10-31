# CI only: desugaring + minSdk for the build check (same as ALERTS.md)
import re
p = 'android/app/build.gradle.kts'
s = open(p).read()
s = s.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
s = re.sub(r'minSdk = [^\n]+', 'minSdk = 24', s)
s = re.sub(r'compileSdk = [^\n]+', 'compileSdk = 36', s)
s += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
open(p, 'w').write(s)
print(s)

# پلەگینە کۆنەکان (geocoding_android …) لەسەر compileSdk 33 ن؛ هەموویان ببە سەر 35
p = 'android/build.gradle.kts'
s = open(p).read()
s += '''
subprojects {
    if (name != "app") {
        afterEvaluate {
            if (project.hasProperty("android")) {
                val ext = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
                ext.compileSdkVersion(36)
            }
        }
    }
}
'''
open(p, 'w').write(s)

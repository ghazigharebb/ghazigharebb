# CI only: desugaring + minSdk for the build check (same as ALERTS.md)
import re
p = 'android/app/build.gradle.kts'
s = open(p).read()
s = s.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
s = re.sub(r'minSdk = [^\n]+', 'minSdk = 24', s)
s += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
open(p, 'w').write(s)
print(s)

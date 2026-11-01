# VEX Health — دانانی ئۆتۆماتیکی iOS: ئاگادارکردنەوەی هەنگاو (Live Activity + Dynamic Island + Widget)
#
# بەکارهێنان (لە فۆڵدەری پڕۆژە، لەسەر Mac، دوای `flutter create .`):
#     gem install xcodeproj        # یەک جار (لەگەڵ CocoaPods پێشتر هاتووە)
#     ruby tools/setup_ios.rb
#
# ئەم کارانە خۆی دەکات (دووبارە جێبەجێکردنی بێ مەترسییە):
#   1. StepsBridge.swift و VexShared.swift دەخاتە ناو Runner
#   2. Target ی «VexStepsWidget» (Widget Extension) دروست دەکات و دەیخاتە ناو ئەپەکە
#   3. App Group (group.<bundle id>) بۆ هەردوو Target + Info.plist + AppDelegate
#   4. ActivityKit بە weak دەبەستێت بۆ ئەوەی ئەپ لە iOS 13–16.0 ش کار بکات
# دوای ئەوە تەنها لە Xcode «Team» هەڵبژێرە (Signing & Capabilities) بۆ هەردوو Target.
require 'fileutils'

begin
  require 'xcodeproj'
rescue LoadError
  abort 'xcodeproj نییە. یەکەم جار: gem install xcodeproj'
end

ROOT = File.expand_path('..', __dir__)
IOS = File.join(ROOT, 'ios')
SRC = File.join(ROOT, 'native', 'ios')
PROJ = File.join(IOS, 'Runner.xcodeproj')
EXT = 'VexStepsWidget'
abort 'پۆشەی ios/ نییە. یەکەم جار `flutter create .` جێبەجێ بکە.' unless File.directory?(PROJ)

project = Xcodeproj::Project.open(PROJ)
runner = project.targets.find { |t| t.name == 'Runner' } or abort 'Target ی Runner نەدۆزرایەوە.'

bundle = runner.build_configurations.map { |c| c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] }.compact.first
abort 'PRODUCT_BUNDLE_IDENTIFIER نەدۆزرایەوە.' unless bundle && !bundle.include?('$')
group_id = "group.#{bundle}"
puts "bundle: #{bundle}\napp group: #{group_id}"

def copy(src, dst)
  FileUtils.mkdir_p(File.dirname(dst))
  FileUtils.cp(src, dst)
  puts "  + #{dst.sub(ROOT + '/', '')}"
end

def add_file(project, group, path, targets)
  ref = group.files.find { |f| f.path == File.basename(path) } || group.new_reference(File.basename(path))
  targets.each do |t|
    t.add_file_references([ref]) unless t.source_build_phase.files_references.include?(ref)
  end
  ref
end

# ---------- 1. فایلەکان ----------
copy(File.join(SRC, 'Runner', 'StepsBridge.swift'), File.join(IOS, 'Runner', 'StepsBridge.swift'))
shared = File.read(File.join(SRC, 'Shared_VexShared.swift')).sub(/static let appGroup = "[^"]*"/, "static let appGroup = \"#{group_id}\"")
FileUtils.mkdir_p(File.join(IOS, 'Shared'))
File.write(File.join(IOS, 'Shared', 'VexShared.swift'), shared)
puts '  + ios/Shared/VexShared.swift'
Dir[File.join(SRC, EXT, '*.swift')].each { |f| copy(f, File.join(IOS, EXT, File.basename(f))) }

# Info.plist ی Extension
File.write(File.join(IOS, EXT, 'Info.plist'), <<~PLIST)
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
  <dict>
  	<key>CFBundleDevelopmentRegion</key><string>$(DEVELOPMENT_LANGUAGE)</string>
  	<key>CFBundleDisplayName</key><string>VEX</string>
  	<key>CFBundleExecutable</key><string>$(EXECUTABLE_NAME)</string>
  	<key>CFBundleIdentifier</key><string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
  	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  	<key>CFBundleName</key><string>$(PRODUCT_NAME)</string>
  	<key>CFBundlePackageType</key><string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
  	<key>CFBundleShortVersionString</key><string>$(FLUTTER_BUILD_NAME)</string>
  	<key>CFBundleVersion</key><string>$(FLUTTER_BUILD_NUMBER)</string>
  	<key>NSExtension</key>
  	<dict>
  		<key>NSExtensionPointIdentifier</key><string>com.apple.widgetkit-extension</string>
  	</dict>
  </dict>
  </plist>
PLIST

# Entitlements (App Group)
ent = lambda do |path|
  File.write(path, <<~ENT)
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    	<key>com.apple.security.application-groups</key>
    	<array><string>#{group_id}</string></array>
    </dict>
    </plist>
  ENT
end
ent.call(File.join(IOS, EXT, "#{EXT}.entitlements"))
runner_ent = File.join(IOS, 'Runner', 'Runner.entitlements')
if File.exist?(runner_ent) && !File.read(runner_ent).include?(group_id)
  s = File.read(runner_ent)
  if s.include?('com.apple.security.application-groups')
    s = s.sub(%r{(<key>com.apple.security.application-groups</key>\s*<array>)}, "\\1<string>#{group_id}</string>")
  else
    s = s.sub('<dict>', "<dict>\n\t<key>com.apple.security.application-groups</key>\n\t<array><string>#{group_id}</string></array>")
  end
  File.write(runner_ent, s)
elsif !File.exist?(runner_ent)
  ent.call(runner_ent)
end

# ---------- 2. Runner ----------
runner_group = project.main_group.find_subpath('Runner', true)
add_file(project, runner_group, 'StepsBridge.swift', [runner])
shared_group = project.main_group.find_subpath('Shared', true)
shared_group.set_source_tree('<group>')
shared_group.set_path('Shared')
runner_group.files.find { |f| f.path == 'Runner.entitlements' } || runner_group.new_reference('Runner.entitlements')

runner.build_configurations.each do |c|
  bs = c.build_settings
  bs['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  flags = Array(bs['OTHER_LDFLAGS'] || ['$(inherited)'])
  flags = flags.flat_map { |f| f.split(' ') }
  unless flags.include?('ActivityKit')
    flags += ['-weak_framework', 'ActivityKit']
  end
  bs['OTHER_LDFLAGS'] = flags
end

# ---------- 3. Widget Extension ----------
ext = project.targets.find { |t| t.name == EXT }
unless ext
  ext = project.new_target(:app_extension, EXT, :ios, '16.2')
  puts "  + Target #{EXT}"
end
ext_group = project.main_group.find_subpath(EXT, true)
ext_group.set_source_tree('<group>')
ext_group.set_path(EXT)
Dir[File.join(IOS, EXT, '*.swift')].sort.each { |f| add_file(project, ext_group, f, [ext]) }
ext_group.files.find { |f| f.path == 'Info.plist' } || ext_group.new_reference('Info.plist')
ext_group.files.find { |f| f.path == "#{EXT}.entitlements" } || ext_group.new_reference("#{EXT}.entitlements")
add_file(project, shared_group, 'VexShared.swift', [runner, ext])

%w[WidgetKit SwiftUI].each do |fw|
  path = "System/Library/Frameworks/#{fw}.framework"
  unless ext.frameworks_build_phase.files_references.any? { |r| r.path == path }
    ref = project.frameworks_group.files.find { |r| r.path == path } ||
          project.frameworks_group.new_reference(path).tap { |r| r.source_tree = 'SDKROOT'; r.name = "#{fw}.framework" }
    ext.frameworks_build_phase.add_file_reference(ref, true)
  end
end

runner_dev = runner.build_configurations.map { |c| c.build_settings['DEVELOPMENT_TEAM'] }.compact.first
ext.build_configurations.each do |c|
  bs = c.build_settings
  bs['PRODUCT_NAME'] = '$(TARGET_NAME)'
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = "#{bundle}.#{EXT}"
  bs['INFOPLIST_FILE'] = "#{EXT}/Info.plist"
  bs['CODE_SIGN_ENTITLEMENTS'] = "#{EXT}/#{EXT}.entitlements"
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = '16.2'
  bs['SWIFT_VERSION'] = '5.0'
  bs['TARGETED_DEVICE_FAMILY'] = '1,2'
  bs['SKIP_INSTALL'] = 'YES'
  bs['CODE_SIGN_STYLE'] = 'Automatic'
  bs['GENERATE_INFOPLIST_FILE'] = 'NO'
  bs['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  bs['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  bs['DEVELOPMENT_TEAM'] = runner_dev if runner_dev
end
# وەشانی ئەپ (FLUTTER_BUILD_NAME/NUMBER) لە Generated.xcconfig — بێ Pods، تەنها بۆ ئەوەی وەشانی Extension وەک ئەپ بێت
gen = project.files.find { |f| f.path.to_s.end_with?('Generated.xcconfig') }
unless gen
  fl = project.main_group.find_subpath('Flutter', true)
  gen = fl.new_reference('Generated.xcconfig')
end
ext.build_configurations.each { |c| c.base_configuration_reference = gen }

# ئەپەکە Extension ـەکە لەگەڵ خۆی دەبات
runner.add_dependency(ext) unless runner.dependencies.any? { |d| d.target == ext }
embed = runner.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' || p.name == 'Embed App Extensions' }
unless embed
  embed = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed.name = 'Embed Foundation Extensions'
  embed.symbol_dst_subfolder_spec = :plug_ins
  runner.build_phases << embed
end
unless embed.files_references.include?(ext.product_reference)
  bf = embed.add_file_reference(ext.product_reference, true)
  bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end
# Embed دەبێت پێش «Thin Binary» ـی Flutter بێت
thin = runner.build_phases.find { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
if thin
  runner.build_phases.delete(embed)
  runner.build_phases.insert(runner.build_phases.index(thin), embed)
end

project.save
puts '  + Runner.xcodeproj'

# ---------- 4. Info.plist ی Runner ----------
plist = File.join(IOS, 'Runner', 'Info.plist')
s = File.read(plist)
adds = {
  'NSSupportsLiveActivities' => '<true/>',
  'NSSupportsLiveActivitiesFrequentUpdates' => '<true/>',
  'NSMotionUsageDescription' => '<string>VEX Health هەنگاوەکانت دەژمێرێت بۆ ئەوەی لە Dynamic Island و شاشەی قفڵ نیشانیان بدات.</string>',
  'NSBluetoothAlwaysUsageDescription' => '<string>VEX Health پێویستی بە بلووتوس هەیە بۆ پەیوەستبوون بە VEX Band و هاوکاتکردنی داتای تەندروستی.</string>',
  'NSLocationWhenInUseUsageDescription' => '<string>VEX Health شوێنی نزیکەیی تۆ بەکاردێنێت بۆ ژماردنی کاتەکانی بانگ بۆ شارەکەت.</string>',
}
ins = adds.reject { |k, _| s.include?("<key>#{k}</key>") }.map { |k, v| "\t<key>#{k}</key>\n\t#{v}" }.join("\n")
unless ins.empty?
  i = s.rindex('</dict>')
  s = s[0...i] + ins + "\n" + s[i..]
  File.write(plist, s)
  puts '  + ios/Runner/Info.plist'
end

# ---------- 5. AppDelegate ----------
ad = File.join(IOS, 'Runner', 'AppDelegate.swift')
s = File.read(ad)
unless s.include?('StepsBridge.shared')
  m = s.match(/^([ \t]*)GeneratedPluginRegistrant\.register\(with: ([^)]+)\)[ \t]*\n/)
  if m
    ind, reg = m[1], m[2].strip
    registrar = reg == 'self' ? 'self.registrar' : "#{reg}.registrar"
    hook = [
      '// ---- VexSteps ----',
      "if let r = #{registrar}(forPlugin: \"VexStepsBridge\") {",
      '  StepsBridge.shared.register(with: r.messenger())',
      '}',
      '// ---- VexAlerts (flutter_local_notifications) ----',
      'UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate',
    ].map { |l| ind + l }.join("\n")
    s = s.sub(m[0], m[0] + hook + "\n")
    s = "import UserNotifications\n" + s unless s.include?('import UserNotifications')
    File.write(ad, s)
    puts '  + ios/Runner/AppDelegate.swift'
  else
    puts '  ! AppDelegate.swift شێوەیەکی جیاوازی هەیە. دوای GeneratedPluginRegistrant.register ئەمە زیاد بکە:'
    puts '    StepsBridge.shared.register(with: <registrar>.messenger())'
  end
end

puts "\nتەواو بوو. لە Xcode: Signing & Capabilities ‹ Team هەڵبژێرە بۆ Runner و #{EXT}، پاشان `flutter run`."

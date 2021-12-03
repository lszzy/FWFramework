#! /bin/bash

framework_name=FWFramework

rm -rf docs
mkdir docs
mkdir "docs/$framework_name"

umbrella_name="$framework_name-umbrella.h"
umbrella_path=Example/Pods/Target\ Support\ Files
cp "$umbrella_path/$framework_name/$umbrella_name" "docs/$framework_name/"
find "$framework_name/Classes" -type f ! -regex '*.h' -name '*.h' \
    -exec cp {} "docs/$framework_name/" \;

sourcekitten doc -- -project _Pods.xcodeproj -target $framework_name > "docs/$framework_name/swift.json"
sourcekitten doc --objc "docs/$framework_name/$umbrella_name" -- -x objective-c -isysroot $(xcrun --show-sdk-path --sdk iphonesimulator) -I $(pwd) -fmodules > "docs/$framework_name/objc.json"
jazzy --sourcekitten-sourcefile "docs/$framework_name/swift.json","docs/$framework_name/objc.json"

rm -rf "docs/$framework_name"
cp *.md docs/

#! /bin/bash

framework_name=FWFramework

rm -rf docs
mkdir docs
mkdir "docs/$framework_name"

lib_path="docs/$framework_name/"
sourcekitten doc -- -project Example/Pods/Pods.xcodeproj -target $framework_name > "$lib_path/swift.json"
jazzy --include-spi-declarations --sourcekitten-sourcefile "$lib_path/swift.json"

rm -rf $lib_path
rm -rf Example/build/
cp *.md docs/

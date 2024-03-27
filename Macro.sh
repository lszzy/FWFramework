#! /bin/bash

swift build -c release --target FWMacroMacros
rm -f Sources/macros/FWMacroMacros
cp -f .build/release/FWMacroMacros Sources/macros/


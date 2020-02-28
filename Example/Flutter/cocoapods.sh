#!/bin/sh
# 创建模块：flutter create --template module example
# 编译模块：flutter版本1.13.6才有--cocoapods参数，可官网下载或切换版本
# 切换版本：git clone -b v1.13.6 https://github.com/flutter/flutter.git
cd example
flutter build ios-framework --cocoapods --output=../cocoapods/

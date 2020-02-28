#!/bin/sh
# 创建模块：flutter create --template module example
# 编译模块：flutter版本1.13.6之后才有--cocoapods参数，检出分支git clone -b v1.13.6 https://github.com/flutter/flutter.git或者官网下载
cd example
flutter build ios-framework --cocoapods --output=../cocoapods/

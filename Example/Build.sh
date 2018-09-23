#!/bin/sh
# author wuyong<admin@wuyong.site>
# 运行脚本前，需要将"自动管理签名"的开关关闭并配置好代码环境和编译选项

# 项目配置列表，必须
# 空间名称，使用workspace时配置生效
WORKSPACE_NAME=""
# 项目名称，不使用workspace时配置生效
PROJECT_NAME="Example"
# scheme名称，即编译target名称
SCHEME_NAME="Example"
# plist文件路径，用于读取和修改版本号
PROJECT_PLIST="Example/Info.plist"
# 当前打包环境，只应用于ipa包名，可自定义，示例："dev", "test", "prod"
PROJECT_ENV="dev"
# 编译环境配置，一般Release，支持"Debug"、"Release"
PROJECT_CONF="Release"

# 证书配置列表，只需配置用到的环境，必须
# 查找有效证书命令：security find-identity -p codesigning -v ~/Library/Keychains/login.keychain
# PROVISIONING_PROFILE参数支持名称和UUID，格式：wu_adhoc 或 00000000-0000-0000-0000-000000000000
# ad-hoc配置
ADHOC_SIGN_IDENTITY=""
ADHOC_SIGN_TEAMID=""
ADHOC_PROVISIONING_PROFILE=""
ADHOC_BUNDLE_IDENTIFIER=""
# appstore配置
APPSTORE_SIGN_IDENTITY=""
APPSTORE_SIGN_TEAMID=""
APPSTORE_PROVISIONING_PROFILE=""
APPSTORE_BUNDLE_IDENTIFIER=""
# enterprise配置
ENTERPRISE_SIGN_IDENTITY=""
ENTERPRISE_SIGN_TEAMID=""
ENTERPRISE_PROVISIONING_PROFILE=""
ENTERPRISE_BUNDLE_IDENTIFIER=""
# development配置
DEVELOPMENT_SIGN_IDENTITY=""
DEVELOPMENT_SIGN_TEAMID=""
DEVELOPMENT_PROVISIONING_PROFILE=""
DEVELOPMENT_BUNDLE_IDENTIFIER=""

# 其它参数配置，可通过参数和输入确定，可选
# 当前证书方式，支持"ad-hoc", "appstore", "enterprise", "development"
ARG_METHOD=""
# 当前编译版本号，格式：1.7.0.1
ARG_VERSION=""

# 路径配置，默认脚本和项目同一级目录
# 当前脚本路径
PATH_PWD=`pwd`
# 当前项目路径
PATH_PROJECT=$PATH_PWD
# 输出产品路径
PATH_PRODUCTS=$PATH_PWD/Products
# 编译临时路径
PATH_BUILD=$PATH_PWD/Build

# 步骤1，配置阶段
echo "1. Config app"
cd $PATH_PROJECT

# 检查配置参数
# 检查plist文件是否存在，否则报错
if [ ! -f "$PATH_PROJECT/$PROJECT_PLIST" ]; then
	echo "Config PROJECT_PLIST error"
	exit 1
fi

# 参数解析，":v:m:h"中第一个冒号表示忽略错误，选项后面的冒号表示该选项需要参数
# 读取当前参数使用$OPTARG，当前索引使用$OPTIND
while getopts ":v:m:h" opt
do
	case $opt in
		v)
			ARG_VERSION=$OPTARG
			;;
		m)
			ARG_METHOD=$OPTARG
			;;
		h)
			echo "Usage: $0 [-v <version>] [-m <method>] [-h]. Example: $0 -v 1.7.0.1 -m ad-hoc"
			exit 1;;
		?)
			echo "Usage: $0 [-v <version>] [-m <method>] [-h]. Example: $0 -v 1.7.0.1 -m ad-hoc"
			exit 1;;
	esac
done
shift $(($OPTIND - 1))

# 没配置且为传参数时，输入参数
# 输入版本号
if [ ! -n "${ARG_VERSION}" ]; then
	CURRENT_VERSION=`/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PATH_PROJECT/$PROJECT_PLIST"`
	echo "~~~~~~~~~~ Please Input Version: ( Default ${CURRENT_VERSION} ) ~~~~~~~~~~~~~~~"

	read INPUT_VERSION
	sleep 0.5
	# 检查是否有输入
	if [ -n "$INPUT_VERSION" ]
	then
		ARG_VERSION=$INPUT_VERSION
	else
		ARG_VERSION=$CURRENT_VERSION
	fi
fi
# 输入证书方式
if [ ! -n "${ARG_METHOD}" ]; then
	echo "~~~~~~~~~~ Please Choose Method: ( Serial Number ) ~~~~~~~~~~~~~~~"
	METHOD_LIST="ad-hoc appstore enterprise development"
	METHOD_INDEX=0
	for METHOD_NAME in $METHOD_LIST
	do
		# let把变量当做数字处理
		let METHOD_INDEX=${METHOD_INDEX}+1
		echo "${METHOD_INDEX} : ${METHOD_NAME}"
	done

	read INPUT_METHOD
	sleep 0.5
	# 检查是否有输入
	if [ -n "$INPUT_METHOD" ]
	then
		if [ "$INPUT_METHOD" = "1" ]
		then
			ARG_METHOD="ad-hoc"
		elif [ "$INPUT_METHOD" = "2" ]
		then
			ARG_METHOD="appstore"
		elif [ "$INPUT_METHOD" = "3" ]
		then
			ARG_METHOD="enterprise"
		elif [ "$INPUT_METHOD" = "4" ]
		then
			ARG_METHOD="development"
		else
			echo "Config ARG_METHOD error"
			exit 1
		fi
	else
		echo "Config ARG_METHOD error"
		exit 1
	fi
fi

# 确定当前所用证书配置
SIGN_IDENTITY=""
SIGN_TEAMID=""
PROVISIONING_PROFILE=""
BUNDLE_IDENTIFIER=""
SIGN_CERTIFICATE=""
if [ "$ARG_METHOD" = "ad-hoc" ]
then
	SIGN_IDENTITY=$ADHOC_SIGN_IDENTITY
	SIGN_TEAMID=$ADHOC_SIGN_TEAMID
	PROVISIONING_PROFILE=$ADHOC_PROVISIONING_PROFILE
	BUNDLE_IDENTIFIER=$ADHOC_BUNDLE_IDENTIFIER
	SIGN_CERTIFICATE="iPhone Distribution"
elif [ "$ARG_METHOD" = "appstore" ]
then
	SIGN_IDENTITY=$APPSTORE_SIGN_IDENTITY
	SIGN_TEAMID=$APPSTORE_SIGN_TEAMID
	PROVISIONING_PROFILE=$APPSTORE_PROVISIONING_PROFILE
	BUNDLE_IDENTIFIER=$APPSTORE_BUNDLE_IDENTIFIER
	SIGN_CERTIFICATE="iPhone Distribution"
elif [ "$ARG_METHOD" = "enterprise" ]
then
	SIGN_IDENTITY=$ENTERPRISE_SIGN_IDENTITY
	SIGN_TEAMID=$ENTERPRISE_SIGN_TEAMID
	PROVISIONING_PROFILE=$ENTERPRISE_PROVISIONING_PROFILE
	BUNDLE_IDENTIFIER=$ENTERPRISE_BUNDLE_IDENTIFIER
	SIGN_CERTIFICATE="iPhone Distribution"
elif [ "$ARG_METHOD" = "development" ]
then
	SIGN_IDENTITY=$DEVELOPMENT_SIGN_IDENTITY
	SIGN_TEAMID=$DEVELOPMENT_SIGN_TEAMID
	PROVISIONING_PROFILE=$DEVELOPMENT_PROVISIONING_PROFILE
	BUNDLE_IDENTIFIER=$DEVELOPMENT_BUNDLE_IDENTIFIER
	SIGN_CERTIFICATE="iPhone Developer"
else
	echo "Config ARG_METHOD error"
	exit 1
fi

# 配置ipa名称
# 当前时间
BUILD_DATE=`date +%Y%m%d_%H%M%S`
# 当前svn版本号，获取失败为空
SVN_REVISION=`svn info | grep "Revision:" | awk 'NR==1{print $2}'`
# 生成ipa文件名
if [ ! -n "${SVN_REVISION}" ]; then
	IPA_NAME="${SCHEME_NAME}_${ARG_VERSION}_${PROJECT_ENV}_${BUILD_DATE}.ipa"
else
	IPA_NAME="${SCHEME_NAME}_${ARG_VERSION}_${PROJECT_ENV}_${BUILD_DATE}_r${SVN_REVISION}.ipa"
fi

# 写入版本号配置到plist文件
CURRENT_VERSION=`/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PATH_PROJECT/$PROJECT_PLIST"`
if [ "$ARG_VERSION" != "$CURRENT_VERSION" ]; then
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $ARG_VERSION" "$PATH_PROJECT/$PROJECT_PLIST"
fi

# 步骤2，编译阶段
echo "2. Build app ( ${ARG_VERSION} ${ARG_METHOD} )"

# 获取xcode版本号，xcode8和9编译配置不同，本脚本支持Xcode9
# XCODE_VERSION=`xcodebuild -showBuildSettings | grep "XCODE_VERSION_ACTUAL" | awk 'NR==1{print $3}'`
# 根据[ $XCODE_VERSION -lt 900 ]判断xcode8，否则xcode9

# 清除之前的编译缓存
rm -rf $PATH_BUILD
# 配置了workspace，则使用workspace编译，否则使用project编辑；derivedDataPath为临时文件路径
# Xcode9默认archive命令不需要指定签名等，使用xcode配置。查看参数列表：xcodebuild -showBuildSettings。如需指定签名等(注意：指定bundleID后相关framework也会修改为该bundleID)，格式如下
# CODE_SIGN_IDENTITY="${SIGN_IDENTITY}" PROVISIONING_PROFILE_SPECIFIER="${PROVISIONING_PROFILE}" PRODUCT_BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER}"
PATH_PRODUCT="$PATH_PRODUCTS/${SCHEME_NAME}_${ARG_VERSION}_${ARG_METHOD}"
if [ -n "${WORKSPACE_NAME}" ]; then
	xcodebuild -workspace "$PATH_PROJECT/$WORKSPACE_NAME.xcworkspace" -scheme "$SCHEME_NAME" -configuration "$PROJECT_CONF" -sdk iphoneos -derivedDataPath "$PATH_BUILD" -archivePath "$PATH_PRODUCT/$SCHEME_NAME.xcarchive" clean archive build
else
	xcodebuild -project "$PATH_PROJECT/$PROJECT_NAME.xcodeproj" -scheme "$SCHEME_NAME" -configuration "$PROJECT_CONF" -sdk iphoneos -derivedDataPath "$PATH_BUILD" -archivePath "$PATH_PRODUCT/$SCHEME_NAME.xcarchive" clean archive build
fi
# 检查是否编译成功
if [ -e "$PATH_PRODUCT/${SCHEME_NAME}.xcarchive" ]; then
	# 清除编译缓存
	rm -rf $PATH_BUILD
	echo "Build app success"
else
	echo "Build app failed"
	exit 1
fi

# 步骤3，导出阶段
echo "3. Export ipa ( ${ARG_VERSION} ${ARG_METHOD} )"

# 自动生成导出exportOptionsPlist文件
# exportOptionsPlist文件中，非AppStore包，禁用bitcode时可配置compileBitcode为NO；AppStore包，禁用bitcode时可配置uploadBitcode为NO
# 导出plist配置文件模板方法：xcode使用archive然后再导出ipa，生成的ipa目录中ExportOptions.plist文件即为模板
echo '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>'${ARG_METHOD}'</string>
	<key>provisioningProfiles</key>
	<dict>
		<key>'${BUNDLE_IDENTIFIER}'</key>
		<string>'${PROVISIONING_PROFILE}'</string>
	</dict>
	<key>signingCertificate</key>
	<string>'${SIGN_CERTIFICATE}'</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>teamID</key>
	<string>'${SIGN_TEAMID}'</string>
	<key>uploadBitcode</key>
	<false/>
	<key>uploadSymbols</key>
	<true/>
	<key>compileBitcode</key>
	<false/>
</dict>
</plist>' > $PATH_PRODUCT/${SCHEME_NAME}.xcarchive.plist

# 开始导出ipa，使用archive中的签名
xcodebuild -exportArchive -archivePath "$PATH_PRODUCT/${SCHEME_NAME}.xcarchive" -exportOptionsPlist "$PATH_PRODUCT/${SCHEME_NAME}.xcarchive.plist" -exportPath "$PATH_PRODUCT/${SCHEME_NAME}.export" -allowProvisioningUpdates
# 检查是否导出ipa成功
if [ -e "$PATH_PRODUCT/${SCHEME_NAME}.export" ]; then
	# 拷贝ipa到导出根目录，并命名ipa
	cp -f $PATH_PRODUCT/${SCHEME_NAME}.export/${SCHEME_NAME}.ipa $PATH_PRODUCT/$IPA_NAME
	echo "Export ipa success"
else
	echo "Export ipa failed"
	exit 1
fi

# 自动打开目录
open $PATH_PRODUCT

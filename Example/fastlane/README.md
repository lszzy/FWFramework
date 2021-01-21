fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios pgyer_test
```
fastlane ios pgyer_test
```
Push a new test build to Pgyer
### ios pgyer_prod
```
fastlane ios pgyer_prod
```
Push a new prod build to Pgyer
### ios testflight_test
```
fastlane ios testflight_test
```
Push a new test build to TestFlight
### ios testflight_prod
```
fastlane ios testflight_prod
```
Push a new prod build to TestFlight
### ios appstore_prod
```
fastlane ios appstore_prod
```
Push a new prod build to the App Store

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

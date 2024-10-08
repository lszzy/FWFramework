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
### ios pgyer_testing
```
fastlane ios pgyer_testing
```
Push a new testing build to Pgyer
### ios pgyer_production
```
fastlane ios pgyer_production
```
Push a new production build to Pgyer
### ios testflight_testing
```
fastlane ios testflight_testing
```
Push a new testing build to TestFlight
### ios testflight_production
```
fastlane ios testflight_production
```
Push a new production build to TestFlight
### ios appstore_production
```
fastlane ios appstore_production
```
Push a new production build to the App Store

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

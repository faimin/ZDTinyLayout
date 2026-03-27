#!/bin/sh
# required: pass iOS version as first parameter
# required: pass Swift version as second parameter

set -o pipefail && \
  xcodebuild clean build \
  -project ZDTinyLayout.xcodeproj \
  -scheme ZDTinyLayoutDemo \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,name=iPhone 8,OS=$1" \
  SWIFT_VERSION=$2 \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY= \
  | bundle exec xcpretty

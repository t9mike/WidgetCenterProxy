# WidgetCenterProxy

This module exposes Apple APIs that are unavailable directly from the legacy
C# app:

- `WidgetCenter.shared` operations used by the iOS 14 widget integration.
- StoreKit 2 verified transaction history used by Sundial Classic to record
  non-refunded purchases and prove offer eligibility to CloudflareServer.

It was originally based on the
[binding-swift walkthrough](https://learn.microsoft.com/xamarin/ios/platform/binding-swift/walkthrough).

## Build the native framework

Run `./build.fat.sh` from this directory. Despite its historical name, the
script now creates a modern `WidgetCenterProxy.xcframework` containing an iOS
device slice and an arm64/x86_64 iOS Simulator slice. It builds into a unique
temporary directory and only replaces the checked-in framework after all
native build steps succeed.

The framework is consumed by `WidgetCenterProxyBinder`. If a new Swift API is
added, update `WidgetCenterProxyBinder/WidgetCenterProxyBinder/ApiDefinitions.cs`
to match the generated `WidgetCenterProxy-Swift.h` declaration, then build the
binder and the Classic Phone app.

The StoreKit bridge requires iOS 16 or later. `Transaction.all` is filtered to
verified, purchased, non-revoked transactions before JSON is returned to C#.
The JSON includes each signed transaction for the short-lived server request;
the C# layer deliberately removes those signatures before saving the shared
purchase snapshot.

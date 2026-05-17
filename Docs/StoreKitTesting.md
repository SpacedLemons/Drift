# StoreKit Testing

Drift uses StoreKit 2 for the Drift Plus subscription foundation. The app scheme is configured to use:

```text
Drift/Configuration/DriftPlus.storekit
```

## Local Products

- Monthly Plus: `drift.plus.monthly`
- Yearly Plus: `drift.plus.yearly`

Both products are auto-renewable subscriptions in one Drift Plus subscription group.

## Testing In Xcode

1. Open `Drift.xcodeproj`.
2. Select the normal `Drift` scheme.
3. Run a Debug build on a simulator.
4. Open the Drift Plus paywall from Settings or by hitting the Free daily entry limit.
5. Verify product loading, monthly purchase, yearly purchase, restore purchases, renewal behaviour, expired subscriptions, and cancelled purchases using Xcode's StoreKit testing controls.

No App Store Connect products are required for local StoreKit testing.

## Free And Plus States

In DEBUG builds, Settings includes Developer Settings:

- Entitlement Mode: Real StoreKit, Force Free, Force Plus
- Simulate free entry limit reached
- Simulate Plus entry limit reached
- Reset guide state
- Clear local data through the existing delete confirmation

Use Force Free/Force Plus for quick UI checks. Use Real StoreKit when testing purchases, restore, renewal, cancellation, expiry, or refunded transaction behaviour.

Developer Settings are compiled with `#if DEBUG` and must not appear in Release builds. Release entitlement must come from StoreKit only.

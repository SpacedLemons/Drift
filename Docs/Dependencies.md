# Dependencies

## Mockable

- Package: `https://github.com/Kolos65/Mockable.git`
- Version rule: `from 0.6.2`
- Used by: app target service protocols annotated with `@Mockable`, and unit tests that use generated mocks.
- Reason: Swift does not provide generated protocol mocks natively. Mockable keeps service and ViewModel tests focused without manually maintaining test doubles.

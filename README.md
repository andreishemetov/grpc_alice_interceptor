# grpc_alice_interceptor

[`GrpcAliceInterceptor`](lib/src/grpc_alice_interceptor.dart) records unary gRPC calls in [flutter_alice](https://pub.dev/packages/flutter_alice) for the network inspector UI.

Pair it with [`flutter_grpc_kit`](https://github.com/andreishemetov/flutter_grpc_kit) or any app that uses `grpc` `ClientChannel` interceptors.

## Install

```yaml
dependencies:
  grpc_alice_interceptor: ^0.1.0
  flutter_alice: ^2.0.1
  grpc: ^5.1.0
```

For local development, use a path dependency to this repo.

## Example

The [`example/`](example/) app runs a local Greeter server and shows captured calls in Alice:

```bash
cd example && dart run bin/server.dart   # terminal 1
cd example && flutter run                # terminal 2
```

## Usage

```dart
import 'package:flutter_alice/alice.dart';
import 'package:grpc_alice_interceptor/grpc_alice_interceptor.dart';
import 'package:flutter_grpc_kit/flutter_grpc_kit.dart';

final alice = Alice(navigatorKey: navigatorKey);
final factory = GrpcChannelFactory(gatewayUrl: 'https://grpc.example.com');

final interceptors = [
  GrpcAliceInterceptor(
    onCallRecorded: alice.addHttpCall,
    serverHost: factory.endpoint.host,
    secure: factory.endpoint.useTls,
  ),
];
```

## Development

```bash
flutter pub get
dart analyze
cd example && flutter test
```

Pull requests run the same checks via [GitHub Actions](.github/workflows/ci.yml). In branch protection, require the **analyze** status check.

## License

MIT — see [LICENSE](LICENSE).

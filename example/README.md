# grpc_alice_interceptor example

Flutter app that calls the standard gRPC **helloworld** `SayHello` RPC and records the call in [flutter_alice](https://pub.dev/packages/flutter_alice) via [`GrpcAliceInterceptor`](../lib/src/grpc_alice_interceptor.dart).

## Run

1. Start the local Greeter server (insecure, port `50051`):

   ```bash
   cd example
   dart run bin/server.dart
   ```

2. Run the Flutter app:

   ```bash
   flutter run
   ```

3. Tap **SayHello**. Open the Alice inspector from the app bar (or shake on a physical device).

### Gateway URL tips

| Target | URL |
|--------|-----|
| iOS Simulator / desktop | `http://127.0.0.1:50051` |
| Android emulator | `http://10.0.2.2:50051` |

Protos live under `protos/`. Generated stubs are in `lib/src/generated/` (from the upstream [grpc](https://pub.dev/packages/grpc) helloworld sample). Regenerate with `protoc` and `protoc_plugin` if you change the `.proto` file.

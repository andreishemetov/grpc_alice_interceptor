import 'package:grpc_alice_interceptor_example/src/generated/helloworld.pbgrpc.dart';
import 'package:grpc/grpc.dart';

class GreeterService extends GreeterServiceBase {
  @override
  Future<HelloReply> sayHello(ServiceCall call, HelloRequest request) async {
    final token = call.clientMetadata?['token'];
    final suffix = token != null && token.isNotEmpty ? ' (token: $token)' : '';
    return HelloReply()..message = 'Hello, ${request.name}!$suffix';
  }
}

Future<void> main() async {
  final server = Server.create(services: [GreeterService()]);
  await server.serve(port: 50051);
  // ignore: avoid_print
  print('Greeter listening on port ${server.port} (insecure).');
}

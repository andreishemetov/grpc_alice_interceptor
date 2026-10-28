import 'package:flutter_test/flutter_test.dart';
import 'package:grpc_alice_interceptor_example/main.dart';

void main() {
  test('parseGrpcTarget accepts host:port', () {
    expect(parseGrpcTarget('127.0.0.1:50051'), (host: '127.0.0.1', port: 50051));
  });

  test('parseGrpcTarget accepts http URL', () {
    expect(parseGrpcTarget('http://10.0.2.2:50051'), (host: '10.0.2.2', port: 50051));
  });
}

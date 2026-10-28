import 'dart:async';
import 'dart:convert';

import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/model/alice_http_error.dart';
import 'package:flutter_alice/model/alice_http_request.dart';
import 'package:flutter_alice/model/alice_http_response.dart';
import 'package:grpc/grpc.dart';
import 'grpc_payload_format.dart';
import 'package:protobuf/protobuf.dart';

const _jsonContentType = 'application/json';

/// Records unary gRPC calls in [flutter_alice] for the network inspector UI.
final class GrpcAliceInterceptor extends ClientInterceptor {
  GrpcAliceInterceptor({
    required void Function(AliceHttpCall call) onCallRecorded,
    required String serverHost,
    required bool secure,
  }) : _onCallRecorded = onCallRecorded,
       _serverHost = serverHost,
       _secure = secure;

  final void Function(AliceHttpCall call) _onCallRecorded;
  final String _serverHost;
  final bool _secure;

  static int _nextCallId = 0;

  @override
  ResponseFuture<R> interceptUnary<Q, R>(
    ClientMethod<Q, R> method,
    Q request,
    CallOptions options,
    ClientUnaryInvoker<Q, R> invoker,
  ) {
    final path = method.path;
    final callId = _nextCallId++;
    final startedAt = DateTime.now();

    final response = invoker(method, request, options);

    unawaited(
      response
          .then((result) {
            _onCallRecorded(
              _buildCall(
                callId: callId,
                path: path,
                startedAt: startedAt,
                metadata: options.metadata,
                requestPayload: request,
                responsePayload: result,
                grpcStatusCode: StatusCode.ok,
                grpcMessage: 'OK',
              ),
            );
          })
          .catchError((Object error, StackTrace stackTrace) {
            final grpcError = error is GrpcError ? error : null;
            final call = _buildCall(
              callId: callId,
              path: path,
              startedAt: startedAt,
              metadata: options.metadata,
              requestPayload: request,
              responsePayload: grpcError?.message ?? error.toString(),
              grpcStatusCode: grpcError?.code ?? StatusCode.unknown,
              grpcMessage: grpcError?.message ?? error.toString(),
              failed: true,
              stackTrace: stackTrace,
            );
            if (grpcError != null || error is Error) {
              final httpError = AliceHttpError();
              httpError.error = error.toString();
              if (error is Error) {
                httpError.stackTrace = error.stackTrace;
              } else {
                httpError.stackTrace = stackTrace;
              }
              call.error = httpError;
            }
            _onCallRecorded(call);
          }),
    );

    return response;
  }

  AliceHttpCall _buildCall({
    required int callId,
    required String path,
    required DateTime startedAt,
    required Map<String, String> metadata,
    required Object? requestPayload,
    required Object? responsePayload,
    required int grpcStatusCode,
    required String grpcMessage,
    bool failed = false,
    StackTrace? stackTrace,
  }) {
    final call = AliceHttpCall(callId);
    call.method = 'POST';
    call.client = 'gRPC';
    call.server = _serverHost;
    call.endpoint = path;
    call.secure = _secure;
    call.uri = '${_secure ? 'grpcs' : 'grpc'}://$_serverHost$path';
    call.duration = DateTime.now().difference(startedAt).inMilliseconds;
    call.loading = false;

    final maskedMetadata = maskGrpcMetadata(metadata);
    final requestBody = _aliceBody(requestPayload);
    final aliceRequest = AliceHttpRequest();
    aliceRequest.time = startedAt;
    aliceRequest.headers = {
      ...Map<String, dynamic>.from(maskedMetadata),
      'content-type': _jsonContentType,
    };
    aliceRequest.contentType = _jsonContentType;
    aliceRequest.body = requestBody;
    aliceRequest.size = _payloadSize(requestBody);
    call.request = aliceRequest;

    final responseBody = _aliceBody(responsePayload);
    final aliceResponse = AliceHttpResponse();
    aliceResponse.time = DateTime.now();
    aliceResponse.body = responseBody;
    aliceResponse.size = _payloadSize(responseBody);
    aliceResponse.status = failed ? 500 : 200;
    aliceResponse.headers = {
      'content-type': _jsonContentType,
      'grpc-status': '$grpcStatusCode',
      'grpc-message': grpcMessage,
      if (stackTrace != null && failed) 'grpc-stack-trace': stackTrace.toString(),
    };
    call.response = aliceResponse;

    return call;
  }

  int _payloadSize(Object? payload) {
    if (payload == null) {
      return 0;
    }
    return utf8.encode(jsonEncode(payload)).length;
  }

  Object? _aliceBody(Object? payload) {
    final data = grpcPayloadToLogData(payload);
    if (payload is! GeneratedMessage) {
      return data;
    }
    if (data is Map && data.isEmpty) {
      return const {};
    }
    return data;
  }
}

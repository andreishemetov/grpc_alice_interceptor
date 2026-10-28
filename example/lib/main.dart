import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_alice/alice.dart';
import 'package:grpc/grpc.dart';
import 'package:grpc_alice_interceptor/grpc_alice_interceptor.dart';

import 'src/generated/helloworld.pbgrpc.dart';

void main() {
  runApp(const ExampleApp());
}

/// Parses `http://host:port` or `host:port` for the local Greeter server.
({String host, int port}) parseGrpcTarget(String raw) {
  final trimmed = raw.trim();
  final uri = Uri.tryParse(trimmed.contains('://') ? trimmed : 'http://$trimmed');
  if (uri == null || uri.host.isEmpty) {
    throw FormatException('Invalid gateway URL: $raw');
  }
  return (host: uri.host, port: uri.hasPort ? uri.port : 50051);
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late final Alice _alice;

  ClientChannel? _channel;
  GreeterClient? _greeter;
  ({String host, int port})? _target;

  final _gatewayController = TextEditingController(text: 'http://127.0.0.1:50051');
  final _nameController = TextEditingController(text: 'world');
  final _tokenController = TextEditingController(text: 'demo-token');

  String? _lastMessage;
  String? _lastError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _alice = Alice(showInspectorOnShake: true);
    _rebuildClient();
  }

  @override
  void dispose() {
    _gatewayController.dispose();
    _nameController.dispose();
    _tokenController.dispose();
    unawaited(_channel?.shutdown());
    super.dispose();
  }

  void _rebuildClient() {
    unawaited(_channel?.shutdown());
    final target = parseGrpcTarget(_gatewayController.text);
    final channel = ClientChannel(
      target.host,
      port: target.port,
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );
    _channel = channel;
    _target = target;
    _greeter = GreeterClient(
      channel,
      interceptors: [
        GrpcAliceInterceptor(
          onCallRecorded: _alice.addHttpCall,
          serverHost: target.host,
          secure: false,
        ),
      ],
    );
  }

  Future<void> _sayHello() async {
    setState(() {
      _loading = true;
      _lastMessage = null;
      _lastError = null;
    });

    _rebuildClient();
    final token = _tokenController.text.trim();
    final metadata = <String, String>{
      if (token.isNotEmpty) 'token': token,
      'x-example-app': 'grpc_alice_interceptor_example',
    };

    try {
      final reply = await _greeter!.sayHello(
        HelloRequest(name: _nameController.text.trim()),
        options: CallOptions(metadata: metadata),
      );
      if (!mounted) {
        return;
      }
      setState(() => _lastMessage = reply.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _lastError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;

    return MaterialApp(
      navigatorKey: _alice.getNavigatorKey(),
      title: 'grpc_alice_interceptor example',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('grpc_alice_interceptor'),
          actions: [
            IconButton(
              tooltip: 'Open Alice inspector',
              onPressed: _alice.showInspector,
              icon: const Icon(Icons.network_check),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _gatewayController,
              decoration: const InputDecoration(
                labelText: 'Gateway URL',
                helperText: 'Use http://10.0.2.2:50051 on Android emulator',
              ),
              onSubmitted: (_) => _rebuildClient(),
            ),
            const SizedBox(height: 12),
            if (target != null)
              Text('Endpoint: ${target.host}:${target.port} (insecure)'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Auth token (metadata key: token, masked in Alice)',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _sayHello,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('SayHello'),
            ),
            const SizedBox(height: 24),
            if (_lastMessage != null) SelectableText('Reply: $_lastMessage'),
            if (_lastError != null)
              SelectableText(
                'Error: $_lastError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 24),
            const Text(
              'Start the sample server from the example folder:\n'
              'dart run bin/server.dart\n\n'
              'Tap SayHello, then open Alice from the app bar (or shake on device). '
              'Sensitive metadata keys such as token are masked in the inspector.',
            ),
          ],
        ),
      ),
    );
  }
}

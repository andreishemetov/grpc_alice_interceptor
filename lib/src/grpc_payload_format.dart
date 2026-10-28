import 'package:protobuf/protobuf.dart';

const _sensitiveMetadataKeys = {'authorization', 'token'};

Map<String, String> maskGrpcMetadata(Map<String, String> metadata) {
  if (metadata.isEmpty) {
    return const {};
  }

  return {
    for (final entry in metadata.entries)
      entry.key: _sensitiveMetadataKeys.contains(entry.key.toLowerCase()) ? '***' : entry.value,
  };
}

dynamic grpcPayloadToLogData(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is GeneratedMessage) {
    return value.toProto3Json();
  }
  return value;
}

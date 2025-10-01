class Evidence {
  final String type; // ex: challenge, sensor, ble
  final String detail;

  Evidence({required this.type, required this.detail});

  Map<String, String> toMap() => {'type': type, 'detail': detail};
}
import 'dart:js_interop';

@JS('google.maps.MapTypeId')
external JSAny? get _googleMapsMapTypeId;

Future<void> waitForGoogleMapsReady({
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (!_isGoogleMapsReady()) {
    if (DateTime.now().isAfter(deadline)) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

bool _isGoogleMapsReady() {
  try {
    return _googleMapsMapTypeId != null;
  } catch (_) {
    return false;
  }
}

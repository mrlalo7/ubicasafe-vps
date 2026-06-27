import 'maps_ready_stub.dart' if (dart.library.html) 'maps_ready_web.dart'
    as impl;

Future<void> waitForGoogleMapsReady({
  Duration timeout = const Duration(seconds: 8),
}) {
  return impl.waitForGoogleMapsReady(timeout: timeout);
}

import 'dart:js_interop';

@JS('tcPlaySound')
external void _tcPlaySound(JSString type);

void playWebSound(String type) {
  try {
    _tcPlaySound(type.toJS);
  } catch (_) {}
}

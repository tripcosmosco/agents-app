import 'audio_web_helper_stub.dart'
    if (dart.library.js) 'audio_web_helper_web.dart';

void triggerWebSound(String type) {
  playWebSound(type);
}

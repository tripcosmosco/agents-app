// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js' as js;

void redirectWebBrowser(String url) {
  try {
    // If window.tcLaunchGoogle exists, attempt Google Identity Services One Tap / Prompt first
    if (js.context.hasProperty('tcLaunchGoogle')) {
      js.context.callMethod('tcLaunchGoogle', []);
      return;
    }
  } catch (_) {}
  html.window.location.href = url;
}

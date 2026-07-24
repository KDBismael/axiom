import 'package:url_launcher/url_launcher.dart';

/// Thin injectable wrapper over `url_launcher` so controllers can be unit
/// tested without touching platform channels (same rationale as
/// `EvidencePickerService` wrapping `image_picker`).
class UrlOpener {
  Future<bool> open(String url) {
    return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

import 'package:url_launcher/url_launcher.dart';

/// Open an issue in Linear. Tries the stored URL first, falls back to search.
Future<void> openInLinear({String? url, String? identifier}) async {
  final targetUrl = url ??
      (identifier != null
          ? 'https://linear.app/issue/$identifier'
          : null);
  if (targetUrl == null) return;
  final uri = Uri.parse(targetUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

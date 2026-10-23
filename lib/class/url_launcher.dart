import 'package:url_launcher/url_launcher.dart';

class UrlLauncher {
  static Future<void> url(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw 'Could not launch $url';
    } else {
      throw 'Could not launch $url';
    }
  }
}

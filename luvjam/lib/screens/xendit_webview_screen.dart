import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class XenditWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String? orderId;

  const XenditWebViewScreen({
    super.key,
    required this.checkoutUrl,
    this.orderId,
  });

  @override
  State<XenditWebViewScreen> createState() =>
      _XenditWebViewScreenState();
}

class _XenditWebViewScreenState
    extends State<XenditWebViewScreen> {
  bool _opening = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openCheckout();
  }

  Future<void> _openCheckout() async {
    final uri = Uri.tryParse(widget.checkoutUrl);

    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty) {
      setState(() {
        _opening = false;
        _error = 'Invalid checkout URL.';
      });
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!mounted) return;

      setState(() {
        _opening = false;
        if (!opened) {
          _error = 'Could not open the payment page.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _opening = false;
        _error = 'Unable to open checkout. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xendit Checkout')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _opening
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _error == null
                          ? Icons.open_in_browser
                          : Icons.error_outline,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error ??
                          'Checkout opened in your browser. '
                              'Complete your payment there, then return here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _openCheckout,
                      child: const Text('Open Checkout Again'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to App'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

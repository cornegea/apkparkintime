import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;

  const PaymentWebViewPage({super.key, required this.paymentUrl});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isPaymentFinished = false;

  @override
  void initState() {
    super.initState();

    print("--- WebView Page Initialized ---");
    print("Attempting to load URL: ${widget.paymentUrl}");
    print("---------------------------------");

    // Inisialisasi controller WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Mencetak progres loading untuk debugging
            print("WebView is loading (progress : $progress%)");
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
            // Cek jika URL mengandung callback 'finish'
            if (url.contains('https://app.parkintime.web.id/payment/finish.php') && !_isPaymentFinished) {
              _isPaymentFinished = true; // Tandai agar tidak dieksekusi berulang kali
              _showSuccessAndPop();
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Mencetak detail error jika gagal memuat
            print('''
            Page resource error:
              code: ${error.errorCode}
              description: ${error.description}
              errorType: ${error.errorType}
              isForMainFrame: ${error.isForMainFrame}
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            // Mencetak setiap kali akan ada navigasi ke URL baru
            print('Allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _showSuccessAndPop() {
    // Pastikan widget masih ada di tree sebelum menampilkan dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Payment Success'),
          content: Text('Your payment was successful. You will be redirected.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
                // Kembali ke halaman paling awal (root) dari stack navigasi
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // PERUBAHAN: Widget WillPopScope untuk menangani tombol kembali fisik di Android
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false; // Mencegah aplikasi keluar jika WebView bisa kembali
        }
        return true; // Izinkan aplikasi keluar jika WebView tidak bisa kembali
      },
      child: Scaffold(
        // PERUBAHAN: AppBar telah dihapus dari sini
        body: SafeArea( // Menggunakan SafeArea agar konten tidak tertutup notch/status bar
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

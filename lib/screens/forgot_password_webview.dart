import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ForgotPasswordWebView extends StatefulWidget {
  const ForgotPasswordWebView({super.key});

  @override
  State<ForgotPasswordWebView> createState() => _ForgotPasswordWebViewState();
}

class _ForgotPasswordWebViewState extends State<ForgotPasswordWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isMessageShown = false; // Penanda untuk memastikan dialog hanya muncul sekali

  // URL untuk halaman lupa kata sandi
  final String forgotPasswordUrl = 'https://app.parkintime.web.id/flutter/reset-password/forgot-password.php';

  // URL yang menandakan bahwa email instruksi telah terkirim
  final String successMessageUrl = 'https://app.parkintime.web.id/flutter/reset-password/forgot-password.php?message=If+an+account+with+that+email+exists%2C+we+have+sent+instructions+to+reset+your+password.';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Loading progress
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Cek jika URL saat ini adalah URL sukses dan dialog belum ditampilkan
            if (url == successMessageUrl && !_isMessageShown) {
              _isMessageShown = true; // Tandai bahwa dialog akan ditampilkan
              _showSuccessAndPop();
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Handle error jika diperlukan
            print('Page resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(forgotPasswordUrl));
  }

  void _showSuccessAndPop() {
    // Pastikan widget masih terpasang di tree
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Pengguna harus menekan tombol OK
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Request Sent'),
          content: const Text('If your email is registered, we have sent instructions to reset your password.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
                Navigator.of(context).pop();      // Kembali ke halaman login
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false; // Mencegah menutup WebView jika ada halaman sebelumnya
        }
        return true; // Izinkan menutup WebView jika tidak ada halaman sebelumnya
      },
      child: Scaffold(
        appBar: AppBar(
          // --- PERUBAHAN DI SINI ---
          title: const Text("Forgot Password"),
          backgroundColor: const Color(0xFF629584), // Warna background baru
          foregroundColor: Colors.white, // Warna untuk judul dan ikon
          // ------------------------
        ),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const Center(
                  // Anda mungkin juga ingin mengubah warna indikator loading agar serasi
                  child: CircularProgressIndicator(color: Color(0xFF629584)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
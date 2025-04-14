import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:women_safety/maps.dart';
// Import your existing Maps page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebPage(),
    );
  }
}

class WebPage extends StatefulWidget {
  const WebPage({Key? key}) : super(key: key);

  @override
  _WebPageState createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
          'https://legalassistantllama-pd9okxbvnjhdg73eww74zw.streamlit.app/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            if (await _webViewController.canGoBack()) {
              await _webViewController.goBack(); // Navigate back within WebView
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        WomenSafetyApp()), // Navigate to your existing MapsPage
              );
            }
          },
        ),
        title: Text("Legal Assistant"),
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}

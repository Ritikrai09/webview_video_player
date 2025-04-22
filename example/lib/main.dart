import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webviewtube/webviewtube.dart';

import 'customized_player.dart';
import 'playlist_player.dart';
import 'webviewtube_decorated_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Webviewtube',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WebviewtubeDemo(),
    );
  }
}

class WebviewtubeDemo extends StatefulWidget {
  const WebviewtubeDemo({Key? key}) : super(key: key);

  @override
  State<WebviewtubeDemo> createState() => _WebviewtubeDemoState();
}

class _WebviewtubeDemoState extends State<WebviewtubeDemo> {
  late final WebviewtubeController controller;

  @override
  void initState() {
    super.initState();

    // To allow the user to watch the video in the YouTube app or website when
    // tapping on the YouTube logo, you can use the `onPlayerNavigationRequest`
    // callback with `url_launcher`.
    controller = WebviewtubeController(
      options: const WebviewtubeOptions(
          forceHd: true, loop: true, interfaceLanguage: 'en'),
      onPlayerNavigationRequest: (uri) async {
        if (uri.host == 'www.youtube.com') {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return false;
        }
        return false;
      },
    );
  }

  @override
  void dispose() {
    // If a controller is passed to the player, remember to dispose it when
    // it's not in need.
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Webviewtube Demo'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Default IFrame Player',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              WebviewtubePlayer(
                videoId: '4AoFA19gbLo',
                controller: controller,
              ),
            ],
          ),
          const SizedBox(height: 70),
          ElevatedButton(
            onPressed: () async {
              controller.pause();
              debugPrint(
                  '${controller.value.videoMetadata.title} paused at ${controller.value.position}');
              await Navigator.of(context).push<void>(MaterialPageRoute(
                  builder: (_) => const WebviewtubeDecoratedPlayer()));
              // when popping back, make the player continues to play
              controller.play();
              debugPrint(
                  'Continue to play ${controller.value.videoMetadata.title}');
            },
            child: const Text(
              'Webviewtube Decorated Player',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.pause();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CustomizedPlayer()));
            },
            child: const Text(
              'Customized Player',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.pause();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PlaylistPlayer()));
            },
            child: const Text(
              'Playlist Player',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'player.dart';
import 'ads/loadBannerAd.dart' as banner_ad_loader;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Toepen',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: const TopBar(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  List<Player> players = [];

  void addPlayer(name) {
    players.add(Player(name: name));
    sortPlayers();
    notifyListeners();
  }

  void removePlayer(player) {
    players.remove(player);
    notifyListeners();
  }

  void addScore(player) {
    if (players.contains(player)) {
      player.addScore();
      notifyListeners();
    }
  }

  void subtractScore(player) {
    if (players.contains(player)) {
      player.subtractScore();
      notifyListeners();
    }
  }

  void updatePlayerName(player, name) {
    player.name = name;
    sortPlayers();
    notifyListeners();
  }

  void sortPlayers() {
    players.sort((a, b) => a.name.compareTo(b.name));
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toepen'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Add player',
            onPressed: () => {
              appState.addPlayer(""),
              appState.sortPlayers()
            },
          ),
        ],
      ),
      body: const MyHomePage()
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var players = appState.players;

    return Scaffold(
      bottomNavigationBar: banner_ad_loader.MyBannerAdWidget(adSize: AdSize.banner),
      body: ListView(
        children: [
          for (var player in players)
            PlayerCard (
              player: player,
            ),
        ],
      ),
    );
  }
}

class PlayerCard extends StatefulWidget {
  final Player player;

  const PlayerCard({
    super.key,
    required this.player,
  });

  @override
  State<StatefulWidget> createState() => _PlayerCard();
}


class _PlayerCard extends State<PlayerCard> {
  bool isEditable = false;

  @override
  Widget build(BuildContext context) {
    var player = widget.player;
    var textEditingController = TextEditingController(text: player.name);

    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.displayMedium!.copyWith(
      color: player.isDead() ? Colors.red : player.hasPoverty() ? Colors.yellow : theme.colorScheme.onPrimary,
      fontSize: 20,
    );
    final scoreStyle = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontSize: 22,
    );

    var appState = context.watch<MyAppState>();

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Builder(builder: (context) {
                if (isEditable || textEditingController.text.isEmpty) {
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: theme.colorScheme.onPrimary,
                        onPressed: () => {
                          appState.removePlayer(player),
                          setState(() => isEditable = false)
                        },
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: textEditingController,
                          cursorColor: Colors.greenAccent,
                          style: scoreStyle,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        color: theme.colorScheme.onPrimary,
                        onPressed: () => {
                          appState.updatePlayerName(player, textEditingController.text),
                          setState(() => isEditable = false)
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel),
                        color: theme.colorScheme.onPrimary,
                        onPressed: () => setState(() => isEditable = false)
                      ),
                    ],
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                color: theme.colorScheme.onPrimary,
                                onPressed: () => setState(() => isEditable = !isEditable),
                              ),
                              Expanded(
                                child: Text(player.name, style: nameStyle, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text('Score: ${player.score}', style: scoreStyle),
                        )
                      ],
                    ),
                  );
                }
              }),
            ),
            if(!isEditable && textEditingController.text.isNotEmpty)
              Row(
                children: [
                  IconButton(
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                            Colors.redAccent)),
                    onPressed: () =>
                    {
                      appState.addScore(player)
                    },
                    icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
                  ),
                  IconButton(
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                            Colors.redAccent)),
                    onPressed: () =>
                    {
                      appState.subtractScore(player)
                    },
                    icon: Icon(
                        Icons.remove, color: theme.colorScheme.onPrimary),
                  ),
                ],
              )
          ],
        ),
      )
    );
  }
}
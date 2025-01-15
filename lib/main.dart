import 'dart:async';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/game.dart';
import 'model/player.dart';
import 'auth/auth_service.dart';
import 'auth/login_screen.dart';
import 'ads/loadBannerAd.dart' as banner_ad_loader;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(MobileAds.instance.initialize());

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Toepen1',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              return const TopBar();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  Game currentGame = Game(players: []);

  void addPlayer(String name) {
    currentGame.addPlayer(name);
    notifyListeners();
  }

  void removePlayer(String id) {
    currentGame.removePlayer(id);
    notifyListeners();
  }

  void addScore(String id) {
    Player? player = currentGame.getPlayer(id);
    if (player == null) return;
    player.addScore();
    notifyListeners();
    }

  void subtractScore(String id) {
    Player? player = currentGame.getPlayer(id);
    if (player == null) return;
    player.subtractScore();
    notifyListeners();
  }

  void updatePlayerName(String id, String name) {
    currentGame.updatePlayerName(id, name);
    notifyListeners();
  }

  void sortPlayers() {
    currentGame.sortPlayers();
  }
}

//TODO: Translate to english (or make some sort of translation functionality)
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Sign out',
          onPressed: () async {
            final bool? logout = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Uitloggen'),
                  content: const Text('Weet je zeker dat je wilt uitloggen?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuleren'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Uitloggen'),
                    ),
                  ],
                );
              },
            );

            if (logout == true) {
              await AuthService().signOut();
            }
          },
        ),
        title: StreamBuilder<User?>(
          stream: AuthService().userChanges,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final user = snapshot.data!;
              if (user.displayName != null) {
                return Text("Welcome ${user.displayName}");
              }
              return const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const Text('Toepen');
          },
        ),
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
      body: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var players = appState.currentGame.players ?? [];

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
                          appState.removePlayer(player.id),
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
                          appState.updatePlayerName(player.id, textEditingController.text),
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
                      appState.addScore(player.id)
                    },
                    icon: Icon(Icons.add, color: theme.colorScheme.onPrimary),
                  ),
                  IconButton(
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                            Colors.redAccent)),
                    onPressed: () =>
                    {
                      appState.subtractScore(player.id)
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
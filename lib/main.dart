import 'dart:async';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'model/game.dart';
import 'model/player.dart';

import 'profile_screen.dart';

import 'database/firestore.dart';

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
        title: 'Toepen',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B4D3E),
            brightness: Brightness.light,
          ),
          cardTheme: CardTheme(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textTheme: const TextTheme(
            displayMedium: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
          ),
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

  MyAppState() {
    saveGameToDatabase(currentGame);
  }

  void saveGameToDatabase(Game game) {
    FireStore().addGame(currentGame);
  }

  void createGame() {
    currentGame = Game(players: []);
    notifyListeners();
  }

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
    currentGame.checkWinner();
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
          icon: const Icon(Icons.account_circle),
          tooltip: 'Profiel',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
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
            icon: const Icon(Icons.add_box),
            tooltip: 'Create new game',
            onPressed: () => showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Nieuw spel starten'),
                  content: const Text('Weet je zeker dat je een nieuw spel wilt starten?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuleren'),
                    ),
                    TextButton(
                      onPressed: () {
                        appState.createGame();
                        appState.saveGameToDatabase(appState.currentGame);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nieuw spel gestart!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('Starten'),
                    ),
                  ],
                );
              },
            ),
          ),


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

    Color cardColor = theme.colorScheme.primary;
    if (player.isDead()) {
      cardColor = theme.colorScheme.error;
    } else if (player.hasPoverty()) {
      cardColor = Colors.amber.shade900;
    }

    final nameStyle = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontSize: 20,
    );

    final scoreStyle = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontSize: 28,
      fontWeight: FontWeight.bold,
    );

    var appState = context.watch<MyAppState>();

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: isEditable || textEditingController.text.isEmpty
                      ? _buildEditMode(context, textEditingController, theme, nameStyle, appState, player)
                      : _buildDisplayMode(context, theme, nameStyle, player),
                ),
                // Status icoontjes
                if (!isEditable && textEditingController.text.isNotEmpty)
                  _buildStatusIcons(player, theme),
              ],
            ),

            if (!isEditable && textEditingController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildScoreButton(
                      icon: Icons.remove,
                      onPressed: () => appState.subtractScore(player.id),
                      theme: theme,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        player.score.toString(),
                        style: scoreStyle,
                      ),
                    ),
                    _buildScoreButton(
                      icon: Icons.add,
                      onPressed: () => appState.addScore(player.id),
                      theme: theme,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcons(Player player, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (player.hasPoverty())
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Tooltip(
              message: 'Armoede',
              child: Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
        if (player.isDead())
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Tooltip(
              message: 'Dood',
              child: Icon(
                Icons.dangerous,  // Als deze niet beschikbaar is, gebruik dan Icons.dangerous
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEditMode(
      BuildContext context,
      TextEditingController controller,
      ThemeData theme,
      TextStyle textStyle,
      MyAppState appState,
      Player player,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          color: theme.colorScheme.onPrimary,
          iconSize: 24,
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          onPressed: () {
            appState.removePlayer(player.id);
            setState(() => isEditable = false);
          },
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            cursorColor: theme.colorScheme.onPrimary,
            textCapitalization: TextCapitalization.words,
            style: textStyle,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        // Cancel knop
        IconButton(
          icon: const Icon(Icons.close),
          color: theme.colorScheme.onPrimary,
          iconSize: 24,
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          onPressed: () {
            controller.text = player.name; // Reset naar originele naam
            setState(() => isEditable = false);
          },
        ),
        // Bevestig knop
        IconButton(
          icon: const Icon(Icons.check),
          color: theme.colorScheme.onPrimary,
          iconSize: 24,
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          onPressed: () {
            if (controller.text.isNotEmpty) {
              appState.updatePlayerName(player.id, controller.text);
              setState(() => isEditable = false);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDisplayMode(
      BuildContext context,
      ThemeData theme,
      TextStyle nameStyle,
      Player player,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          color: theme.colorScheme.onPrimary,
          iconSize: 24,
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          onPressed: () => setState(() => isEditable = true),
        ),
        Expanded(
          child: Text(
            player.name,
            style: nameStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onPrimary,
            size: 26,
          ),
        ),
      ),
    );
  }
}

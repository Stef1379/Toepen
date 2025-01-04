import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player.dart';

void main() {
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
        home: const MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var players = [Player("Ben"), Player("Gijs"), Player("Rowan"), Player("Stijn"), Player("Stef")];

  void addScore(player) {
    if (players.contains(player)) {
      player.score++;
    }
    notifyListeners();
  }

  void subtractScore(player) {
    if (players.contains(player)) {
      player.score--;
    }
    notifyListeners();
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var players = appState.players;

    return Scaffold(
      body: ListView(
        children: [
          for (var player in players)
            PlayerCard (
              player: player,
            )
        ],
      ),
    );
  }
}

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
      fontSize: 30
    );
    final armoedeStyle = theme.textTheme.displayMedium!.copyWith(
      color: Colors.yellow
    );

    var appState = context.watch<MyAppState>();

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Text(player.name, style: player.score < 14 ? style : armoedeStyle),
            const Spacer(flex: 10),
            Text('Score: ${player.score}', style: style),
            const Spacer(flex: 1),
            Row(
              children: [
                IconButton(
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red)),
                  onPressed: () => {
                    appState.addScore(player)
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
                IconButton(
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.red)),
                  onPressed: () => {
                    appState.subtractScore(player)
                  },
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
              ],
            )
          ],
        ),
      )
    );
  }
}
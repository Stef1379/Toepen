import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toepen_cardgame/model/player.dart';
import 'package:toepen_cardgame/profile_screen.dart';
import 'package:toepen_cardgame/firebase_options.dart';
import 'package:toepen_cardgame/auth/auth_service.dart';
import 'package:toepen_cardgame/auth/login_screen.dart';
import 'package:toepen_cardgame/ads/load_banner_ad.dart';
import 'package:toepen_cardgame/app_state.dart';


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
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
          Locale('nl'),
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B4D3E),
            brightness: Brightness.light,
          ),
          cardTheme: CardTheme(
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    List<Player>? players = appState.currentGame.players;
    final theme = Theme.of(context);

    void navigateToProfile(BuildContext context) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        backgroundColor: theme.colorScheme.primary,
        leading: Center(
          child: Hero(
            tag: AppLocalizations.of(context)!.profile,
            child: Material(
              type: MaterialType.transparency,
              child: IconButton(
                icon: Icon(
                  Icons.account_circle,
                  color: theme.colorScheme.onPrimary,
                  size: 28,
                ),
                tooltip: AppLocalizations.of(context)!.profile,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                onPressed: () {
                  navigateToProfile(context);
                },
              ),
            ),
          ),
        ),
        title: StreamBuilder<User?>(
          stream: AuthService().userChanges,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              final user = snapshot.data!;
              if (user.displayName != null) {
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.appTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            user.displayName!,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                              fontWeight: FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${appState.currentGame.players?.length ?? 0}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const _LoadingIndicator();
            }
            return Text(
              AppLocalizations.of(context)!.appTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        actions: [
          _ActionButton(
            icon: Icons.add_box_rounded,
            tooltip: AppLocalizations.of(context)!.newGame,
            onPressed: () =>  players == null || players.isEmpty ? null : _showNewGameDialog(context),
          ),
          _ActionButton(
            icon: Icons.person_add_rounded,
            tooltip: AppLocalizations.of(context)!.addPlayer,
            onPressed: () {
              appState.addPlayer("");
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const MyHomePage(),
    );
  }

  Future<void> _showNewGameDialog(BuildContext context) async {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: theme.colorScheme.surfaceTint,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              Icon(
                Icons.warning_rounded,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.startNewGame,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context)!.newGameWarning,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.cancel,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Provider.of<MyAppState>(context, listen: false).createGame();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      AppLocalizations.of(context)!.newGame,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(
          icon,
          color: theme.colorScheme.onPrimary,
        ),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

class TooltipArrowPainter extends CustomPainter {
  final Color color;

  TooltipArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = color;
    paint.style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var players = appState.currentGame.players ?? [];
    final theme = Theme.of(context);

    return Scaffold(
      bottomNavigationBar: MyBannerAdWidget(adSize: AdSize.banner),
      body: players.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add_rounded,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.noPlayersYet,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.clickToAddPlayers,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  appState.addPlayer("");
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Tooltip arrow
                      Positioned(
                        top: -10,
                        left: 24,
                        child: CustomPaint(
                          size: const Size(20, 10),
                          painter: TooltipArrowPainter(color: theme.colorScheme.surface),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_add_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.clickHereToAddPlayers,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : ListView(
        children: [
          for (var player in players)
            PlayerCard(
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
                // Status icons
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
              message: AppLocalizations.of(context)!.poverty,
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
              message: AppLocalizations.of(context)!.dead,
              child: Icon(
                Icons.dangerous,
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
          tooltip: AppLocalizations.of(context)!.delete,
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
        IconButton(
          icon: const Icon(Icons.close),
          tooltip: AppLocalizations.of(context)!.cancel,
          color: theme.colorScheme.onPrimary,
          iconSize: 24,
          constraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 44,
          ),
          onPressed: () {
            controller.text = player.name;
            setState(() => isEditable = false);
          },
        ),
        IconButton(
          icon: const Icon(Icons.check),
          tooltip: AppLocalizations.of(context)!.confirm,
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
          tooltip: AppLocalizations.of(context)!.edit,
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

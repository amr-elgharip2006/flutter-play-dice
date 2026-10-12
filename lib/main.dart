import 'dart:math';

import 'package:flutter/material.dart';

const Color seedColor = Colors.deepPurple;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.random});

  final Random? random;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      themeMode = themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  ThemeData buildTheme(Brightness brightness) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Play Dice',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      home: PlayDice(random: widget.random, onToggleTheme: toggleTheme),
    );
  }
}

class PlayDice extends StatefulWidget {
  const PlayDice({super.key, this.random, this.onToggleTheme});

  final Random? random;
  final VoidCallback? onToggleTheme;

  @override
  State<PlayDice> createState() => _PlayDiceState();
}

class _PlayDiceState extends State<PlayDice> {
  int value1 = 1;
  int value2 = 1;
  int rollCount = 0;

  late final Random random = widget.random ?? Random();

  int get total => value1 + value2;

  // the start (1, 1) and reset don't count as doubles
  bool get isDoubles => rollCount > 0 && value1 == value2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // load all faces once so the dice don't blink on the first roll (web)
    for (var face = 1; face <= 6; face++) {
      precacheImage(AssetImage('assets/images/dice$face.png'), context);
    }
  }

  void roll() {
    setState(() {
      value1 = random.nextInt(6) + 1;
      value2 = random.nextInt(6) + 1;
      rollCount++;
    });
  }

  void reset() {
    setState(() {
      value1 = 1;
      value2 = 1;
      rollCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Dice'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              onPressed: widget.onToggleTheme,
              tooltip: isDark
                  ? 'Switch to light theme'
                  : 'Switch to dark theme',
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Total: $total',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text('Rolls: $rollCount', style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DieFace(value: value1),
                  const SizedBox(width: 16),
                  DieFace(value: value2),
                ],
              ),
              // fixed height so the buttons don't jump
              SizedBox(
                height: 64,
                child: Center(
                  child: isDoubles
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Doubles!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.tertiary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.celebration,
                              size: 32,
                              color: colorScheme.tertiary,
                            ),
                          ],
                        )
                      : null,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: roll,
                      child: const Text('Roll', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: reset,
                      child: const Text(
                        'Reset',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DieFace extends StatelessWidget {
  const DieFace({super.key, required this.value, this.size = 120});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/dice$value.png',
          width: size,
          height: size,
          gaplessPlayback: true,
          semanticLabel: 'Die showing $value',
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Exercise 7: roll() without setState
//
// void roll() {
//   value1 = random.nextInt(6) + 1;
//   value2 = random.nextInt(6) + 1;
//   rollCount++;
//   print('$value1 + $value2');
// }
//
// the values change (you can see them in the console) but the screen
// stays the same, because build() is only called again after setState.

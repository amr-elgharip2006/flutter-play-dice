import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:play_dice/main.dart';

// returns fixed values so the dice are known in the test
class FakeRandom implements Random {
  FakeRandom(this.values);

  final List<int> values;
  int _index = 0;

  @override
  int nextInt(int max) => values[_index++ % values.length];

  @override
  double nextDouble() => throw UnimplementedError();

  @override
  bool nextBool() => throw UnimplementedError();
}

List<String> diceAssets(WidgetTester tester) {
  return tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => (image.image as AssetImage).assetName)
      .toList();
}

int totalOnScreen(WidgetTester tester) {
  final text = tester.widget<Text>(find.textContaining('Total: ')).data!;
  return int.parse(text.substring('Total: '.length));
}

void main() {
  testWidgets('starts with total 2, two dice images and 0 rolls', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Total: 2'), findsOneWidget);
    expect(find.text('Rolls: 0'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    expect(diceAssets(tester), [
      'assets/images/dice1.png',
      'assets/images/dice1.png',
    ]);
    expect(find.text('Doubles!'), findsNothing);
  });

  testWidgets('Roll increments the counter and total stays in 2..12', (
    tester,
  ) async {
    await tester.pumpWidget(MyApp(random: Random(42)));

    for (var i = 1; i <= 20; i++) {
      await tester.tap(find.text('Roll'));
      await tester.pump();

      expect(find.text('Rolls: $i'), findsOneWidget);
      expect(totalOnScreen(tester), inInclusiveRange(2, 12));
      expect(find.byType(Image), findsNWidgets(2));
    }
  });

  testWidgets('Reset sets total back to 2 and the counter to 0', (
    tester,
  ) async {
    // Dice will show 4 and 6 -> total 10.
    await tester.pumpWidget(MyApp(random: FakeRandom([3, 5])));

    await tester.tap(find.text('Roll'));
    await tester.pump();
    expect(find.text('Total: 10'), findsOneWidget);
    expect(find.text('Rolls: 1'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('Total: 2'), findsOneWidget);
    expect(find.text('Rolls: 0'), findsOneWidget);
    expect(diceAssets(tester), [
      'assets/images/dice1.png',
      'assets/images/dice1.png',
    ]);
  });

  testWidgets('shows the doubles message only when both dice match', (
    tester,
  ) async {
    // First roll: 4 and 4 (doubles). Second roll: 1 and 5.
    await tester.pumpWidget(MyApp(random: FakeRandom([3, 3, 0, 4])));

    await tester.tap(find.text('Roll'));
    await tester.pump();
    expect(find.text('Total: 8'), findsOneWidget);
    expect(diceAssets(tester), [
      'assets/images/dice4.png',
      'assets/images/dice4.png',
    ]);
    expect(find.text('Doubles!'), findsOneWidget);
    expect(find.byIcon(Icons.celebration), findsOneWidget);

    await tester.tap(find.text('Roll'));
    await tester.pump();
    expect(find.text('Total: 6'), findsOneWidget);
    expect(find.text('Doubles!'), findsNothing);

    // Reset goes back to 1 + 1, which is not announced as doubles.
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('Doubles!'), findsNothing);
  });

  testWidgets('theme button switches between light and dark', (tester) async {
    await tester.pumpWidget(const MyApp());

    Brightness brightness() =>
        Theme.of(tester.element(find.text('Roll'))).brightness;

    expect(brightness(), Brightness.light);

    await tester.tap(find.byTooltip('Switch to dark theme'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);

    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
  });
}

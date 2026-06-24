// App Store screenshot capture (iPhone 6.9"). Renders the REAL game screen with
// a deterministically-seeded controller so every shot shows the app in use
// (fixes Guideline 2.3.3). Driven from CI via `flutter drive` against the driver
// in test_driver/integration_test.dart, which writes the PNGs to disk.
//
// The controller starts a Ticker on construction; under the live integration
// binding that advances in real time, so we (a) set engine.speed = 0 to FREEZE
// the falling tiles at a clean frame, and (b) after each capture replace the
// tree with an empty widget and dispose the controller, which stops the ticker
// BEFORE teardown (otherwise the running animation fails the test). We use
// pump(Duration), never pumpAndSettle (the ticker + animations never settle).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pusaka_tiles/core/theme.dart';
import 'package:pusaka_tiles/game/game_mode.dart';
import 'package:pusaka_tiles/game/songs.dart';
import 'package:pusaka_tiles/services/ads/ads_service.dart';
import 'package:pusaka_tiles/services/audio/audio_service.dart';
import 'package:pusaka_tiles/services/storage/prefs.dart';
import 'package:pusaka_tiles/state/app_state.dart';
import 'package:pusaka_tiles/state/game_controller.dart';
import 'package:pusaka_tiles/features/game/game_screen.dart';

const _perTest = Timeout(Duration(seconds: 120));

Future<AppState> _makeApp() async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'pt_first_run': false,
    'pt_coins': 1320,
    'pt_sound': false, // keep CI quiet
    'pt_music': false,
  });
  final prefs = await Prefs.create();
  return AppState(prefs, StubAdsService(), AudioService());
}

Widget _wrap(AppState app, TilesGameController gc) => MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: app),
        ChangeNotifierProvider<TilesGameController>.value(value: gc),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const TilesGameScreen(),
      ),
    );

/// Build a frozen, seeded gameplay controller for [songIndex].
TilesGameController _seed(
  AppState app,
  int songIndex, {
  required int points,
  required int combo,
  double fever = 0,
  int flashLane = -1,
}) {
  final gc = TilesGameController(app, SongCatalog.all[songIndex], mode: GameMode.klasik);
  gc.engine.speed = 0; // freeze the falling tiles for a clean capture
  gc.points = points;
  gc.combo = combo;
  gc.bestCombo = combo;
  gc.feverMeter = fever > 0 ? 0.65 : 0.3;
  gc.feverTimeLeft = fever;
  gc.flashLane = flashLane;
  gc.flashT = flashLane >= 0 ? 0.9 : 0;
  return gc;
}

Future<void> _capture(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  AppState app,
  TilesGameController gc,
  String name,
) async {
  await tester.pumpWidget(_wrap(app, gc));
  await tester.pump(const Duration(milliseconds: 350));
  await binding.convertFlutterSurfaceToImage();
  await tester.pump(const Duration(milliseconds: 16));
  await binding.takeScreenshot(name);
  // Tear the screen down, then stop the controller's ticker before teardown.
  await tester.pumpWidget(const SizedBox.shrink());
  gc.dispose();
  // Dispose audio too: audioplayers registers a FramePositionUpdater frame
  // callback that otherwise survives teardown ("animation still running").
  app.audio.dispose();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tiles_01_play', (tester) async {
    final app = await _makeApp();
    final gc = _seed(app, 0, points: 1850, combo: 12, flashLane: 1);
    await _capture(tester, binding, app, gc, 'tiles_01_play');
  }, timeout: _perTest);

  testWidgets('tiles_02_fever', (tester) async {
    final app = await _makeApp();
    final gc = _seed(app, 12, points: 4200, combo: 28, fever: 9, flashLane: 2);
    await _capture(tester, binding, app, gc, 'tiles_02_fever');
  }, timeout: _perTest);

  testWidgets('tiles_03_play', (tester) async {
    final app = await _makeApp();
    final gc = _seed(app, 6, points: 3100, combo: 18, flashLane: 3);
    await _capture(tester, binding, app, gc, 'tiles_03_play');
  }, timeout: _perTest);
}

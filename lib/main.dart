import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'services/ads/ads_service.dart';
import 'services/ads/google_mobile_ads_service.dart';
import 'services/audio/audio_service.dart';
import 'services/storage/prefs.dart';
import 'state/app_state.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  if (K.adsEnabled) {
    MobileAds.instance.initialize();
  }

  final prefs = await Prefs.create();
  final AdsService ads = K.adsEnabled ? GoogleMobileAdsService() : StubAdsService();
  final audio = AudioService();
  final appState = AppState(prefs, ads, audio);

  runApp(PusakaTilesApp(appState: appState));
}

class PusakaTilesApp extends StatelessWidget {
  final AppState appState;
  const PusakaTilesApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        title: 'Pusaka Tiles',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}

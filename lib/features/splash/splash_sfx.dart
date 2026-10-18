import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Splash SFX — real OS keyboard click for typing; assets for swish/pop.
class SplashSfx {
  SplashSfx();

  static const _channel = MethodChannel('gotchu/sfx');

  AudioPlayer? _swish;
  AudioPlayer? _pop;
  bool _ready = false;
  bool _failed = false;

  Future<void> init() async {
    if (_ready || _failed) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );

      _swish = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      _pop = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
      await _swish!.setVolume(0.75);
      await _pop!.setVolume(0.6);
      await AudioCache.instance.loadAll([
        'sounds/swish.wav',
        'sounds/logo_pop.wav',
      ]);
      _ready = true;
    } on MissingPluginException catch (e) {
      // Swish/pop may fail on hot restart; key clicks still work via channel
      // after a full rebuild that includes the MethodChannel.
      _failed = true;
      debugPrint('SplashSfx asset init: $e');
    } catch (e) {
      _failed = true;
      debugPrint('SplashSfx init failed: $e');
    }
  }

  /// Real platform keyboard click (iOS 1104 / Android FX_KEYPRESS_STANDARD).
  Future<void> typeKey(String ch) async {
    try {
      await _channel.invokeMethod<void>('keyClick');
    } catch (e) {
      debugPrint('keyClick: $e');
    }
  }

  Future<void> swish() async {
    final p = _swish;
    if (!_ready || p == null) return;
    try {
      await p.stop();
      await p.play(AssetSource('sounds/swish.wav'));
    } catch (e) {
      debugPrint('swish sfx: $e');
    }
  }

  Future<void> logoPop() async {
    final p = _pop;
    if (!_ready || p == null) return;
    try {
      await p.stop();
      await p.play(AssetSource('sounds/logo_pop.wav'));
    } catch (e) {
      debugPrint('pop sfx: $e');
    }
  }

  Future<void> dispose() async {
    await _swish?.dispose();
    await _pop?.dispose();
    _swish = null;
    _pop = null;
  }
}

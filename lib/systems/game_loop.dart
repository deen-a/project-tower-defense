import 'dart:async';
import '../core/game_state.dart';

class GameLoop {
  final GameState gameState;
  Timer? _timer;
  int _frameCount = 0;
  double _accumulatedTime = 0;
  final double _fixedDeltaTime = 1 / 60; // 60 FPS
  
  GameLoop(this.gameState);
  
  void start() {
    if (_timer != null) return;
    
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _update();
    });
  }
  
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
  
  void _update() {
    _frameCount++;
    _accumulatedTime += _fixedDeltaTime;
    
    // Fixed timestep update
    gameState.update(_fixedDeltaTime);
    
    // Optional: Update at variable rate if needed
    // gameState.update(_accumulatedTime);
    // _accumulatedTime = 0;
  }
  
  int get frameCount => _frameCount;
  
  bool get isRunning => _timer != null;
  
  void dispose() {
    stop();
  }
}
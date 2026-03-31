enum GameMode {
  campaign,    // Fixed waves dengan boss di akhir
  endless,     // Loop terus, setelah boss map berubah
  challenge    // Special rules/constraints
}

class GameModeManager {
  GameMode currentMode = GameMode.campaign;
  int endlessCycles = 0;
  MapData? currentEndlessMap;
  
  void switchToEndlessMode() {
    currentMode = GameMode.endless;
    endlessCycles = 0;
    generateNewEndlessMap();
  }
  
  void generateNewEndlessMap() {
    endlessCycles++;
    currentEndlessMap = MapGenerator.generateRandomMap(
      environment: _getEnvironmentForCycle(endlessCycles),
      hasFlyingObstacles: true,
    );
  }
  
  String _getEnvironmentForCycle(int cycle) {
    final environments = ['forest', 'desert', 'winter', 'volcano', 'void'];
    return environments[cycle % environments.length];
  }
  
  bool shouldChangeMapAfterBoss() {
    return currentMode == GameMode.endless;
  }
}
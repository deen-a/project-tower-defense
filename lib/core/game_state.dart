import 'package:flutter/material.dart';

class GameConstants {
  static const int debugCoins = 2000000;
  static const int playerStartHealth = 100;
  
  // Tower types
  static const String towerBasic = "basic";
  static const String towerBurst = "burst"; 
  static const String towerRailgun = "railgun";
  static const String towerFlamethrower = "flamethrower";
}

class GameState {
  int coins = GameConstants.debugCoins;
  int playerHealth = GameConstants.playerStartHealth;
  int currentWave = 0;
  bool isWaveActive = false;
  bool isGameOver = false;
  int skillPoints = 0;
  
  // Observable for state changes
  final ValueNotifier<void> notifier = ValueNotifier(null);
  
  void notifyListeners() => notifier.value = null;
  
  bool spendCoins(int amount) {
    if (coins >= amount) {
      coins -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  void addCoins(int amount) {
    coins += amount;
    notifyListeners();
  }
  
  void takeDamage(int damage) {
    playerHealth -= damage;
    if (playerHealth <= 0) {
      playerHealth = 0;
      isGameOver = true;
    }
    notifyListeners();
  }
  
  bool spendSkillPoints(int amount) {
    if (skillPoints >= amount) {
      skillPoints -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }
  
  void addSkillPoints(int amount) {
    skillPoints += amount;
    notifyListeners();
  }
  
  void onBossDefeated() {
    addSkillPoints(1);
    addCoins(200);
  }
}
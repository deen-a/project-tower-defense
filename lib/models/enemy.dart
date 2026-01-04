import 'dart:math';
import 'package:flutter/material.dart';
import '../core/game_state.dart';
import '../utils/map_generator.dart';
import '../offset_extension.dart';
import 'tower.dart';

abstract class Enemy {
  final String type;
  final int health;
  final double speed;
  final int coinReward;
  final bool isFlying;
  final List<EnemyAbility> abilities;
  
  int currentHealth;
  Offset position;
  double distanceTraveled = 0;
  bool isAlive = true;
  
  Enemy({
    required this.type,
    required this.health,
    required this.speed,
    required this.coinReward,
    required this.isFlying,
    required this.abilities,
    required this.position,
  }) : currentHealth = health;
  
  void update(double dt, MapData mapData) {
    if (isFlying) {
      _updateFlyingMovement(dt, mapData);
    } else {
      _updateGroundMovement(dt, mapData);
    }
    
    // Update abilities
    for (var ability in abilities) {
      ability.update(dt);
    }
  }
  
  void _updateFlyingMovement(double dt, MapData mapData) {
    // Flying enemies take shortest path avoiding flying obstacles
    final target = mapData.path.last;
    final direction = (target - position).normalized();
    final newPosition = position + direction * speed * dt;
    
    // Check for flying obstacles
    bool willCollide = false;
    for (var obstacle in mapData.flyingObstacles) {
      if ((newPosition - obstacle).distance < 1.0) {
        willCollide = true;
        break;
      }
    }
    
    if (!willCollide) {
      position = newPosition;
    } else {
      // Simple obstacle avoidance - move around
      position = position + Offset(direction.dy, -direction.dx) * speed * dt;
    }
    
    distanceTraveled += speed * dt;
  }
  
  void _updateGroundMovement(double dt, MapData mapData) {
    // Ground enemies follow the path
    // Implementation for path following...
  }
  
  void takeDamage(int damage) {
    currentHealth -= damage;
    if (currentHealth <= 0) {
      isAlive = false;
    }
  }
  
  void useAbilities(List<Tower> nearbyTowers) {
    for (var ability in abilities) {
      if (ability.canActivate()) {
        ability.activate(nearbyTowers, this);
      }
    }
  }
}

// Enemy Abilities System
abstract class EnemyAbility {
  final double cooldown;
  final double range;
  double currentCooldown = 0;
  
  EnemyAbility({required this.cooldown, required this.range});
  
  bool canActivate() => currentCooldown <= 0;
  
  void update(double dt) {
    if (currentCooldown > 0) {
      currentCooldown -= dt;
    }
  }
  
  void activate(List<Tower> nearbyTowers, Enemy owner);
  
  List<Tower> getTowersInRange(Offset position, List<Tower> allTowers) {
    return allTowers.where((tower) => 
      (tower.position - position).distance <= range
    ).toList();
  }
}

// Specific Abilities
class StunAbility extends EnemyAbility {
  final double stunDuration;
  
  StunAbility({required super.cooldown, required super.range, required this.stunDuration});
  
  @override
  void activate(List<Tower> nearbyTowers, Enemy owner) {
    final towersInRange = getTowersInRange(owner.position, nearbyTowers);
    
    for (var tower in towersInRange) {
      if (tower.stunable) {
        tower.applyStun(stunDuration);
      }
    }
    
    currentCooldown = cooldown;
  }
}

class LifestealAbility extends EnemyAbility {
  final double lifestealPercent;
  
  LifestealAbility({required super.cooldown, required super.range, required this.lifestealPercent});
  
  @override
  void activate(List<Tower> nearbyTowers, Enemy owner) {
    final towersInRange = getTowersInRange(owner.position, nearbyTowers);
    
    for (var tower in towersInRange) {
      if (tower.currentHealth > 10) {
        final drainAmount = tower.currentHealth * lifestealPercent;
        tower.takeDamage(drainAmount.toInt());
        owner.currentHealth = min(owner.health, owner.currentHealth + drainAmount.toInt());
      }
    }
    
    currentCooldown = cooldown;
  }
}

// Concrete Enemy Classes
class BasicEnemy extends Enemy {
  BasicEnemy(Offset position) : super(
    type: "basic",
    health: 100,
    speed: 1.0,
    coinReward: 10,
    isFlying: false,
    abilities: [],
    position: position,
  );
}

class SpeedyEnemy extends Enemy {
  SpeedyEnemy(Offset position) : super(
    type: "speedy", 
    health: 50,
    speed: 2.0,
    coinReward: 15,
    isFlying: false,
    abilities: [],
    position: position,
  );
}

class TankEnemy extends Enemy {
  TankEnemy(Offset position) : super(
    type: "tank",
    health: 300,
    speed: 0.6,
    coinReward: 25,
    isFlying: false,
    abilities: [],
    position: position,
  );
}

class FlyingEnemy extends Enemy {
  FlyingEnemy(Offset position) : super(
    type: "flying",
    health: 80,
    speed: 1.5,
    coinReward: 20,
    isFlying: true,
    abilities: [],
    position: position,
  );
}

class EliteStunEnemy extends Enemy {
  EliteStunEnemy(Offset position) : super(
    type: "elite_stun",
    health: 150,
    speed: 1.2,
    coinReward: 40,
    isFlying: false,
    abilities: [
      StunAbility(cooldown: 15.0, range: 3.0, stunDuration: 3.0),
    ],
    position: position,
  );
}

class LifestealEnemy extends Enemy {
  LifestealEnemy(Offset position) : super(
    type: "lifesteal",
    health: 120,
    speed: 1.0,
    coinReward: 35,
    isFlying: false,
    abilities: [
      LifestealAbility(cooldown: 10.0, range: 2.5, lifestealPercent: 0.1),
    ],
    position: position,
  );
}

class BossEnemy extends Enemy {
  BossEnemy(Offset position) : super(
    type: "boss",
    health: 1000,
    speed: 0.4,
    coinReward: 100,
    isFlying: false,
    abilities: [
      StunAbility(cooldown: 20.0, range: 4.0, stunDuration: 5.0),
      LifestealAbility(cooldown: 12.0, range: 3.0, lifestealPercent: 0.15),
    ],
    position: position,
  );
}
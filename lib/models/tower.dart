import 'dart:math';
import 'package:flutter/material.dart';
import '../core/game_state.dart';
import '../utils/map_generator.dart';
import '../offset_extension.dart';

abstract class Tower {
  final String type;
  final int cost;
  final int damage;
  final double fireRate; // attacks per second
  final int health;
  final double range;
  final bool stunable;
  final double placementMargin;
  final Offset position;

  int currentHealth;
  double lastFiredTime = 0;
  bool isStunned = false;
  double stunTimer = 0;

  Tower({
    required this.type,
    required this.cost,
    required this.damage,
    required this.fireRate,
    required this.health,
    required this.range,
    required this.stunable,
    required this.placementMargin,
    required this.position,
  }) : currentHealth = health;

  bool canFire(double currentTime) {
    if (isStunned) return false;
    return (currentTime - lastFiredTime) >= (1.0 / fireRate);
  }

  void fire(double currentTime, Enemy target) {
    lastFiredTime = currentTime;
    onFire(target);
  }

  void onFire(Enemy target);
  void update(double dt);

  void takeDamage(int damage) {
    currentHealth -= damage;
    if (currentHealth <= 0) {
      currentHealth = 0;
      // Handle tower destruction
    }
  }

  void applyStun(double duration) {
    if (!stunable) return;
    isStunned = true;
    stunTimer = duration;
  }

  void updateStun(double dt) {
    if (isStunned) {
      stunTimer -= dt;
      if (stunTimer <= 0) {
        isStunned = false;
        stunTimer = 0;
      }
    }
  }
}

class BasicTower extends Tower {
  BasicTower(Offset position)
      : super(
          type: GameConstants.towerBasic,
          cost: 75,
          damage: 15,
          fireRate: 1.0,
          health: 100,
          range: 60,
          stunable: true,
          placementMargin: 10,
          position: position,
        );

  @override
  void onFire(Enemy target) {
    // Create basic projectile
    target.takeDamage(damage);
  }

  @override
  void update(double dt) {
    updateStun(dt);
  }
}

class BurstTower extends Tower {
  BurstTower(Offset position)
      : super(
          type: GameConstants.towerBurst,
          cost: 125,
          damage: 8,
          fireRate: 3.33, // 1/0.3 = 3.33 attacks per second
          health: 100,
          range: 50,
          stunable: true,
          placementMargin: 10,
          position: position,
        );

  @override
  void onFire(Enemy target) {
    target.takeDamage(damage);
  }

  @override
  void update(double dt) {
    updateStun(dt);
  }
}

class RailgunTower extends Tower {
  RailgunTower(Offset position)
      : super(
          type: GameConstants.towerRailgun,
          cost: 225,
          damage: 40,
          fireRate: 0.4, // 1/2.5 = 0.4 attacks per second
          health: 150,
          range: 120,
          stunable: false,
          placementMargin: 12,
          position: position,
        );

  @override
  void onFire(Enemy target) {
    target.takeDamage(damage);
  }

  @override
  void update(double dt) {
    // No stun update needed
  }
}

class FlamethrowerTower extends Tower {
  double heat = 0;
  double overheatCooldown = 2.5;
  double heatLimit = 20;
  double heatIncreaseRate = 0.2;
  double heatDecreaseRate = 0.5;
  bool isOverheated = false;
  double overheatTimer = 0;

  FlamethrowerTower(Offset position)
      : super(
          type: GameConstants.towerFlamethrower,
          cost: 150,
          damage: 5,
          fireRate: 10.0, // 1/0.1 = 10 attacks per second
          health: 120,
          range: 45,
          stunable: true,
          placementMargin: 10,
          position: position,
        );

  @override
  bool canFire(double currentTime) {
    if (isOverheated || isStunned) return false;
    return super.canFire(currentTime);
  }

  @override
  void onFire(Enemy target) {
    heat += heatIncreaseRate;
    if (heat >= heatLimit) {
      isOverheated = true;
      overheatTimer = overheatCooldown;
    }
    target.takeDamage(damage);
  }

  @override
  void update(double dt) {
    updateStun(dt);

    if (isOverheated) {
      overheatTimer -= dt;
      if (overheatTimer <= 0) {
        isOverheated = false;
        heat = 0;
      }
    } else if (heat > 0) {
      heat = max(0, heat - (heatDecreaseRate * dt));
    }
  }
}

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
    return allTowers
        .where((tower) => (tower.position - position).distance <= range)
        .toList();
  }
}

// Specific Abilities
class StunAbility extends EnemyAbility {
  final double stunDuration;

  StunAbility(
      {required super.cooldown,
      required super.range,
      required this.stunDuration});

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

  LifestealAbility(
      {required super.cooldown,
      required super.range,
      required this.lifestealPercent});

  @override
  void activate(List<Tower> nearbyTowers, Enemy owner) {
    final towersInRange = getTowersInRange(owner.position, nearbyTowers);

    for (var tower in towersInRange) {
      if (tower.currentHealth > 10) {
        final drainAmount = tower.currentHealth * lifestealPercent;
        tower.takeDamage(drainAmount.toInt());
        owner.currentHealth =
            min(owner.health, owner.currentHealth + drainAmount.toInt());
      }
    }

    currentCooldown = cooldown;
  }
}

// Concrete Enemy Classes
class BasicEnemy extends Enemy {
  BasicEnemy(Offset position)
      : super(
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
  SpeedyEnemy(Offset position)
      : super(
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
  TankEnemy(Offset position)
      : super(
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
  FlyingEnemy(Offset position)
      : super(
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
  EliteStunEnemy(Offset position)
      : super(
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
  LifestealEnemy(Offset position)
      : super(
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
  BossEnemy(Offset position)
      : super(
          type: "boss",
          health: 1000,
          speed: 0.4,
          coinReward: 100,
          isFlying: false,
          abilities: [
            StunAbility(cooldown: 20.0, range: 4.0, stunDuration: 5.0),
            LifestealAbility(
                cooldown: 12.0, range: 3.0, lifestealPercent: 0.15),
          ],
          position: position,
        );
}

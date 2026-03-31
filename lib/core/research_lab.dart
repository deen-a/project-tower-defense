class ResearchLab {
  final Map<String, TowerResearch> towerResearches = {};
  final Map<String, int> researchedLevels = {};
  
  ResearchLab() {
    _initializeResearches();
  }
  
  void _initializeResearches() {
    // Basic Tower Research
    towerResearches['basic_damage'] = TowerResearch(
      id: 'basic_damage',
      towerType: 'basic',
      name: 'Enhanced Ammo',
      description: 'Increase Basic Tower damage by 20%',
      cost: 100,
      maxLevel: 5,
      stat: 'damage',
      value: 0.2, // 20% increase
    );
    
    towerResearches['basic_range'] = TowerResearch(
      id: 'basic_range', 
      towerType: 'basic',
      name: 'Longer Barrel',
      description: 'Increase Basic Tower range by 10%',
      cost: 150,
      maxLevel: 3,
      stat: 'range',
      value: 0.1,
    );
    
    // Railgun Research
    towerResearches['railgun_penetration'] = TowerResearch(
      id: 'railgun_penetration',
      towerType: 'railgun',
      name: 'Armor Penetration',
      description: 'Railgun shots ignore 50% of enemy armor',
      cost: 300,
      maxLevel: 2,
      stat: 'armor_penetration',
      value: 0.5,
    );
    
    // Global Research
    towerResearches['global_autoheal'] = TowerResearch(
      id: 'global_autoheal',
      towerType: 'global',
      name: 'Advanced Nanobots',
      description: 'Increase all towers auto-heal rate by 25%',
      cost: 400,
      maxLevel: 4,
      stat: 'auto_heal_rate',
      value: 0.25,
    );
    
    towerResearches['global_deflect'] = TowerResearch(
      id: 'global_deflect',
      towerType: 'global', 
      name: 'Reactive Armor',
      description: 'All towers gain 5% chance to deflect damage',
      cost: 500,
      maxLevel: 3,
      stat: 'deflect_chance',
      value: 0.05,
    );
  }
  
  bool canResearch(String researchId, int playerSkillPoints) {
    final research = towerResearches[researchId];
    if (research == null) return false;
    
    final currentLevel = researchedLevels[researchId] ?? 0;
    if (currentLevel >= research.maxLevel) return false;
    
    final researchCost = research.getCostForLevel(currentLevel + 1);
    return playerSkillPoints >= researchCost;
  }
  
  bool research(String researchId, GameState gameState) {
    if (!canResearch(researchId, gameState.skillPoints)) return false;
    
    final research = towerResearches[researchId]!;
    final currentLevel = researchedLevels[researchId] ?? 0;
    final cost = research.getCostForLevel(currentLevel + 1);
    
    if (gameState.spendSkillPoints(cost)) {
      researchedLevels[researchId] = currentLevel + 1;
      return true;
    }
    
    return false;
  }
  
  double getResearchBonus(String researchId) {
    final research = towerResearches[researchId];
    final level = researchedLevels[researchId] ?? 0;
    if (research == null) return 0.0;
    
    return research.value * level;
  }
  
  List<TowerResearch> getAvailableResearches() {
    return towerResearches.values.toList();
  }
}

class TowerResearch {
  final String id;
  final String towerType; // 'global' for all towers
  final String name;
  final String description;
  final int cost;
  final int maxLevel;
  final String stat; // stat to modify
  final double value; // value per level
  
  TowerResearch({
    required this.id,
    required this.towerType,
    required this.name,
    required this.description,
    required this.cost,
    required this.maxLevel,
    required this.stat,
    required this.value,
  });
  
  int getCostForLevel(int level) {
    return (cost * pow(1.5, level - 1)).round();
  }
}
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CncCompanionApp());
}

const _gearCategories = [
  'Armor',
  'Shield',
  'Containers',
  'Weapons',
  'Equipment',
  'Helms',
];

const _alignmentOptions = [
  'Lawful Good',
  'Lawful Neutral',
  'Lawful Evil',
  'Neutral Good',
  'Neutral',
  'Neutral Evil',
  'Chaotic Good',
  'Chaotic Neutral',
  'Chaotic Evil',
];

class SpellReferenceItem {
  const SpellReferenceItem({
    required this.spellName,
    required this.characterClass,
    required this.level,
    required this.castingTime,
    required this.range,
    required this.duration,
    required this.savingThrow,
    required this.spellResistance,
    required this.components,
  });

  final String spellName;
  final String characterClass;
  final String level;
  final String castingTime;
  final String range;
  final String duration;
  final String savingThrow;
  final String spellResistance;
  final String components;

  Map<String, dynamic> toJson() => {
    'spellName': spellName,
    'class': characterClass,
    'level': level,
    'ct': castingTime,
    'r': range,
    'd': duration,
    'sv': savingThrow,
    'sr': spellResistance,
    'comp': components,
  };

  factory SpellReferenceItem.fromJson(Map<String, dynamic> json) =>
      SpellReferenceItem(
        spellName: json['spellName'] as String? ?? '',
        characterClass: json['class'] as String? ?? '',
        level: json['level']?.toString() ?? '',
        castingTime: json['ct'] as String? ?? '',
        range: json['r'] as String? ?? '',
        duration: json['d'] as String? ?? '',
        savingThrow: json['sv'] as String? ?? '',
        spellResistance: json['sr'] as String? ?? '',
        components: json['comp'] as String? ?? '',
      );

  String get selectionKey => jsonEncode([
    characterClass.trim().toLowerCase(),
    level.trim(),
    spellName.trim().toLowerCase(),
  ]);
}

class GearReferenceItem {
  const GearReferenceItem({
    required this.category,
    required this.name,
    this.armorModifier,
    this.shieldAc,
    this.foes,
    this.helmAc,
    this.vs = '',
    this.encumbrance = '',
    this.worn = false,
    this.capacity = '',
    this.attackType = 'Melee',
    this.damage = '',
    this.special = '',
  });

  final String category;
  final String name;
  final int? armorModifier;
  final int? shieldAc;
  final int? foes;
  final int? helmAc;
  final String vs;
  final String encumbrance;
  final bool worn;
  final String capacity;
  final String attackType;
  final String damage;
  final String special;

  Map<String, dynamic> toJson() => {
    'category': category,
    'name': name,
    if (armorModifier != null) 'armorModifier': armorModifier,
    if (category == 'Shield') ...{'shieldAc': shieldAc ?? 0, 'foes': foes ?? 0},
    if (category == 'Helms') ...{'helmAc': helmAc ?? 0, 'vs': vs},
    if (category == 'Equipment' || category == 'Containers') ...{
      'encumbrance': encumbrance,
      'worn': worn,
    },
    if (category == 'Containers') 'capacity': capacity,
    if (category == 'Weapons') ...{
      'attackType': attackType,
      'damage': damage,
      'special': special,
    },
  };

  factory GearReferenceItem.fromJson(Map<String, dynamic> json) =>
      GearReferenceItem(
        category: json['category'] as String,
        name: json['name'] as String,
        armorModifier: (json['armorModifier'] as num?)?.toInt(),
        shieldAc: (json['shieldAc'] as num?)?.toInt(),
        foes: (json['foes'] as num?)?.toInt(),
        helmAc: (json['helmAc'] as num?)?.toInt(),
        vs: json['vs'] as String? ?? '',
        encumbrance: json['encumbrance'] as String? ?? '',
        worn: json['worn'] as bool? ?? false,
        capacity: json['capacity']?.toString() ?? '',
        damage: json['damage'] as String? ?? '',
        special: json['special'] as String? ?? '',
        attackType:
            json['attackType'] as String? ??
            _inferWeaponAttackType(json['name'] as String),
      );
}

String _inferWeaponAttackType(String weaponName) {
  final name = weaponName.toLowerCase();
  return [
        'bow',
        'sling',
        'crossbow',
        'javelin',
        'dart',
        'thrown',
      ].any(name.contains)
      ? 'Ranged'
      : 'Melee';
}

class EquippedGearItem {
  const EquippedGearItem({
    required this.id,
    required this.category,
    required this.name,
    this.baseModifier = 0,
    this.shieldAc = 0,
    this.foes = 0,
    this.helmAc = 0,
    this.vs = '',
    this.encumbrance = '',
    this.worn = false,
    this.capacity = '',
    this.magical = false,
    this.magicModifier = 0,
    this.attackType = 'Melee',
  });

  final String id;
  final String category;
  final String name;
  final int baseModifier;
  final int shieldAc;
  final int foes;
  final int helmAc;
  final String vs;
  final String encumbrance;
  final bool worn;
  final String capacity;
  final bool magical;
  final int magicModifier;
  final String attackType;

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'name': name,
    'baseModifier': baseModifier,
    'shieldAc': shieldAc,
    'foes': foes,
    'helmAc': helmAc,
    'vs': vs,
    'encumbrance': encumbrance,
    'worn': worn,
    'capacity': capacity,
    'magical': magical,
    'magicModifier': magicModifier,
    'attackType': attackType,
  };

  factory EquippedGearItem.fromJson(Map<String, dynamic> json, int index) =>
      EquippedGearItem(
        id: json['id'] as String? ?? 'equipped-gear-$index',
        category: json['category'] as String,
        name: json['name'] as String,
        baseModifier: (json['baseModifier'] as num?)?.toInt() ?? 0,
        shieldAc: (json['shieldAc'] as num?)?.toInt() ?? 0,
        foes: (json['foes'] as num?)?.toInt() ?? 0,
        helmAc: (json['helmAc'] as num?)?.toInt() ?? 0,
        vs: json['vs'] as String? ?? '',
        encumbrance: json['encumbrance'] as String? ?? '',
        worn: json['worn'] as bool? ?? false,
        capacity: json['capacity']?.toString() ?? '',
        magical: json['magical'] as bool? ?? false,
        magicModifier: (json['magicModifier'] as num?)?.toInt() ?? 0,
        attackType:
            json['attackType'] as String? ??
            _inferWeaponAttackType(json['name'] as String),
      );

  EquippedGearItem copyWith({
    int? baseModifier,
    int? shieldAc,
    int? foes,
    int? helmAc,
    String? vs,
    String? encumbrance,
    bool? worn,
    String? capacity,
    bool? magical,
    int? magicModifier,
    String? attackType,
  }) => EquippedGearItem(
    id: id,
    category: category,
    name: name,
    baseModifier: baseModifier ?? this.baseModifier,
    shieldAc: shieldAc ?? this.shieldAc,
    foes: foes ?? this.foes,
    helmAc: helmAc ?? this.helmAc,
    vs: vs ?? this.vs,
    encumbrance: encumbrance ?? this.encumbrance,
    worn: worn ?? this.worn,
    capacity: capacity ?? this.capacity,
    magical: magical ?? this.magical,
    magicModifier: magicModifier ?? this.magicModifier,
    attackType: attackType ?? this.attackType,
  );
}

final _defaultGearItems = <GearReferenceItem>[
  GearReferenceItem(category: 'Armor', name: 'Padded Armor', armorModifier: 1),
  GearReferenceItem(category: 'Armor', name: 'Leather Coat', armorModifier: 1),
  GearReferenceItem(category: 'Armor', name: 'Leather Armor', armorModifier: 2),
  GearReferenceItem(category: 'Armor', name: 'Ring Mail', armorModifier: 3),
  GearReferenceItem(category: 'Armor', name: 'Hide', armorModifier: 3),
  GearReferenceItem(
    category: 'Armor',
    name: 'Studded Leather',
    armorModifier: 3,
  ),
  GearReferenceItem(
    category: 'Armor',
    name: 'Laminar, Leather',
    armorModifier: 3,
  ),
  GearReferenceItem(category: 'Armor', name: 'Mail Shirt', armorModifier: 4),
  GearReferenceItem(category: 'Armor', name: 'Scale Mail', armorModifier: 4),
  GearReferenceItem(category: 'Armor', name: 'Cuir Bouille', armorModifier: 4),
  GearReferenceItem(
    category: 'Armor',
    name: 'Breastplate, Bronze',
    armorModifier: 4,
  ),
  GearReferenceItem(category: 'Armor', name: 'Brigandine', armorModifier: 4),
  GearReferenceItem(
    category: 'Armor',
    name: 'Breastplate, Steel',
    armorModifier: 5,
  ),
  GearReferenceItem(category: 'Armor', name: 'Mail Hauberk', armorModifier: 5),
  GearReferenceItem(
    category: 'Armor',
    name: 'Coat of Plates',
    armorModifier: 5,
  ),
  GearReferenceItem(
    category: 'Armor',
    name: 'Light Ensemble, Greek',
    armorModifier: 5,
  ),
  GearReferenceItem(category: 'Armor', name: 'Banded Mail', armorModifier: 6),
  GearReferenceItem(category: 'Armor', name: 'Splint Mail', armorModifier: 6),
  GearReferenceItem(
    category: 'Armor',
    name: 'Heavy Ensemble, Greek',
    armorModifier: 6,
  ),
  GearReferenceItem(
    category: 'Armor',
    name: 'Light Ensemble, Roman',
    armorModifier: 6,
  ),
  GearReferenceItem(
    category: 'Armor',
    name: 'Full Chain Suit',
    armorModifier: 6,
  ),
  GearReferenceItem(category: 'Armor', name: 'Plate Mail', armorModifier: 7),
  GearReferenceItem(
    category: 'Armor',
    name: 'Heavy Ensemble, Roman',
    armorModifier: 7,
  ),
  GearReferenceItem(category: 'Armor', name: 'Full Plate', armorModifier: 8),
  GearReferenceItem(category: 'Armor', name: 'Polish Hussar', armorModifier: 8),
  ..._defaultShields,
  ..._defaultHelms,
  ..._defaultEquipment,
  ..._defaultContainers,
  ..._defaultWeapons,
];

const _defaultShields = [
  GearReferenceItem(category: 'Shield', name: 'Buckler', shieldAc: 1, foes: 1),
  GearReferenceItem(
    category: 'Shield',
    name: 'Shield, Small Steel',
    shieldAc: 1,
    foes: 1,
  ),
  GearReferenceItem(
    category: 'Shield',
    name: 'Shield, Small Wooden',
    shieldAc: 1,
    foes: 1,
  ),
  GearReferenceItem(
    category: 'Shield',
    name: 'Shield, Medium Steel',
    shieldAc: 1,
    foes: 2,
  ),
  GearReferenceItem(
    category: 'Shield',
    name: 'Shield, Medium Wooden',
    shieldAc: 1,
    foes: 2,
  ),
  GearReferenceItem(
    category: 'Shield',
    name: 'Shield, Large Steel',
    shieldAc: 1,
    foes: 3,
  ),
  GearReferenceItem(
    category: 'Shield',
    name: 'Shield, Large Wooden',
    shieldAc: 1,
    foes: 3,
  ),
];

const _defaultHelms = [
  GearReferenceItem(
    category: 'Helms',
    name: 'Armet',
    helmAc: 6,
    vs: 'Head only',
  ),
  GearReferenceItem(
    category: 'Helms',
    name: 'Bacient',
    helmAc: 4,
    vs: 'Head only',
  ),
  GearReferenceItem(
    category: 'Helms',
    name: 'Benin',
    helmAc: 2,
    vs: 'Head only',
  ),
  GearReferenceItem(
    category: 'Helms',
    name: 'Casquetel',
    helmAc: 2,
    vs: 'Head only',
  ),
  GearReferenceItem(
    category: 'Helms',
    name: 'Coif, Chain',
    helmAc: 4,
    vs: 'Head only',
  ),
  GearReferenceItem(
    category: 'Helms',
    name: 'Coin, Leather',
    helmAc: 1,
    vs: 'Head only',
  ),
  GearReferenceItem(
    category: 'Helms',
    name: 'Helm, Great',
    helmAc: 7,
    vs: 'Head only',
  ),
  GearReferenceItem(
    category: 'Helms',
    name: 'Helm, Normal',
    helmAc: 5,
    vs: 'Head only',
  ),
  GearReferenceItem(
    category: 'Helms',
    name: 'Helm, Norman',
    helmAc: 3,
    vs: 'Head only',
  ),
  GearReferenceItem(
    category: 'Helms',
    name: 'Helm, Pot',
    helmAc: 2,
    vs: 'Head only',
  ),
  GearReferenceItem(
    category: 'Helms',
    name: 'War Hat',
    helmAc: 2,
    vs: 'Head only',
  ),
];

const _equipmentCatalog = '''
Armor & Weapon oil|1|
Awl|1|
Backpack|2|W
Bagpipe|4|
Bandages (2 wounds)|| 
Barrel, Large|9|
Barrel, Small|6|
Basket|2|
Bedroll|3|
Belt Pouch, Large|1|W
Belt Pouch, Small|0|W
Blanket, Winter|2|
Bottle|1|
Broom|3|
Bucket|2|
Candle (5 Sticks)|1|
Canteen|1|
Case, Map or Scroll|1|
Casket|4|
Chain (20ft)|12|
Chalk (per piece)|1|
Chest, Large|12|
Chest, Small|4|
Chisel|1|
Cord (50ft)|2|
Crowbar|2|
Diggery-do||
Drum|5|
Dust, Bag of|1|
Fife|1|
File|1|
File, Metal|1|
Firewood (per day)|8|
Fishing Gear|2|
Flask|1|
Flint and Steel||
Flute|1|
Gong|3|
Gord|1|
Grappling Hook|2|
Grease, Crock|1|
Hammer|2|
Hammer, Sledge|4|
Hammock|4|
Harp|4|
Holy Symbol|1|
Holy Water, flask|1|
Hook, Iron|1|
Horn|2|
Incense, stick||
Ink||
Kettle, Iron|3|
Lamp, Open|2|
Latern, Bullseye|2|
Latern, hooded|2|
Lodestone|1|
Manacles|1|
Mandolin|2|
Marbles (Bag of 25)||
Mirror, small steel|1|
Mortar and Pestle|2|
Mug/Tankard||
Nails, Iron (50)|1|
Oil, Flask|1|
Pack, Shoulder|3|W
Padlock and Key|1|
Panpipes|1|
Paper (10 sheets)||
Parchment (10 sheets)||
Pickaxe, Miner's|4|
Pipe||
Pitons/spikes (5)|1|
Pole (10ft)|5|
Pot|4|
Prayer Beads||
Quill||
Quiver, Dozen|2|
Quiver, Score|2|
Razor|1|
Rogue's Tools|1|
Rope, Hemp (50ft)|3|
Rope, Silk (50ft)|2|
Sack, Large|2|
Sack, Small|1|
Saw, metal|2|
Sealing Wax||
Sewing Kit|1|
Shovel|3|
Soap (per bar)|1|
String (50ft)|2|
Tent, Large|10|
Tent, Medium|7|
Tent, small|4|
Tinder Box (10 Firese)|2|
Tongs|1|
Torch|1|
Trap, Lg. Animal|9|
Trap, Med Animal|6|
Trap, Sml Animal|3|
Trunk, Travel|3|
Vial (1 ounce)|0|
Waterskin (1 Gallon)|3|
Vellum (10 Sheets)||
Wedge, splitting||
Whetstone|1|
Whistle||
Wolvesbane||
Zither|3|
Cheese, Block|1|
Grains, bag|3|
Liquor, Cask|5|
Rations (1 day)|1|
Rations (week)|4|
Wine, Common|1|
Wine, Fine|1
''';

final _defaultEquipment = [
  for (final row in _equipmentCatalog.trim().split('\n'))
    _equipmentFromCatalogRow(row),
];

GearReferenceItem _equipmentFromCatalogRow(String row) {
  final fields = row.split('|');
  if (fields.length < 2 || fields.length > 3) {
    throw FormatException('Invalid default equipment reference row: $row');
  }
  return GearReferenceItem(
    category: 'Equipment',
    name: fields[0],
    encumbrance: fields[1].trim(),
    worn: fields.length == 3 && fields[2].trim() == 'W',
  );
}

const _containerCatalog = '''
Backpack|2|W|8
Barrel, Large|9||9
Barrel, Small|6||6
Basket|2||2
Belt Pouch, Large|1|W|2
Belt Pouch, Small|0|W|1
Bottle|1||1
Bucket|2||3
Canteen|1||0.5
Case, Map or Scroll|1||10
Casket|4||6
Chest, Large|12||8
Chest, Small|4||6
Quiver, Dozen|2||10
Quiver, Score|2||20
Trunk, Travel|3||5
Vial (1 ounce)|0||1
Waterskin (1 Gallon)|3||1
Sack, Large|2||10
Sack, Small|1||6
Pack, Shoulder|3|W|10
''';

final _defaultContainers = [
  for (final row in _containerCatalog.trim().split('\n'))
    _containerFromCatalogRow(row),
];

GearReferenceItem _containerFromCatalogRow(String row) {
  final fields = row.split('|');
  if (fields.length != 4) {
    throw FormatException('Invalid default container reference row: $row');
  }
  return GearReferenceItem(
    category: 'Containers',
    name: fields[0],
    encumbrance: fields[1],
    worn: fields[2] == 'W',
    capacity: fields[3],
  );
}

const _weaponCatalog = '''
Axe, Battle|1d8||M
Axe, Bearded|3d4|Two-Handed|M
Axe, Hand/Throwing (Melee)|1d6||M
Axe, Hand/Throwing (Ranged)|1d6|10 ft.|R
Axe, Piercing|1d8+1||M
Axe, Two-Handed|1d12|Two-Handed|M
Bardiche|2d4|Two-Handed|M
Bec De Corbin|1d10|+2 vs. chain, plate or scale armors, Two Handed|M
Bill or Billhook|2d4|Two-Handed|M
Brass Knuckles|1d3||M
Cat-O-Nine-Tails|1d3||M
Cestus|+1 damage||M
Cleaver|1d4||M
Club (Melee)|1d6||M
Club (Ranged)|1d6|10 ft.|R
Crowbill|1d6|Two-Handed|M
Dagger|1d4||M
Dirk|1d4+1||M
Fauchard|1d6|Two-Handed|M
Fauchard Fork|1d8|Two-Handed|M
Fist|1d2|Subdual Damage|M
Flail, Heavy|1d10|Two-Handed|M
Flail, Light|1d8||M
Flamberge|2d4+2|Two-Handed|M
Flatchet|1d6+1||M
Fork, Military|1d8|Two-Handed|M
Gauntlet, Spiked|1d3||M
Glaive|1d8|Two-Handed|M
Glaive Guisarme|2d4|Two-Handed|M
Godentag|1d6+3|Two-Handed|M
Guisarme|2d4|Two-Handed|M
Halberd|1d10|Two-Handed|M
Hammer, Light (Melee)|1d4||M
Hammer, Light (Ranged)|1d4|20'|R
Hammer, War|1d8||M
Hatchet|1d4||M
Hook Sword|1d4+1|+3 to Disarm or Overbear|M
Hook, Hafted|1d6||M
Katar|1d4+1||M
Knife (Melee)|1d2||M
Knife (Thrown)|1d2|10 ft.|R
Lance, Heavy|1d8|Two-Handed, Double damage on a charging mount|M
Lance, Light|1d6|Two-Handed, Double damage on a charging mount|M
Lucerne Hammer|1d12|Two-Handed|M
Mace, Heavy|1d8||M
Mace, Large|1d10|Double damage on a charging mount|M
Mace, Light|1d6||M
Main Gauche|1d4+1|Use to attack or +1 bonus to AC|M
Man Catcher|1d4|Two-Handed, Trap medium or small opponent|M
Maul|1d10|Two-Handed|M
Morningstar|2d4||M
Nine Ring Broadsword|1d10||M
Partisan|1d8|Two-Handed|M
Pick, Heavy|1d6|Two-Handed|M
Pick, Light|1d4|Two-Handed|M
Pike|1d8|Two-Handed, Double damage vs. a charge|M
Poniard|1d4+1||M
Ranseur|2d4|Two-Handed|M
Sap|1d3|Subdual Damage|M
Scimitar, Great|2d6|Two-Handed|M
Scythe|2d4|Two-Handed|M
Sickle|1d4||M
Sleeve Tangler|1d10|+3 to Disarm|M
Spear (Melee)|1d6|Two-Handed, Double damage on a charging mount|M
Spear (Ranged)|1d6|20 ft.|R
Spear, Long|1d8|Two-Handed, Double damage vs. a charge|M
Spear, Wolf (Melee)|1d8|Two-Handed|M
Spear, Wolf (Ranged)|1d8|Two-Handed, 10 ft.|R
Staff|1d6|Two-Handed|M
Sword, Bastard|1d10||M
Sword, Broad|2d4||M
Sword, Falchion|2d4||M
Sword, Long|1d8||M
Sword, Rapier|1d6||M
Sword, Scimitar|1d6||M
Sword, Short|1d6||M
Sword, Two-Handed|2d6|Two-Handed|M
Trident (Melee)|1d8|Two-Handed|M
Trident (Ranged)|1d8|Two-Handed, 10 ft.|R
Tulwar|1d6||M
Voulge|2d4|Two-Handed|M
Aclis|1d4|20 ft.|R
Blowpipe|1|10 ft.|R
Bolas|1d4|20 ft.|R
Bow, Long|1d6|Two-Handed, 100 ft.|R
Bow, Long, Composite|1d8|Two-Handed, 110 ft.|R
Bow, Short|1d6|Two-Handed, 60 ft.|R
Bow, Short, Composite|1d8|Two-Handed, 70 ft.|R
Crossbow, Light|1d6|Two-Handed, 80 ft.|R
Crossbow, Hand|1d4|30 ft.|R
Crossbow, Heavy|1d10|Two-Handed, 120 ft.|R
Dart|1d3|20 ft.|R
Harpoon|1d6|20 ft.|R
Javelin|1d4|30 ft.|R
Rock|1d2|30 ft.|R
Sling|1d4|50 ft.|R
Whip|1d2|15 ft.|R
''';

final _defaultWeapons = [
  for (final row in _weaponCatalog.trim().split('\n'))
    _weaponFromCatalogRow(row),
];

GearReferenceItem _weaponFromCatalogRow(String row) {
  final fields = row.split('|');
  if (fields.length != 4) {
    throw FormatException('Invalid default weapon reference row: $row');
  }
  return GearReferenceItem(
    category: 'Weapons',
    name: fields[0],
    damage: fields[1],
    special: fields[2],
    attackType: fields[3] == 'R' ? 'Ranged' : 'Melee',
  );
}

const _forest = Color(0xFF25483A);
const _ink = Color(0xFF202720);
const _muted = Color(0xFF777D75);
const _paper = Color(0xFFF5F4EF);
const _gold = Color(0xFFC39148);

class CncCompanionApp extends StatelessWidget {
  const CncCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _forest,
      surface: _paper,
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'C&C Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: _paper,
        appBarTheme: const AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE9E7DF)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8F8F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E4DD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E4DD)),
          ),
        ),
      ),
      home: const CharacterVaultPage(),
    );
  }
}

class CharacterSheet {
  const CharacterSheet({
    required this.id,
    required this.name,
    required this.race,
    required this.characterClass,
    required this.level,
    required this.alignment,
    required this.background,
    required this.armorModifier,
    this.armorName = '',
    required this.currentHp,
    required this.maxHp,
    required this.experience,
    required this.abilities,
    required this.primaryAttributes,
    required this.spells,
    required this.equipment,
    this.equippedGear = const [],
    required this.notes,
    this.characterClasses = const [],
    this.classMode = 'single',
    this.raceLineage = 'Human',
    this.hpLevel = 1,
  });

  final String id;
  final String name;
  final String race;
  final String characterClass;
  final List<String> characterClasses;
  final String classMode;
  final String raceLineage;
  final int level;
  final String alignment;
  final String background;
  final int armorModifier;
  final String armorName;
  final int hpLevel;
  final int currentHp;
  final int maxHp;
  final int experience;
  final Map<String, int> abilities;
  final Set<String> primaryAttributes;
  final List<String> spells;
  final List<String> equipment;
  final List<EquippedGearItem> equippedGear;
  final String notes;

  List<String> get classes {
    final selected = characterClasses.isEmpty
        ? [if (characterClass.trim().isNotEmpty) characterClass]
        : characterClasses;
    final unique = <String>[];
    for (final name in selected) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty && !unique.contains(trimmed)) unique.add(trimmed);
    }
    return unique;
  }

  int? get experienceRequiredForNextLevel =>
      _requiredExperienceForNextLevel(classes, classMode, effectiveLevel);

  int get experiencePerClass => classMode == 'multiclass' && classes.isNotEmpty
      ? experience ~/ classes.length
      : experience;

  int get effectiveLevel =>
      _levelForExperience(classes, classMode, experience) ?? level.clamp(1, 20);

  int levelForClass(String className) {
    final classIndex = classes.indexWhere(
      (name) => name.toLowerCase() == className.toLowerCase(),
    );
    if (classIndex < 0) return effectiveLevel;
    if (classMode == 'classAndHalf' && classIndex == 1) {
      return effectiveLevel ~/ 2;
    }
    return effectiveLevel;
  }

  List<String> get spellcastingClasses => classes
      .where(
        (name) =>
            name.trim().toLowerCase() == 'cleric' ||
            name.trim().toLowerCase() == 'druid' ||
            name.trim().toLowerCase() == 'illusionist' ||
            name.trim().toLowerCase() == 'wizard',
      )
      .toList();

  int get armorModifierForClass {
    final selectedArmor = equippedGear.where(
      (item) => item.category == 'Armor',
    );
    final armor = selectedArmor.isEmpty ? null : selectedArmor.first;
    return armor == null
        ? armorModifier
        : armor.baseModifier + (armor.magical ? armor.magicModifier : 0);
  }

  int get armorClassWithoutShield =>
      10 + armorModifierForClass + statModifierFor('Dexterity');

  EquippedGearItem? get equippedShield {
    for (final item in equippedGear) {
      if (item.category == 'Shield') return item;
    }
    return null;
  }

  int get armorClass {
    final shieldBonus = equippedGear
        .where((item) => item.category == 'Shield')
        .fold<int>(0, (total, item) => total + item.shieldAc);
    return armorClassWithoutShield + shieldBonus;
  }

  int get classBth => _classBthForCharacter(classes, classMode, effectiveLevel);

  int toHitForWeapon(EquippedGearItem weapon) =>
      classBth +
      statModifierFor(
        weapon.attackType == 'Ranged' ? 'Dexterity' : 'Strength',
      ) +
      (weapon.magical ? weapon.magicModifier : 0);

  Map<String, int> get effectiveAbilities => {
    for (final ability in abilityNames)
      ability:
          (abilities[ability] ?? 10) +
          (_raceAttributeModifiers(race, raceLineage)[ability] ?? 0),
  };

  int racialModifierFor(String ability) =>
      _raceAttributeModifiers(race, raceLineage)[ability] ?? 0;

  static const abilityNames = [
    'Strength',
    'Dexterity',
    'Constitution',
    'Intelligence',
    'Wisdom',
    'Charisma',
  ];

  static int maxPrimaryAttributesForRace(String race) =>
      race.trim().toLowerCase() == 'human' ? 3 : 2;

  static Set<String> limitPrimaryAttributes(
    String race,
    Iterable<String> primaryAttributes,
  ) {
    final selected = primaryAttributes.toSet();
    final limited = <String>{};
    for (final ability in abilityNames) {
      if (selected.contains(ability) &&
          limited.length < maxPrimaryAttributesForRace(race)) {
        limited.add(ability);
      }
    }
    return limited;
  }

  int statModifierFor(String ability) =>
      modifierForScore(effectiveAbilities[ability] ?? 10);

  int targetNumberFor(String ability) =>
      primaryAttributes.contains(ability) ? 12 : 18;

  int modifiedTargetFor(String ability) =>
      targetNumberFor(ability) - statModifierFor(ability) - effectiveLevel;

  static int modifierForScore(int score) => switch (score) {
    <= 1 => -4,
    <= 3 => -3,
    <= 5 => -2,
    <= 8 => -1,
    <= 12 => 0,
    <= 15 => 1,
    <= 17 => 2,
    _ => 3,
  };

  CharacterSheet copyWith({
    String? name,
    String? race,
    String? characterClass,
    List<String>? characterClasses,
    String? classMode,
    String? raceLineage,
    int? level,
    String? alignment,
    String? background,
    int? armorModifier,
    String? armorName,
    int? hpLevel,
    int? currentHp,
    int? maxHp,
    int? experience,
    Map<String, int>? abilities,
    Set<String>? primaryAttributes,
    List<String>? spells,
    List<String>? equipment,
    List<EquippedGearItem>? equippedGear,
    String? notes,
  }) {
    final selectedClasses =
        characterClasses ??
        (characterClass == null ? this.characterClasses : [characterClass]);
    final selectedPrimaryClass =
        characterClass ??
        (characterClasses != null && characterClasses.isNotEmpty
            ? characterClasses.first
            : this.characterClass);
    return CharacterSheet(
      id: id,
      name: name ?? this.name,
      race: race ?? this.race,
      characterClass: selectedPrimaryClass,
      characterClasses: selectedClasses,
      classMode: classMode ?? this.classMode,
      raceLineage: raceLineage ?? this.raceLineage,
      level: level ?? this.level,
      alignment: alignment ?? this.alignment,
      background: background ?? this.background,
      armorModifier: armorModifier ?? this.armorModifier,
      armorName: armorName ?? this.armorName,
      hpLevel: hpLevel ?? this.hpLevel,
      currentHp: currentHp ?? this.currentHp,
      maxHp: maxHp ?? this.maxHp,
      experience: experience ?? this.experience,
      abilities: abilities ?? this.abilities,
      primaryAttributes: limitPrimaryAttributes(
        race ?? this.race,
        primaryAttributes ?? this.primaryAttributes,
      ),
      spells: spells ?? this.spells,
      equipment: equipment ?? this.equipment,
      equippedGear: equippedGear ?? this.equippedGear,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'race': race,
    'characterClass': characterClass,
    'classes': classes,
    'classMode': classMode,
    'raceLineage': raceLineage,
    'level': level,
    'alignment': alignment,
    'background': background,
    'armorModifier': armorModifier,
    'armorName': armorName,
    'armorClass': armorClass,
    'hpLevel': hpLevel,
    'currentHp': currentHp,
    'maxHp': maxHp,
    'experience': experience,
    'abilities': abilities,
    'primaryAttributes': primaryAttributes.toList(),
    'spells': spells,
    'equipment': equipment,
    'equippedGear': [for (final item in equippedGear) item.toJson()],
    'notes': notes,
  };

  factory CharacterSheet.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(dynamic value) => (value as Map).map(
      (key, score) => MapEntry(key as String, (score as num).toInt()),
    );

    final primaryClass = json['characterClass'] as String? ?? '';
    final classes = List<String>.from(json['classes'] ?? const []);
    final race = (json['race'] ?? json['ancestry']) as String? ?? '';
    final raceLineage = json['raceLineage'] as String? ?? 'Human';
    final abilities = intMap(json['abilities'] ?? const {});
    final legacyArmorClass = (json['armorClass'] as num?)?.toInt() ?? 10;
    final dexterity =
        (abilities['Dexterity'] ?? 10) +
        (_raceAttributeModifiers(race, raceLineage)['Dexterity'] ?? 0);
    final armorModifier =
        (json['armorModifier'] as num?)?.toInt() ??
        (legacyArmorClass - 10 - CharacterSheet.modifierForScore(dexterity));
    final armorName =
        json['armorName'] as String? ??
        (armorModifier == 0 ? '' : 'Custom armor ($armorModifier)');
    final savedEquippedGear = (json['equippedGear'] as List<dynamic>?)
        ?.asMap()
        .entries
        .map(
          (entry) => EquippedGearItem.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key,
          ),
        )
        .toList();
    final equippedGear =
        savedEquippedGear ??
        (armorName.isEmpty
            ? const <EquippedGearItem>[]
            : [
                EquippedGearItem(
                  id: 'legacy-armor',
                  category: 'Armor',
                  name: armorName,
                  baseModifier: armorModifier,
                ),
              ]);
    return CharacterSheet(
      id: json['id'] as String,
      name: json['name'] as String,
      race: race,
      characterClass: primaryClass.isNotEmpty
          ? primaryClass
          : (classes.isNotEmpty ? classes.first : ''),
      characterClasses: classes,
      classMode: json['classMode'] as String? ?? 'single',
      raceLineage: raceLineage,
      level: (json['level'] as num?)?.toInt() ?? 1,
      alignment: json['alignment'] as String? ?? '',
      background: json['background'] as String? ?? '',
      armorModifier: armorModifier,
      armorName: armorName,
      hpLevel:
          (json['hpLevel'] as num?)?.toInt() ??
          (json['level'] as num?)?.toInt() ??
          1,
      currentHp: (json['currentHp'] as num?)?.toInt() ?? 1,
      maxHp: (json['maxHp'] as num?)?.toInt() ?? 1,
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      abilities: abilities,
      primaryAttributes: limitPrimaryAttributes(
        (json['race'] ?? json['ancestry']) as String? ?? '',
        Set<String>.from(json['primaryAttributes'] ?? const <String>[]),
      ),
      spells: List<String>.from(json['spells'] ?? const []),
      equipment: List<String>.from(json['equipment'] ?? const []),
      equippedGear: equippedGear,
      notes: json['notes'] as String? ?? '',
    );
  }
}

int? _experienceForClassLevel(String className, int level) {
  if (level == 0) return 0;
  final progression = _classProgressions[className.trim().toLowerCase()];
  if (progression == null) return null;
  for (final row in progression) {
    if (row[0] == '$level') {
      return int.tryParse(row[3].replaceAll(',', '')) ??
          (level == 1 && row[3] == '-' ? 0 : null);
    }
  }
  return null;
}

int? _requiredExperienceForNextLevel(
  List<String> classes,
  String classMode,
  int level,
) {
  if (classes.isEmpty || level >= 20) return null;
  return _requiredExperienceForLevel(classes, classMode, level + 1);
}

int? _requiredExperienceForLevel(
  List<String> classes,
  String classMode,
  int targetLevel,
) {
  if (classes.isEmpty || targetLevel < 1 || targetLevel > 20) return null;
  if (classMode == 'classAndHalf') {
    if (classes.length != 2) return null;
    final primaryRequirement = _experienceForClassLevel(
      classes.first,
      targetLevel,
    );
    final halfClassRequirement = _experienceForClassLevel(
      classes[1],
      targetLevel ~/ 2,
    );
    if (primaryRequirement == null || halfClassRequirement == null) return null;
    return primaryRequirement + halfClassRequirement;
  }
  if (classMode == 'multiclass') {
    if (classes.length < 2 || classes.length > 3) return null;
    final requirements = classes
        .map((className) => _experienceForClassLevel(className, targetLevel))
        .toList();
    if (requirements.any((requirement) => requirement == null)) return null;
    return requirements.reduce(
          (first, second) => first! > second! ? first : second,
        )! *
        classes.length;
  }
  if (classes.length != 1) return null;
  return _experienceForClassLevel(classes.single, targetLevel);
}

int? _levelForExperience(
  List<String> classes,
  String classMode,
  int experience,
) {
  if (classes.isEmpty || experience < 0) return null;
  var level = 0;
  for (var candidate = 1; candidate <= 20; candidate++) {
    final required = _requiredExperienceForLevel(classes, classMode, candidate);
    if (required == null) return null;
    if (experience < required) break;
    level = candidate;
  }
  return level == 0 ? 1 : level;
}

String? _hitDieForClassLevel(String className, int level) {
  final progression = _classProgressions[className.trim().toLowerCase()];
  if (progression == null) return null;
  for (final row in progression) {
    if (row[0] == '$level') return row[1];
  }
  return null;
}

int _bthForClassLevel(String className, int level) {
  final progression = _classProgressions[className.trim().toLowerCase()];
  if (progression == null) return 0;
  for (final row in progression) {
    if (row[0] == '$level') return int.tryParse(row[2]) ?? 0;
  }
  return 0;
}

int _classBthForCharacter(List<String> classes, String classMode, int level) {
  if (classes.isEmpty) return 0;
  var highestBth = 0;
  for (var index = 0; index < classes.length; index++) {
    final classLevel = classMode == 'classAndHalf' && index == 1
        ? level ~/ 2
        : level;
    if (classLevel < 1) continue;
    final bth = _bthForClassLevel(classes[index], classLevel);
    if (bth > highestBth) highestBth = bth;
  }
  return highestBth;
}

String? _highestHitDieForLevel(
  List<String> classes,
  int level, {
  String classMode = 'single',
}) {
  final hitDice = <String>[];
  for (var index = 0; index < classes.length; index++) {
    final classLevel = classMode == 'classAndHalf' && index == 1
        ? (level ~/ 2 < 1 ? 1 : level ~/ 2)
        : level;
    final hitDie = _hitDieForClassLevel(classes[index], classLevel);
    if (hitDie != null) hitDice.add(hitDie);
  }
  if (hitDice.isEmpty) return null;
  int rank(String hitDie) {
    final dieSides = int.tryParse(hitDie.toLowerCase().replaceFirst('d', ''));
    return dieSides ?? int.tryParse(hitDie) ?? 0;
  }

  hitDice.sort((first, second) => rank(second).compareTo(rank(first)));
  return hitDice.first;
}

int? _maximumHitPointsForHitDie(String hitDie) {
  final dieSides = int.tryParse(hitDie.toLowerCase().replaceFirst('d', ''));
  return dieSides ?? int.tryParse(hitDie);
}

int _hitPointsWithConstitution(int baseHitPoints, int constitutionModifier) {
  final total = baseHitPoints + constitutionModifier;
  return total < 1 ? 1 : total;
}

class CharacterVaultPage extends StatefulWidget {
  const CharacterVaultPage({super.key});

  @override
  State<CharacterVaultPage> createState() => _CharacterVaultPageState();
}

class _CharacterVaultPageState extends State<CharacterVaultPage> {
  static const _storageKey = 'cnc_companion.characters.v1';
  static const _racesKey = 'cnc_companion.reference.races.v1';
  static const _classesKey = 'cnc_companion.reference.classes.v1';
  static const _gearKey = 'cnc_companion.reference.gear.v1';
  static const _spellsKey = 'cnc_companion.reference.spells.v1';
  static const _weaponCatalogSeededKey =
      'cnc_companion.reference.weapons.seeded.v1';
  static const _shieldCatalogSeededKey =
      'cnc_companion.reference.shields.seeded.v1';
  static const _otherGearCatalogSeededKey =
      'cnc_companion.reference.other_gear.seeded.v1';
  static const _referenceDefaultsSeededKey =
      'cnc_companion.reference.defaults_seeded.v1';
  static const _defaultRaces = [
    'Dwarf',
    'Elf',
    'Gnome',
    'Halfling',
    'Half-Elf',
    'Half-Orc',
    'Human',
  ];
  static const _defaultClasses = [
    'Assassin',
    'Barbarian',
    'Bard',
    'Cleric',
    'Druid',
    'Fighter',
    'Illusionist',
    'Knight',
    'Monk',
    'Paladin',
    'Ranger',
    'Rogue',
    'Wizard',
  ];
  static const _sections = [
    ('Overview', Icons.dashboard_outlined),
    ('Abilities', Icons.bolt_outlined),
    ('Saving Throws', Icons.shield_outlined),
    ('Spells', Icons.auto_awesome_outlined),
    ('Gear & Notes', Icons.backpack_outlined),
  ];

  List<CharacterSheet> _characters = [];
  List<String> _races = [];
  List<String> _classes = [];
  List<GearReferenceItem> _gearItems = [];
  List<SpellReferenceItem> _spellItems = [];
  String? _selectedId;
  int _section = 0;
  bool _referenceMode = false;
  String? _referenceKind;
  String? _referenceName;
  bool _loading = true;
  String? _loadError;

  CharacterSheet? get _selected {
    for (final character in _characters) {
      if (character.id == _selectedId) return character;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_storageKey);
      var races = preferences.getStringList(_racesKey) ?? _defaultRaces;
      var classes = preferences.getStringList(_classesKey) ?? _defaultClasses;
      final storedGear = preferences.getString(_gearKey);
      final storedSpells = preferences.getString(_spellsKey);
      final spellItems = storedSpells == null
          ? <SpellReferenceItem>[]
          : (jsonDecode(storedSpells) as List<dynamic>)
                .map(
                  (entry) => SpellReferenceItem.fromJson(
                    Map<String, dynamic>.from(entry as Map),
                  ),
                )
                .toList();
      if (storedSpells == null) {
        final saved = await preferences.setString(_spellsKey, jsonEncode([]));
        if (!saved) {
          throw StateError('Could not initialize spell reference data.');
        }
      }
      var gearItems = storedGear == null
          ? _defaultGearItems
          : (jsonDecode(storedGear) as List<dynamic>)
                .map(
                  (entry) => GearReferenceItem.fromJson(
                    Map<String, dynamic>.from(entry as Map),
                  ),
                )
                .toList();
      if (storedGear == null) {
        final saved = await preferences.setString(
          _gearKey,
          jsonEncode(gearItems.map((item) => item.toJson()).toList()),
        );
        final catalogSeeded = await preferences.setBool(
          _weaponCatalogSeededKey,
          true,
        );
        final shieldsSeeded = await preferences.setBool(
          _shieldCatalogSeededKey,
          true,
        );
        final otherGearSeeded = await preferences.setBool(
          _otherGearCatalogSeededKey,
          true,
        );
        if (!saved || !catalogSeeded || !shieldsSeeded || !otherGearSeeded) {
          throw StateError('Could not initialize gear reference data.');
        }
      } else if (!(preferences.getBool(_weaponCatalogSeededKey) ?? false)) {
        gearItems = [
          for (final item in gearItems)
            if (item.category != 'Weapons' ||
                !_defaultWeapons.any((weapon) => weapon.name == item.name))
              item
            else
              _defaultWeapons.firstWhere((weapon) => weapon.name == item.name),
          for (final weapon in _defaultWeapons)
            if (!gearItems.any(
              (item) => item.category == 'Weapons' && item.name == weapon.name,
            ))
              weapon,
        ];
        final saved = await preferences.setString(
          _gearKey,
          jsonEncode(gearItems.map((item) => item.toJson()).toList()),
        );
        final catalogSeeded = await preferences.setBool(
          _weaponCatalogSeededKey,
          true,
        );
        if (!saved || !catalogSeeded) {
          throw StateError('Could not add the default weapon reference data.');
        }
      }
      if (!(preferences.getBool(_shieldCatalogSeededKey) ?? false)) {
        gearItems = [
          for (final item in gearItems)
            if (item.category != 'Shield' ||
                !_defaultShields.any((shield) => shield.name == item.name))
              item
            else
              _defaultShields.firstWhere((shield) => shield.name == item.name),
          for (final shield in _defaultShields)
            if (!gearItems.any(
              (item) => item.category == 'Shield' && item.name == shield.name,
            ))
              shield,
        ];
        final saved = await preferences.setString(
          _gearKey,
          jsonEncode(gearItems.map((item) => item.toJson()).toList()),
        );
        final catalogSeeded = await preferences.setBool(
          _shieldCatalogSeededKey,
          true,
        );
        if (!saved || !catalogSeeded) {
          throw StateError('Could not add the default shield reference data.');
        }
      }
      if (!(preferences.getBool(_otherGearCatalogSeededKey) ?? false)) {
        final defaults = [
          ..._defaultHelms,
          ..._defaultEquipment,
          ..._defaultContainers,
        ];
        gearItems = [
          for (final item in gearItems)
            if (!defaults.any(
              (reference) =>
                  reference.category == item.category &&
                  reference.name == item.name,
            ))
              item
            else
              defaults.firstWhere(
                (reference) =>
                    reference.category == item.category &&
                    reference.name == item.name,
              ),
          for (final reference in defaults)
            if (!gearItems.any(
              (item) =>
                  item.category == reference.category &&
                  item.name == reference.name,
            ))
              reference,
        ];
        final saved = await preferences.setString(
          _gearKey,
          jsonEncode(gearItems.map((item) => item.toJson()).toList()),
        );
        final catalogSeeded = await preferences.setBool(
          _otherGearCatalogSeededKey,
          true,
        );
        if (!saved || !catalogSeeded) {
          throw StateError('Could not add default equipment reference data.');
        }
      }
      if (!(preferences.getBool(_referenceDefaultsSeededKey) ?? false)) {
        races = _mergeReferenceOptions(_defaultRaces, races);
        classes = _mergeReferenceOptions(_defaultClasses, classes);
        final racesSaved = await preferences.setStringList(_racesKey, races);
        final classesSaved = await preferences.setStringList(
          _classesKey,
          classes,
        );
        final migrationSaved = await preferences.setBool(
          _referenceDefaultsSeededKey,
          true,
        );
        if (!racesSaved || !classesSaved || !migrationSaved) {
          throw StateError(
            'Could not initialize race and class reference data.',
          );
        }
      }
      final normalizedRaces = _mergeReferenceOptions(
        const [],
        races.map(_normalizeLegacyRaceName).toList(),
      );
      if (!_sameOptions(races, normalizedRaces)) {
        final saved = await preferences.setStringList(
          _racesKey,
          normalizedRaces,
        );
        if (!saved) {
          throw StateError('Could not update race reference data.');
        }
        races = normalizedRaces;
      }
      final characters = stored == null
          ? <CharacterSheet>[]
          : (jsonDecode(stored) as List<dynamic>)
                .map(
                  (entry) => CharacterSheet.fromJson(
                    Map<String, dynamic>.from(entry as Map),
                  ),
                )
                .map((character) {
                  final normalizedRace = _normalizeLegacyRaceName(
                    character.race,
                  );
                  return normalizedRace == character.race
                      ? character
                      : character.copyWith(race: normalizedRace);
                })
                .toList();
      if (stored != null) {
        final updatedCharacters = jsonEncode(
          characters.map((character) => character.toJson()).toList(),
        );
        if (updatedCharacters != stored) {
          final saved = await preferences.setString(
            _storageKey,
            updatedCharacters,
          );
          if (!saved) {
            throw StateError('Could not update saved character race names.');
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _characters = characters;
        _races = races;
        _classes = classes;
        _gearItems = gearItems;
        _spellItems = spellItems;
        _selectedId = characters.isEmpty ? null : characters.first.id;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load saved characters: $error';
        _loading = false;
      });
    }
  }

  Future<void> _persistCharacters() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _storageKey,
        jsonEncode(_characters.map((character) => character.toJson()).toList()),
      );
      if (!saved && mounted) {
        _showMessage('Character changes could not be saved on this device.');
      }
    } catch (error) {
      if (mounted) _showMessage('Could not save character changes: $error');
    }
  }

  Future<void> _persistReferenceData() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final racesSaved = await preferences.setStringList(_racesKey, _races);
      final classesSaved = await preferences.setStringList(
        _classesKey,
        _classes,
      );
      final gearSaved = await preferences.setString(
        _gearKey,
        jsonEncode(_gearItems.map((item) => item.toJson()).toList()),
      );
      if ((!racesSaved || !classesSaved || !gearSaved) && mounted) {
        _showMessage('Reference data could not be saved on this device.');
      }
    } catch (error) {
      if (mounted) _showMessage('Could not save reference data: $error');
    }
  }

  Future<void> _persistSpells() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _spellsKey,
        jsonEncode(_spellItems.map((item) => item.toJson()).toList()),
      );
      if (!saved && mounted) {
        _showMessage('Spell reference data could not be saved on this device.');
      }
    } catch (error) {
      if (mounted) _showMessage('Could not save spell reference data: $error');
    }
  }

  List<String> _mergeReferenceOptions(
    List<String> defaults,
    List<String> existing,
  ) {
    final options = <String, String>{};
    for (final option in [...defaults, ...existing]) {
      options.putIfAbsent(option.toLowerCase(), () => option);
    }
    return options.values.toList()..sort(
      (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
    );
  }

  String _normalizeLegacyRaceName(String race) =>
      race.trim().toLowerCase() == 'hafling' ? 'Halfling' : race;

  bool _sameOptions(List<String> first, List<String> second) {
    if (first.length != second.length) return false;
    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _createCharacter() async {
    final character = await showDialog<CharacterSheet>(
      context: context,
      builder: (_) => CharacterFormDialog(races: _races, classes: _classes),
    );
    if (character == null || !mounted) return;
    setState(() {
      _characters = [..._characters, character];
      _selectedId = character.id;
      _section = 0;
      _referenceMode = false;
    });
    await _persistCharacters();
  }

  Future<void> _editCharacter(CharacterSheet character) async {
    final updated = await showDialog<CharacterSheet>(
      context: context,
      builder: (_) => CharacterFormDialog(
        character: character,
        races: _races,
        classes: _classes,
      ),
    );
    if (updated == null || !mounted) return;
    setState(() {
      _characters = _characters
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
    });
    await _persistCharacters();
  }

  Future<void> _updateCharacter(CharacterSheet updated) async {
    setState(() {
      _characters = _characters
          .map((item) => item.id == updated.id ? updated : item)
          .toList();
    });
    await _persistCharacters();
  }

  Future<void> _levelUpCharacter(CharacterSheet character) async {
    final nextLevel = character.hpLevel + 1;
    if (nextLevel > character.effectiveLevel || nextLevel > 20) return;
    final hitDie = _highestHitDieForLevel(
      character.classes,
      nextLevel,
      classMode: character.classMode,
    );
    if (hitDie == null || _maximumHitPointsForHitDie(hitDie) == null) {
      _showMessage('No Hit Die progression is available for this level.');
      return;
    }

    final hitPoints = await showDialog<int>(
      context: context,
      builder: (context) => _LevelUpDialog(
        character: character,
        nextLevel: nextLevel,
        hitDie: hitDie,
        constitutionModifier: character.statModifierFor('Constitution'),
      ),
    );
    if (hitPoints == null || !mounted) return;
    await _updateCharacter(
      character.copyWith(
        maxHp: character.maxHp + hitPoints,
        hpLevel: nextLevel,
      ),
    );
    _showMessage('Level $nextLevel reached. +$hitPoints Max HP.');
  }

  Future<void> _deleteCharacter(CharacterSheet character) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete character?'),
        content: Text('Remove ${character.name} from this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _characters = _characters
          .where((item) => item.id != character.id)
          .toList();
      _selectedId = _characters.isEmpty ? null : _characters.first.id;
      _section = 0;
    });
    await _persistCharacters();
  }

  Future<void> _addReferenceOption({
    required String label,
    required List<String> options,
    required ValueChanged<List<String>> onChanged,
  }) async {
    final value = await _askForText(context, 'Add $label', '$label name');
    if (value == null || value.isEmpty || !mounted) return;
    if (options.any((option) => option.toLowerCase() == value.toLowerCase())) {
      _showMessage('$value is already in your reference data.');
      return;
    }
    onChanged(_mergeReferenceOptions(const [], [...options, value]));
    await _persistReferenceData();
  }

  Future<void> _removeReferenceOption({
    required List<String> options,
    required String value,
    required ValueChanged<List<String>> onChanged,
  }) async {
    onChanged(options.where((option) => option != value).toList());
    await _persistReferenceData();
  }

  Future<void> _addGearItem(String category) async {
    final item = await showDialog<GearReferenceItem>(
      context: context,
      builder: (_) => _GearItemDialog(category: category),
    );
    if (item == null || !mounted) return;
    final duplicate = _gearItems.any(
      (existing) =>
          existing.category == category &&
          existing.name.toLowerCase() == item.name.toLowerCase(),
    );
    if (duplicate) {
      _showMessage('${item.name} is already in the $category table.');
      return;
    }
    setState(() => _gearItems = [..._gearItems, item]);
    await _persistReferenceData();
  }

  Future<void> _editGearItem(GearReferenceItem item) async {
    final updated = await showDialog<GearReferenceItem>(
      context: context,
      builder: (_) =>
          _GearItemDialog(category: item.category, initialItem: item),
    );
    if (updated == null || !mounted) return;
    final duplicate = _gearItems.any(
      (existing) =>
          existing.category == item.category &&
          existing.name != item.name &&
          existing.name.toLowerCase() == updated.name.toLowerCase(),
    );
    if (duplicate) {
      _showMessage('${updated.name} is already in the ${item.category} table.');
      return;
    }
    setState(() {
      _gearItems = [
        for (final existing in _gearItems)
          if (existing.category == item.category && existing.name == item.name)
            updated
          else
            existing,
      ];
    });
    await _persistReferenceData();
  }

  Future<void> _removeGearItem(GearReferenceItem item) async {
    setState(
      () => _gearItems = _gearItems
          .where(
            (existing) =>
                existing.category != item.category ||
                existing.name != item.name,
          )
          .toList(),
    );
    await _persistReferenceData();
  }

  Future<void> _addSpell() async {
    final spell = await showDialog<SpellReferenceItem>(
      context: context,
      builder: (_) => const _SpellReferenceDialog(),
    );
    if (spell == null || !mounted) return;
    if (_spellItems.any(
      (existing) =>
          existing.spellName.toLowerCase() == spell.spellName.toLowerCase() &&
          existing.characterClass.toLowerCase() ==
              spell.characterClass.toLowerCase() &&
          existing.level.toLowerCase() == spell.level.toLowerCase(),
    )) {
      _showMessage(
        '${spell.spellName} is already listed for this class and level.',
      );
      return;
    }
    setState(() => _spellItems = [..._spellItems, spell]);
    await _persistSpells();
  }

  Future<void> _editSpell(SpellReferenceItem item) async {
    final updated = await showDialog<SpellReferenceItem>(
      context: context,
      builder: (_) => _SpellReferenceDialog(initialItem: item),
    );
    if (updated == null || !mounted) return;
    if (_spellItems.any(
      (existing) =>
          existing != item &&
          existing.spellName.toLowerCase() == updated.spellName.toLowerCase() &&
          existing.characterClass.toLowerCase() ==
              updated.characterClass.toLowerCase() &&
          existing.level.toLowerCase() == updated.level.toLowerCase(),
    )) {
      _showMessage(
        '${updated.spellName} is already listed for this class and level.',
      );
      return;
    }
    setState(() {
      _spellItems = [
        for (final existing in _spellItems)
          if (existing == item) updated else existing,
      ];
    });
    await _persistSpells();
  }

  Future<void> _removeSpell(SpellReferenceItem spell) async {
    setState(
      () => _spellItems = _spellItems.where((item) => item != spell).toList(),
    );
    await _persistSpells();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: _forest),
                const SizedBox(height: 12),
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadCharacters,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        final character = _selected;
        return Scaffold(
          body: SafeArea(
            child: wide
                ? Row(
                    children: [
                      _Sidebar(
                        section: _section,
                        sections: _sections,
                        characters: _characters,
                        selectedId: _selectedId,
                        referenceMode: _referenceMode,
                        onSection: (index) => setState(() {
                          _section = index;
                          _referenceMode = false;
                        }),
                        onSelect: (id) => setState(() {
                          _selectedId = id;
                          _section = 0;
                          _referenceMode = false;
                        }),
                        onCreate: _createCharacter,
                        onReference: () =>
                            setState(() => _referenceMode = true),
                      ),
                      Expanded(
                        child: _mainContent(
                          character,
                          wide: true,
                          onCreate: _createCharacter,
                          onReference: () =>
                              setState(() => _referenceMode = true),
                        ),
                      ),
                    ],
                  )
                : _mainContent(
                    character,
                    wide: false,
                    onCreate: _createCharacter,
                    onReference: () => setState(() => _referenceMode = true),
                  ),
          ),
          bottomNavigationBar: wide || _characters.isEmpty
              ? null
              : NavigationBar(
                  selectedIndex: _section,
                  onDestinationSelected: (index) =>
                      setState(() => _section = index),
                  destinations: [
                    for (final section in _sections)
                      NavigationDestination(
                        icon: Icon(section.$2),
                        label: section.$1,
                      ),
                  ],
                ),
        );
      },
    );
  }

  Widget _mainContent(
    CharacterSheet? character, {
    required bool wide,
    required VoidCallback onCreate,
    required VoidCallback onReference,
  }) {
    if (_referenceMode) {
      return Column(
        children: [
          _ReferenceTopBar(
            wide: wide,
            title: _referenceName ?? 'Reference Data',
            backTooltip: _referenceName == null
                ? 'Back to character sheet'
                : 'Back to reference data',
            onBack: () => setState(() {
              if (_referenceName != null) {
                _referenceKind = null;
                _referenceName = null;
              } else {
                _referenceMode = false;
              }
            }),
            onCreate: onCreate,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                wide ? 40 : 20,
                24,
                wide ? 40 : 20,
                36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: _referenceName == null
                      ? _ReferenceDataSection(
                          races: _races,
                          classes: _classes,
                          onAddRace: () => _addReferenceOption(
                            label: 'Race',
                            options: _races,
                            onChanged: (values) =>
                                setState(() => _races = values),
                          ),
                          onAddClass: () => _addReferenceOption(
                            label: 'Class',
                            options: _classes,
                            onChanged: (values) =>
                                setState(() => _classes = values),
                          ),
                          onRemoveRace: (value) => _removeReferenceOption(
                            options: _races,
                            value: value,
                            onChanged: (values) =>
                                setState(() => _races = values),
                          ),
                          onRemoveClass: (value) => _removeReferenceOption(
                            options: _classes,
                            value: value,
                            onChanged: (values) =>
                                setState(() => _classes = values),
                          ),
                          onOpenRace: (name) => setState(() {
                            _referenceKind = 'Race';
                            _referenceName = name;
                          }),
                          onOpenClass: (name) => setState(() {
                            _referenceKind = 'Class';
                            _referenceName = name;
                          }),
                          onOpenGear: (category) => setState(() {
                            _referenceKind = 'Gear';
                            _referenceName = category;
                          }),
                          onOpenSpells: () => setState(() {
                            _referenceKind = 'Spells';
                            _referenceName = 'Spells';
                          }),
                        )
                      : _referenceKind == 'Gear'
                      ? _GearReferenceDetailPage(
                          category: _referenceName!,
                          items: _gearItems
                              .where((item) => item.category == _referenceName)
                              .toList(),
                          onAdd: () => _addGearItem(_referenceName!),
                          onEdit: _editGearItem,
                          onRemove: _removeGearItem,
                        )
                      : _referenceKind == 'Spells'
                      ? _SpellReferenceDetailPage(
                          items: _spellItems,
                          onAdd: _addSpell,
                          onEdit: _editSpell,
                          onRemove: _removeSpell,
                        )
                      : ReferenceDetailPage(
                          kind: _referenceKind!,
                          name: _referenceName!,
                        ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (character == null) {
      return _EmptyVault(onCreate: onCreate, onReference: onReference);
    }
    return Column(
      children: [
        _TopBar(
          character: character,
          characters: _characters,
          wide: wide,
          onSelect: (id) => setState(() {
            _selectedId = id;
            _section = 0;
          }),
          onCreate: onCreate,
          onReference: onReference,
          onEdit: () => _editCharacter(character),
          onDelete: () => _deleteCharacter(character),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              wide ? 40 : 20,
              24,
              wide ? 40 : 20,
              36,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1050),
                child: _sectionContent(character, wide),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionContent(CharacterSheet character, bool wide) {
    switch (_section) {
      case 1:
        return _AbilitiesSection(
          character: character,
          wide: wide,
          onChanged: _updateCharacter,
        );
      case 2:
        return _SavesSection(character: character, onChanged: _updateCharacter);
      case 3:
        if (character.spellcastingClasses.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SpellsPerDayCharacterSection(character: character),
              const SizedBox(height: 24),
              _CharacterKnownSpellsSection(
                character: character,
                referenceSpells: _spellItems,
                onChanged: (spells) =>
                    _updateCharacter(character.copyWith(spells: spells)),
              ),
            ],
          );
        }
        return _ListSection(
          title: 'Spellbook',
          subtitle: 'Keep your known spells close at hand.',
          icon: Icons.auto_awesome_outlined,
          items: character.spells,
          emptyLabel: 'No spells recorded yet.',
          onChanged: (spells) =>
              _updateCharacter(character.copyWith(spells: spells)),
        );
      case 4:
        return _GearSection(
          character: character,
          gearItems: _gearItems,
          onChanged: _updateCharacter,
        );
      default:
        return _OverviewSection(
          character: character,
          wide: wide,
          onEdit: () => _editCharacter(character),
          onDelete: () => _deleteCharacter(character),
          onLevelUp: () => _levelUpCharacter(character),
          onSection: (index) => setState(() => _section = index),
        );
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.section,
    required this.sections,
    required this.characters,
    required this.selectedId,
    required this.referenceMode,
    required this.onSection,
    required this.onSelect,
    required this.onCreate,
    required this.onReference,
  });

  final int section;
  final List<(String, IconData)> sections;
  final List<CharacterSheet> characters;
  final String? selectedId;
  final bool referenceMode;
  final ValueChanged<int> onSection;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;
  final VoidCallback onReference;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: const Color(0xFF203D32),
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_stories, color: Color(0xFFE7C78F)),
              ),
              const SizedBox(width: 11),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'C&C COMPANION',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'ADVENTURER’S LEDGER',
                    style: TextStyle(
                      color: Color(0xFFB7C7BB),
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          const _SidebarLabel('YOUR CHARACTERS'),
          const SizedBox(height: 10),
          for (final character in characters)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _SideButton(
                selected: character.id == selectedId && section == 0,
                icon: Icons.person_outline,
                label: character.name,
                onTap: () => onSelect(character.id),
              ),
            ),
          TextButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New character'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE7C78F),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            ),
          ),
          const SizedBox(height: 28),
          const _SidebarLabel('CHARACTER SHEET'),
          const SizedBox(height: 10),
          for (var index = 0; index < sections.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _SideButton(
                selected: section == index && index != 0,
                icon: sections[index].$2,
                label: sections[index].$1,
                onTap: () => onSection(index),
              ),
            ),
          const SizedBox(height: 10),
          _SideButton(
            selected: referenceMode,
            icon: Icons.menu_book_outlined,
            label: 'Reference data',
            onTap: onReference,
          ),
          const Spacer(),
          const Divider(color: Color(0xFF426153)),
          const Padding(
            padding: EdgeInsets.only(top: 10, left: 10),
            child: Text(
              'Your sheets are stored on this device.',
              style: TextStyle(color: Color(0xFFB7C7BB), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarLabel extends StatelessWidget {
  const _SidebarLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 10),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF9FB2A5),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF355648) : Colors.transparent,
    borderRadius: BorderRadius.circular(11),
    child: InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected
                  ? const Color(0xFFE7C78F)
                  : const Color(0xFFB7C7BB),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFFD4DED6),
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.character,
    required this.characters,
    required this.wide,
    required this.onSelect,
    required this.onCreate,
    required this.onReference,
    required this.onEdit,
    required this.onDelete,
  });

  final CharacterSheet character;
  final List<CharacterSheet> characters;
  final bool wide;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreate;
  final VoidCallback onReference;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
      decoration: const BoxDecoration(
        color: _paper,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E6DE))),
      ),
      child: Row(
        children: [
          if (!wide) ...[
            const Icon(Icons.auto_stories, color: _forest),
            const SizedBox(width: 9),
            const Text(
              'C&C COMPANION',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const Spacer(),
          ] else
            Expanded(
              child: Text(
                character.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (characters.length > 1)
            PopupMenuButton<String>(
              tooltip: 'Switch character',
              onSelected: onSelect,
              itemBuilder: (context) => [
                for (final item in characters)
                  PopupMenuItem(value: item.id, child: Text(item.name)),
              ],
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.people_outline, color: _forest),
              ),
            ),
          IconButton(
            tooltip: 'Reference data',
            onPressed: onReference,
            icon: const Icon(Icons.menu_book_outlined),
          ),
          if (wide)
            IconButton(
              tooltip: 'Edit character',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            )
          else
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit character')),
                PopupMenuItem(value: 'delete', child: Text('Delete character')),
              ],
            ),
          const SizedBox(width: 5),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: Text(wide ? 'New character' : 'New'),
            style: FilledButton.styleFrom(
              backgroundColor: _forest,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceTopBar extends StatelessWidget {
  const _ReferenceTopBar({
    required this.wide,
    required this.title,
    required this.backTooltip,
    required this.onBack,
    required this.onCreate,
  });

  final bool wide;
  final String title;
  final String backTooltip;
  final VoidCallback onBack;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Container(
    height: 76,
    padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16),
    decoration: const BoxDecoration(
      color: _paper,
      border: Border(bottom: BorderSide(color: Color(0xFFE8E6DE))),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: backTooltip,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: _forest),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, size: 18),
          label: Text(wide ? 'New character' : 'New'),
          style: FilledButton.styleFrom(
            backgroundColor: _forest,
            foregroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    ),
  );
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault({required this.onCreate, required this.onReference});
  final VoidCallback onCreate;
  final VoidCallback onReference;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EDE7),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.auto_stories, size: 42, color: _forest),
            ),
            const SizedBox(height: 24),
            const Text(
              'Every great tale starts\nwith a character.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create your first adventurer and keep their abilities, '
              'saving throws, spells, and gear all in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.5),
            ),
            const SizedBox(height: 25),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create a character'),
              style: FilledButton.styleFrom(
                backgroundColor: _forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onReference,
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Add race and class reference data'),
              style: TextButton.styleFrom(foregroundColor: _forest),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LevelUpDialog extends StatefulWidget {
  const _LevelUpDialog({
    required this.character,
    required this.nextLevel,
    required this.hitDie,
    required this.constitutionModifier,
  });

  final CharacterSheet character;
  final int nextLevel;
  final String hitDie;
  final int constitutionModifier;

  @override
  State<_LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<_LevelUpDialog> {
  late final TextEditingController _hitPoints;
  late final int _maximum;
  String? _error;

  @override
  void initState() {
    super.initState();
    _maximum = _maximumHitPointsForHitDie(widget.hitDie)!;
    final isDie = widget.hitDie.toLowerCase().startsWith('d');
    _hitPoints = TextEditingController(text: isDie ? '' : '$_maximum');
  }

  @override
  void dispose() {
    _hitPoints.dispose();
    super.dispose();
  }

  void _roll() {
    setState(() {
      _hitPoints.text = '${Random().nextInt(_maximum) + 1}';
      _error = null;
    });
  }

  void _confirm() {
    final hitPoints = int.tryParse(_hitPoints.text.trim());
    if (hitPoints == null || hitPoints < 1 || hitPoints > _maximum) {
      setState(() => _error = 'Choose a value from 1 to $_maximum.');
      return;
    }
    Navigator.pop(
      context,
      _hitPointsWithConstitution(hitPoints, widget.constitutionModifier),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDie = widget.hitDie.toLowerCase().startsWith('d');
    final baseGain = int.tryParse(_hitPoints.text.trim());
    final totalGain = baseGain == null
        ? null
        : _hitPointsWithConstitution(baseGain, widget.constitutionModifier);
    final constitutionText = widget.constitutionModifier >= 0
        ? '+${widget.constitutionModifier}'
        : '${widget.constitutionModifier}';
    return AlertDialog(
      title: Text('Level up to ${widget.nextLevel}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.character.classes.join(' / ')} · '
            'Hit Die ${widget.hitDie} · CON $constitutionText',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('level-up-hit-points'),
            controller: _hitPoints,
            readOnly: !isDie,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: isDie ? 'Hit Die result' : 'Base HP gain',
              helperText: isDie
                  ? 'Enter 1 to $_maximum; Constitution is added.'
                  : 'Fixed progression gain; Constitution is added.',
              errorText: _error,
            ),
          ),
          if (totalGain != null) ...[
            const SizedBox(height: 8),
            Text(
              'HP added: $baseGain $constitutionText CON = $totalGain',
              key: const ValueKey('level-up-hp-total'),
            ),
          ],
          if (isDie) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const ValueKey('roll-level-up-hp'),
              onPressed: _roll,
              icon: const Icon(Icons.casino_outlined),
              label: Text('Roll ${widget.hitDie}'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('confirm-level-up'),
          onPressed: _confirm,
          child: Text(
            totalGain == null
                ? 'Add HP to maximum'
                : 'Add $totalGain HP to maximum',
          ),
        ),
      ],
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.character,
    required this.wide,
    required this.onEdit,
    required this.onDelete,
    required this.onLevelUp,
    required this.onSection,
  });

  final CharacterSheet character;
  final bool wide;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onLevelUp;
  final ValueChanged<int> onSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow('CHARACTER OVERVIEW'),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    character.name,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    [
                      if (character.race.isNotEmpty) character.race,
                      if (character.classes.isNotEmpty)
                        character.classes.join(' / '),
                      'Level ${character.effectiveLevel}',
                    ].join('  ·  '),
                    style: const TextStyle(color: _muted, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (wide)
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit details'),
              ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 650 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: columns == 4 ? 1.65 : 1.75,
              children: [
                _MetricCard(
                  label: 'HIT POINTS',
                  value: '${character.currentHp} / ${character.maxHp}',
                  icon: Icons.favorite_border,
                  accent: const Color(0xFFB55245),
                ),
                _MetricCard(
                  label: 'ARMOR CLASS',
                  value: '${character.armorClass}',
                  icon: Icons.shield_outlined,
                ),
                _MetricCard(
                  label: 'EXPERIENCE',
                  value: _formatNumber(character.experience),
                  icon: Icons.stars_outlined,
                  accent: _gold,
                ),
                _MetricCard(
                  label: 'NEXT LEVEL XP',
                  value: character.effectiveLevel >= 20
                      ? 'MAX LEVEL'
                      : character.experienceRequiredForNextLevel == null
                      ? '—'
                      : _formatNumber(
                          character.experienceRequiredForNextLevel!,
                        ),
                  icon: Icons.trending_up,
                  accent: _forest,
                ),
                _MetricCard(
                  label: 'ALIGNMENT',
                  value: character.alignment.isEmpty
                      ? '—'
                      : character.alignment,
                  icon: Icons.balance_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const _SectionHeading(title: 'Armor Class'),
        const SizedBox(height: 12),
        _ArmorClassBreakdown(character: character),
        const SizedBox(height: 24),
        const _SectionHeading(title: 'To Hit'),
        const SizedBox(height: 12),
        if (character.equippedGear.any((item) => item.category == 'Weapons'))
          Column(
            children: [
              for (final weapon in character.equippedGear.where(
                (item) => item.category == 'Weapons',
              ))
                Card(
                  key: ValueKey('to-hit-${weapon.id}'),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEAF0E9),
                      foregroundColor: _forest,
                      child: Icon(Icons.gps_fixed, size: 18),
                    ),
                    title: Text(weapon.name),
                    subtitle: Text(
                      '${weapon.attackType} · BtH ${_signed(character.classBth)}'
                      ' · ${weapon.attackType == 'Ranged' ? 'Dex' : 'Str'} '
                      '${_signed(character.statModifierFor(weapon.attackType == 'Ranged' ? 'Dexterity' : 'Strength'))}'
                      '${weapon.magical ? ' · Magic ${_signed(weapon.magicModifier)}' : ''}',
                    ),
                    trailing: Text(
                      _signed(character.toHitForWeapon(weapon)),
                      key: ValueKey('to-hit-value-${weapon.id}'),
                      style: const TextStyle(
                        color: _forest,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Class BtH: ${_signed(character.classBth)}'),
                  const SizedBox(height: 6),
                  Text(
                    'Melee: ${_signed(character.classBth + character.statModifierFor('Strength'))}'
                    '    Ranged: ${_signed(character.classBth + character.statModifierFor('Dexterity'))}',
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Equip weapons in Gear & notes to see weapon-specific To Hit.',
                    style: TextStyle(color: _muted),
                  ),
                ],
              ),
            ),
          ),
        if (character.classMode == 'multiclass' && character.classes.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Experience split evenly: '
              '${_formatNumber(character.experiencePerClass)} XP per class.',
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ),
        if (character.hpLevel < character.effectiveLevel)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: FilledButton.icon(
              key: const ValueKey('level-up'),
              onPressed:
                  _highestHitDieForLevel(
                        character.classes,
                        character.hpLevel + 1,
                        classMode: character.classMode,
                      ) ==
                      null
                  ? null
                  : onLevelUp,
              icon: const Icon(Icons.trending_up),
              label: Text('Level up to ${character.hpLevel + 1}'),
            ),
          )
        else if (character.effectiveLevel < 20 &&
            _highestHitDieForLevel(
                  character.classes,
                  character.hpLevel + 1,
                  classMode: character.classMode,
                ) ==
                null)
          const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Text(
              'Hit Die data is needed to level up and increase Max HP.',
              style: TextStyle(color: _muted),
            ),
          ),
        const SizedBox(height: 26),
        _SectionHeading(
          title: 'Ability scores',
          actionLabel: 'View all',
          onAction: () => onSection(1),
        ),
        const SizedBox(height: 12),
        _AbilityStrip(character: character, compact: true),
        const SizedBox(height: 25),
        _SectionHeading(
          title: 'Saving throws',
          actionLabel: 'View all',
          onAction: () => onSection(2),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Column(
              children: [
                const _SaveRowHeader(),
                for (final name in CharacterSheet.abilityNames) ...[
                  _SaveRow(
                    name: name,
                    targetNumber: character.targetNumberFor(name),
                    modifier: character.statModifierFor(name),
                    levelModifier: character.effectiveLevel,
                    modifiedTarget: character.modifiedTargetFor(name),
                  ),
                  if (name != CharacterSheet.abilityNames.last)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        _SectionHeading(
          title: 'At a glance',
          actionLabel: 'Edit details',
          onAction: onEdit,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 40,
              runSpacing: 20,
              children: [
                _InfoField(
                  label: 'CLASS',
                  value: _orDash(character.classes.join(', ')),
                ),
                _InfoField(label: 'RACE', value: _orDash(character.race)),
                _InfoField(
                  label: 'BACKGROUND',
                  value: _orDash(character.background),
                ),
                _InfoField(
                  label: 'LEVEL',
                  value: '${character.effectiveLevel}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            key: const ValueKey('delete-character'),
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete character'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArmorClassBreakdown extends StatelessWidget {
  const _ArmorClassBreakdown({required this.character});

  final CharacterSheet character;

  @override
  Widget build(BuildContext context) {
    final shield = character.equippedShield;
    final dexterityModifier = character.statModifierFor('Dexterity');
    String? armorName;
    for (final item in character.equippedGear) {
      if (item.category == 'Armor') {
        armorName = item.name;
        break;
      }
    }
    final armorLabel = armorName == null ? 'Armor' : 'Armor ($armorName)';
    return Card(
      key: const ValueKey('armor-class-breakdown'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '10 base ${_signed(character.armorModifierForClass)} $armorLabel '
              '${_signed(dexterityModifier)} Dexterity '
              '= ${character.armorClassWithoutShield}',
              key: const ValueKey('armor-class-base-calculation'),
            ),
            if (shield != null) ...[
              const SizedBox(height: 8),
              Text(
                '${_signed(shield.shieldAc)} ${shield.name} shield bonus applies '
                'against up to ${shield.foes} '
                '${shield.foes == 1 ? 'attacker' : 'attackers'}: '
                'AC ${character.armorClass}.',
                key: const ValueKey('armor-class-shield-calculation'),
              ),
              const SizedBox(height: 6),
              Text(
                'Against any additional attackers, the shield bonus does not '
                'apply: AC ${character.armorClassWithoutShield}.',
                key: const ValueKey('armor-class-extra-attackers'),
                style: const TextStyle(color: _muted),
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'Shield AC bonuses protect against only the listed number of '
              'attackers at a time; other attackers do not receive that bonus.',
              style: TextStyle(color: _muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = _forest,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AbilitiesSection extends StatelessWidget {
  const _AbilitiesSection({
    required this.character,
    required this.wide,
    required this.onChanged,
  });

  final CharacterSheet character;
  final bool wide;
  final ValueChanged<CharacterSheet> onChanged;

  Future<void> _changeScore(
    BuildContext context,
    String ability,
    int value,
  ) async {
    final updated = Map<String, int>.from(character.abilities)
      ..[ability] = value - character.racialModifierFor(ability);
    onChanged(character.copyWith(abilities: updated));
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Eyebrow('CORE STATS'),
      const SizedBox(height: 8),
      const _PageTitle('Ability scores'),
      const SizedBox(height: 6),
      const Text(
        'Track the six prime abilities that shape your adventurer.',
        style: TextStyle(color: _muted),
      ),
      const SizedBox(height: 22),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 700 ? 3 : 2;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: wide ? 1.55 : 1.35,
            children: [
              for (final ability in CharacterSheet.abilityNames)
                _AbilityCard(
                  name: ability,
                  score: character.effectiveAbilities[ability] ?? 10,
                  baseScore: character.abilities[ability] ?? 10,
                  racialModifier: character.racialModifierFor(ability),
                  onChanged: (value) => _changeScore(context, ability, value),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _AbilityStrip extends StatelessWidget {
  const _AbilityStrip({required this.character, this.compact = false});
  final CharacterSheet character;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) => GridView.count(
          crossAxisCount: constraints.maxWidth >= 650 ? 6 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          childAspectRatio: constraints.maxWidth >= 650 ? 1.5 : 1,
          children: [
            for (final ability in CharacterSheet.abilityNames)
              _AbilityScoreTile(
                name: ability,
                score: character.effectiveAbilities[ability] ?? 10,
              ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _AbilityCard extends StatelessWidget {
  const _AbilityCard({
    required this.name,
    required this.score,
    required this.baseScore,
    required this.racialModifier,
    required this.onChanged,
  });

  final String name;
  final int score;
  final int baseScore;
  final int racialModifier;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
          if (racialModifier != 0)
            Text(
              'Base $baseScore · Race ${racialModifier > 0 ? '+' : ''}'
              '$racialModifier',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 35,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _modifier(score),
                  style: const TextStyle(
                    color: _forest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              _ScoreButton(
                icon: Icons.remove,
                label: 'Decrease $name',
                onPressed: score > 1 ? () => onChanged(score - 1) : null,
              ),
              const SizedBox(width: 8),
              _ScoreButton(
                icon: Icons.add,
                label: 'Increase $name',
                onPressed: score < 2000 ? () => onChanged(score + 1) : null,
              ),
              const Spacer(),
              const Text(
                'Score',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AbilityScoreTile extends StatelessWidget {
  const _AbilityScoreTile({required this.name, required this.score});
  final String name;
  final int score;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name.substring(0, 3).toUpperCase(),
            style: const TextStyle(
              color: _muted,
              fontSize: 9,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Text(
            _modifier(score),
            style: const TextStyle(color: _forest, fontSize: 10),
          ),
        ],
      ),
    ),
  );
}

class _ScoreButton extends StatelessWidget {
  const _ScoreButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 31,
    height: 31,
    child: IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: label,
      padding: EdgeInsets.zero,
      iconSize: 17,
      icon: Icon(icon),
    ),
  );
}

class _SavesSection extends StatelessWidget {
  const _SavesSection({required this.character, required this.onChanged});
  final CharacterSheet character;
  final ValueChanged<CharacterSheet> onChanged;

  void _setPrimary(String name, bool isPrimary) {
    final primaryAttributes = Set<String>.from(character.primaryAttributes);
    if (isPrimary) {
      if (primaryAttributes.length >=
          CharacterSheet.maxPrimaryAttributesForRace(character.race)) {
        return;
      }
      primaryAttributes.add(name);
    } else {
      primaryAttributes.remove(name);
    }
    onChanged(character.copyWith(primaryAttributes: primaryAttributes));
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Eyebrow('DEFENSE'),
      const SizedBox(height: 8),
      const _PageTitle('Saving throws'),
      const SizedBox(height: 6),
      const Text(
        'Humans may choose up to 3 primary attributes; all other races may '
        'choose up to 2. Target numbers and modifiers update automatically '
        'from your character’s ability scores.',
        style: TextStyle(color: _muted),
      ),
      const SizedBox(height: 22),
      LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth = constraints.maxWidth < 760
              ? 760.0
              : constraints.maxWidth - 28;
          return Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      const _SavingThrowHeader(),
                      for (final name in CharacterSheet.abilityNames) ...[
                        _SavingThrowRow(
                          name: name,
                          isPrimary: character.primaryAttributes.contains(name),
                          canSelectPrimary:
                              character.primaryAttributes.contains(name) ||
                              character.primaryAttributes.length <
                                  CharacterSheet.maxPrimaryAttributesForRace(
                                    character.race,
                                  ),
                          modifier: character.statModifierFor(name),
                          targetNumber: character.targetNumberFor(name),
                          levelModifier: character.effectiveLevel,
                          modifiedTarget: character.modifiedTargetFor(name),
                          onPrimaryChanged: (value) => _setPrimary(name, value),
                        ),
                        if (name != CharacterSheet.abilityNames.last)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}

class _SavingThrowHeader extends StatelessWidget {
  const _SavingThrowHeader();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 42,
    child: Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            'ATTRIBUTE',
            style: TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'TARGET NUMBER',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'STAT MODIFIER',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'LEVEL MOD',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'MODIFIED TARGET',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SavingThrowRow extends StatelessWidget {
  const _SavingThrowRow({
    required this.name,
    required this.isPrimary,
    required this.canSelectPrimary,
    required this.modifier,
    required this.targetNumber,
    required this.levelModifier,
    required this.modifiedTarget,
    required this.onPrimaryChanged,
  });

  final String name;
  final bool isPrimary;
  final bool canSelectPrimary;
  final int modifier;
  final int targetNumber;
  final int levelModifier;
  final int modifiedTarget;
  final ValueChanged<bool> onPrimaryChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Row(
      children: [
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Checkbox(
                key: ValueKey('primary-$name'),
                value: isPrimary,
                semanticLabel: '$name primary attribute',
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: canSelectPrimary
                    ? (value) => onPrimaryChanged(value ?? false)
                    : null,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '$targetNumber',
            key: ValueKey('target-$name'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            _signed(modifier),
            key: ValueKey('modifier-$name'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _forest,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '$levelModifier',
            key: ValueKey('level-$name'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            '$modifiedTarget',
            key: ValueKey('modified-$name'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _forest,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SaveRowHeader extends StatelessWidget {
  const _SaveRowHeader();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            'ATTRIBUTE',
            style: TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'TARGET',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'STAT MOD',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'LEVEL',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'MOD TARGET',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SaveRow extends StatelessWidget {
  const _SaveRow({
    required this.name,
    required this.modifier,
    required this.targetNumber,
    required this.levelModifier,
    required this.modifiedTarget,
  });
  final String name;
  final int modifier;
  final int targetNumber;
  final int levelModifier;
  final int modifiedTarget;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: Text(
            '$targetNumber',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            _signed(modifier),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _forest, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            '$levelModifier',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            '$modifiedTarget',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _forest, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _SpellsPerDayCharacterSection extends StatelessWidget {
  const _SpellsPerDayCharacterSection({required this.character});

  final CharacterSheet character;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Eyebrow('SPELLCASTING'),
      const SizedBox(height: 8),
      const _PageTitle('Spells per day'),
      const SizedBox(height: 12),
      for (final className in character.spellcastingClasses) ...[
        _SectionHeading(title: '$className spells per day'),
        const SizedBox(height: 8),
        _SpellSlotsTable(
          className: className,
          level: character.levelForClass(className),
          key: ValueKey('character-spells-per-day-${className.toLowerCase()}'),
        ),
        const SizedBox(height: 16),
      ],
    ],
  );
}

int? _spellReferenceLevel(String value) {
  final levelText = RegExp(r'^\s*(\d+)').firstMatch(value)?.group(1);
  return levelText == null ? null : int.tryParse(levelText);
}

int _highestSpellLevelAvailable(String className, int characterLevel) {
  final slots = _spellSlotsForClassLevel(className, characterLevel);
  var highest = -1;
  for (var level = 0; level < slots.length; level++) {
    if (slots[level] > 0) highest = level;
  }
  return highest;
}

class _CharacterKnownSpellsSection extends StatelessWidget {
  const _CharacterKnownSpellsSection({
    required this.character,
    required this.referenceSpells,
    required this.onChanged,
  });

  final CharacterSheet character;
  final List<SpellReferenceItem> referenceSpells;
  final ValueChanged<List<String>> onChanged;

  Future<void> _addSpells(
    BuildContext context,
    String className,
    List<SpellReferenceItem> available,
  ) async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (_) => _SelectReferenceSpellsDialog(
        className: className,
        items: available,
      ),
    );
    if (selected == null || selected.isEmpty) return;
    onChanged({...character.spells, ...selected}.toList());
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Eyebrow('SPELLCASTING'),
      const SizedBox(height: 8),
      const _PageTitle('Spells known'),
      const SizedBox(height: 6),
      const Text(
        'Clerics and Druids see all reference spells available at their level. '
        'Wizards and Illusionists add spells from the reference data.',
        style: TextStyle(color: _muted, height: 1.5),
      ),
      const SizedBox(height: 16),
      for (final className in character.spellcastingClasses) ...[
        _SectionHeading(title: '$className spells'),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final level = character.levelForClass(className);
            final isDivine =
                className.toLowerCase() == 'cleric' ||
                className.toLowerCase() == 'druid';
            final highestLevel = _highestSpellLevelAvailable(className, level);
            final classSpells = referenceSpells.where((spell) {
              if (spell.characterClass.trim().toLowerCase() !=
                  className.trim().toLowerCase()) {
                return false;
              }
              final spellLevel = _spellReferenceLevel(spell.level);
              if (spellLevel == null ||
                  spellLevel < 0 ||
                  spellLevel > highestLevel) {
                return false;
              }
              return isDivine ||
                  character.spells.contains(spell.selectionKey);
            }).toList()
              ..sort((first, second) {
                final levelComparison =
                    (_spellReferenceLevel(first.level) ?? 0).compareTo(
                      _spellReferenceLevel(second.level) ?? 0,
                    );
                return levelComparison != 0
                    ? levelComparison
                    : first.spellName.toLowerCase().compareTo(
                        second.spellName.toLowerCase(),
                      );
              });
            final availableToAdd = isDivine
                ? const <SpellReferenceItem>[]
                : referenceSpells
                      .where(
                        (spell) =>
                            spell.characterClass.trim().toLowerCase() ==
                                className.trim().toLowerCase() &&
                            !character.spells.contains(spell.selectionKey) &&
                            _spellReferenceLevel(spell.level) != null &&
                            _spellReferenceLevel(spell.level)! >= 0 &&
                            _spellReferenceLevel(spell.level)! <= highestLevel,
                      )
                      .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: classSpells.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            isDivine
                                ? 'No $className reference spells are available '
                                    'for level $level yet.'
                                : 'No $className spells selected yet.',
                            style: const TextStyle(color: _muted),
                          ),
                        )
                      : Column(
                          children: [
                            for (final spell in classSpells)
                              ListTile(
                                key: ValueKey(
                                  'known-spell-${spell.selectionKey}',
                                ),
                                dense: true,
                                title: Text(spell.spellName),
                                subtitle: Text('Level ${spell.level}'),
                                trailing: isDivine
                                    ? null
                                    : IconButton(
                                        tooltip: 'Remove ${spell.spellName}',
                                        icon: const Icon(
                                          Icons.close,
                                          size: 18,
                                        ),
                                        onPressed: () => onChanged(
                                          character.spells
                                              .where(
                                                (key) =>
                                                    key != spell.selectionKey,
                                              )
                                              .toList(),
                                        ),
                                      ),
                              ),
                          ],
                        ),
                ),
                if (!isDivine) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: ValueKey(
                      'add-known-spell-${className.toLowerCase()}',
                    ),
                    onPressed: availableToAdd.isEmpty
                        ? null
                        : () => _addSpells(context, className, availableToAdd),
                    icon: const Icon(Icons.add),
                    label: const Text('Add spell'),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ],
    ],
  );
}

class _SelectReferenceSpellsDialog extends StatefulWidget {
  const _SelectReferenceSpellsDialog({
    required this.className,
    required this.items,
  });

  final String className;
  final List<SpellReferenceItem> items;

  @override
  State<_SelectReferenceSpellsDialog> createState() =>
      _SelectReferenceSpellsDialogState();
}

class _SelectReferenceSpellsDialogState
    extends State<_SelectReferenceSpellsDialog> {
  final Set<String> _selected = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.items
        .where(
          (spell) =>
              _query.isEmpty ||
              spell.spellName.toLowerCase().contains(_query.toLowerCase()) ||
              spell.level.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return AlertDialog(
      title: Text('Add ${widget.className} spells'),
      content: SizedBox(
        width: 440,
        height: 420,
        child: Column(
          children: [
            TextField(
              key: const ValueKey('spell-reference-picker-filter'),
              decoration: const InputDecoration(
                labelText: 'Filter spells',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visibleItems.isEmpty
                  ? const Center(
                      child: Text('No matching spells in the reference data.'),
                    )
                  : ListView(
                      children: [
                        for (final spell in visibleItems)
                          CheckboxListTile(
                            key: ValueKey(
                              'select-reference-spell-${spell.selectionKey}',
                            ),
                            value: _selected.contains(spell.selectionKey),
                            title: Text(spell.spellName),
                            subtitle: Text('Level ${spell.level}'),
                            onChanged: (selected) => setState(() {
                              if (selected ?? false) {
                                _selected.add(spell.selectionKey);
                              } else {
                                _selected.remove(spell.selectionKey);
                              }
                            }),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selected.toList()),
          child: Text('Add selected (${_selected.length})'),
        ),
      ],
    );
  }
}

class _SpellSlotsTable extends StatelessWidget {
  const _SpellSlotsTable({
    super.key,
    required this.className,
    required this.level,
  });

  final String className;
  final int level;

  @override
  Widget build(BuildContext context) {
    final slots = _spellSlotsForClassLevel(className, level);
    final columns = [
      'Character Level',
      '0',
      '1st',
      '2nd',
      '3rd',
      '4th',
      '5th',
      '6th',
      '7th',
      '8th',
      '9th',
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            for (final column in columns) DataColumn(label: Text(column)),
          ],
          rows: [
            DataRow(
              key: ValueKey('spell-slots-level-$level'),
              cells: [
                DataCell(Text('$level')),
                for (final count in slots) DataCell(Text('$count')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    required this.emptyLabel,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> items;
  final String emptyLabel;
  final ValueChanged<List<String>> onChanged;

  Future<void> _add(BuildContext context) async {
    final value = await _askForText(
      context,
      'Add $title item',
      'Name or details',
    );
    if (value == null || value.isEmpty) return;
    onChanged([...items, value]);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Eyebrow('CHARACTER DETAILS'),
      const SizedBox(height: 8),
      _PageTitle(title),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(color: _muted)),
      const SizedBox(height: 22),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 34),
                  child: Column(
                    children: [
                      Icon(icon, size: 34, color: _muted),
                      const SizedBox(height: 10),
                      Text(emptyLabel, style: const TextStyle(color: _muted)),
                    ],
                  ),
                )
              else
                for (var index = 0; index < items.length; index++)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEAF0E9),
                      foregroundColor: _forest,
                      child: Icon(icon, size: 18),
                    ),
                    title: Text(items[index]),
                    trailing: IconButton(
                      tooltip: 'Remove ${items[index]}',
                      onPressed: () => onChanged([
                        for (var i = 0; i < items.length; i++)
                          if (i != index) items[i],
                      ]),
                      icon: const Icon(Icons.close, size: 19),
                    ),
                  ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: Text('Add ${title == 'Spellbook' ? 'spell' : 'item'}'),
      ),
    ],
  );
}

class _GearSection extends StatelessWidget {
  const _GearSection({
    required this.character,
    required this.gearItems,
    required this.onChanged,
  });

  final CharacterSheet character;
  final List<GearReferenceItem> gearItems;
  final ValueChanged<CharacterSheet> onChanged;

  void _updateGear(List<EquippedGearItem> equippedGear) {
    final armor = equippedGear.where((item) => item.category == 'Armor');
    final selectedArmor = armor.isEmpty ? null : armor.first;
    onChanged(
      character.copyWith(
        equippedGear: equippedGear,
        armorName: selectedArmor?.name ?? '',
        armorModifier: selectedArmor?.baseModifier ?? 0,
      ),
    );
  }

  void _addGear(GearReferenceItem item) {
    final equipped = [
      ...character.equippedGear.where(
        (selected) =>
            !(['Armor', 'Helms', 'Shield'].contains(item.category) &&
                selected.category == item.category),
      ),
      EquippedGearItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        category: item.category,
        name: item.name,
        baseModifier: item.armorModifier ?? 0,
        shieldAc: item.shieldAc ?? 0,
        foes: item.foes ?? 0,
        helmAc: item.helmAc ?? 0,
        vs: item.vs,
        encumbrance: item.encumbrance,
        worn: item.worn,
        capacity: item.capacity,
        attackType: item.attackType,
      ),
    ];
    _updateGear(equipped);
  }

  void _updateEquippedGear(EquippedGearItem updated) {
    _updateGear([
      for (final item in character.equippedGear)
        if (item.id == updated.id) updated else item,
    ]);
  }

  void _removeGear(EquippedGearItem item) {
    _updateGear(
      character.equippedGear
          .where((selected) => selected.id != item.id)
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Eyebrow('CHARACTER DETAILS'),
      const SizedBox(height: 8),
      const _PageTitle('Gear & notes'),
      const SizedBox(height: 6),
      const Text(
        'Keep track of what you carry and the details of your journey.',
        style: TextStyle(color: _muted),
      ),
      const SizedBox(height: 22),
      for (final category in _gearCategories) ...[
        _SectionHeading(title: category),
        const SizedBox(height: 8),
        _EquippedGearCategory(
          category: category,
          options: gearItems
              .where((item) => item.category == category)
              .toList(),
          selected: character.equippedGear
              .where((item) => item.category == category)
              .toList(),
          onAdd: _addGear,
          onUpdate: _updateEquippedGear,
          onRemove: _removeGear,
        ),
        const SizedBox(height: 18),
      ],
      _ListSection(
        title: 'Equipment',
        subtitle: 'Weapons, armor, treasure, and other carried items.',
        icon: Icons.backpack_outlined,
        items: character.equipment,
        emptyLabel: 'Your inventory is empty.',
        onChanged: (equipment) =>
            onChanged(character.copyWith(equipment: equipment)),
      ),
      const SizedBox(height: 24),
      const _SectionHeading(title: 'Adventure notes'),
      const SizedBox(height: 12),
      _NotesCard(
        initialValue: character.notes,
        onChanged: (notes) => onChanged(character.copyWith(notes: notes)),
      ),
    ],
  );
}

class _EquippedGearCategory extends StatelessWidget {
  const _EquippedGearCategory({
    required this.category,
    required this.options,
    required this.selected,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
  });

  final String category;
  final List<GearReferenceItem> options;
  final List<EquippedGearItem> selected;
  final ValueChanged<GearReferenceItem> onAdd;
  final ValueChanged<EquippedGearItem> onUpdate;
  final ValueChanged<EquippedGearItem> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (options.isNotEmpty)
        DropdownButtonFormField<String>(
          key: ValueKey(
            'add-equipped-$category-${selected.map((item) => item.id).join('-')}',
          ),
          isExpanded: true,
          initialValue: null,
          decoration: InputDecoration(labelText: 'Add $category'),
          hint: Text('Choose ${category.toLowerCase()}'),
          items: [
            for (final item in options)
              DropdownMenuItem(
                value: item.name,
                child: Text(
                  category == 'Armor'
                      ? '${item.name} (+${item.armorModifier ?? 0} AC)'
                      : category == 'Shield'
                      ? '${item.name} (+${item.shieldAc ?? 0} AC, ${item.foes ?? 0} foes)'
                      : category == 'Helms'
                      ? '${item.name} (AC ${item.helmAc ?? 0}, ${item.vs})'
                      : category == 'Containers'
                      ? '${item.name} (${item.capacity} capacity)'
                      : item.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (name) {
            if (name == null) return;
            for (final item in options) {
              if (item.name == name) {
                onAdd(item);
                break;
              }
            }
          },
        )
      else
        Text(
          'Add items from Reference Data > Gear > $category.',
          style: const TextStyle(color: _muted),
        ),
      if (selected.isNotEmpty) ...[
        const SizedBox(height: 8),
        for (final item in selected)
          _EquippedGearTile(
            item: item,
            onUpdate: onUpdate,
            onRemove: () => onRemove(item),
          ),
      ],
    ],
  );
}

class _EquippedGearTile extends StatelessWidget {
  const _EquippedGearTile({
    required this.item,
    required this.onUpdate,
    required this.onRemove,
  });

  final EquippedGearItem item;
  final ValueChanged<EquippedGearItem> onUpdate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (item.category == 'Weapons')
                  Text(item.attackType, style: const TextStyle(color: _muted)),
                if (item.category == 'Armor')
                  Text(
                    'Base AC modifier: ${item.baseModifier}',
                    style: const TextStyle(color: _muted),
                  ),
                if (item.category == 'Shield')
                  Text(
                    'AC +${item.shieldAc} · ${item.foes} foes',
                    style: const TextStyle(color: _muted),
                  ),
                if (item.category == 'Helms')
                  Text(
                    'AC ${item.helmAc} · ${item.vs}',
                    style: const TextStyle(color: _muted),
                  ),
                if (item.category == 'Equipment' ||
                    item.category == 'Containers')
                  Text(
                    [
                      if (item.encumbrance.isNotEmpty)
                        'Enc ${item.encumbrance}',
                      if (item.worn) 'Worn',
                      if (item.category == 'Containers' &&
                          item.capacity.isNotEmpty)
                        'Capacity ${item.capacity}',
                    ].join(' · '),
                    style: const TextStyle(color: _muted),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                key: ValueKey('magical-${item.id}'),
                value: item.magical,
                onChanged: (value) =>
                    onUpdate(item.copyWith(magical: value ?? false)),
              ),
              const Text('Magical?'),
              if (item.magical) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 92,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('magic-modifier-${item.id}'),
                    isExpanded: true,
                    initialValue: item.magicModifier,
                    decoration: const InputDecoration(
                      labelText: 'Magic',
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    items: [
                      for (var modifier = -5; modifier <= 5; modifier++)
                        DropdownMenuItem(
                          value: modifier,
                          child: Text(
                            modifier > 0 ? '+$modifier' : '$modifier',
                          ),
                        ),
                    ],
                    onChanged: (modifier) {
                      if (modifier != null) {
                        onUpdate(item.copyWith(magicModifier: modifier));
                      }
                    },
                  ),
                ),
              ],
              IconButton(
                tooltip: 'Remove ${item.name}',
                onPressed: onRemove,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _ReferenceDataSection extends StatelessWidget {
  const _ReferenceDataSection({
    required this.races,
    required this.classes,
    required this.onAddRace,
    required this.onAddClass,
    required this.onRemoveRace,
    required this.onRemoveClass,
    required this.onOpenRace,
    required this.onOpenClass,
    required this.onOpenGear,
    required this.onOpenSpells,
  });

  final List<String> races;
  final List<String> classes;
  final VoidCallback onAddRace;
  final VoidCallback onAddClass;
  final ValueChanged<String> onRemoveRace;
  final ValueChanged<String> onRemoveClass;
  final ValueChanged<String> onOpenRace;
  final ValueChanged<String> onOpenClass;
  final ValueChanged<String> onOpenGear;
  final VoidCallback onOpenSpells;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _Eyebrow('YOUR CAMPAIGN LIBRARY'),
      const SizedBox(height: 8),
      const _PageTitle('Reference data'),
      const SizedBox(height: 6),
      const Text(
        'Manage campaign races, classes, gear, and spells. Race and class '
        'options are available when you create or edit a character.',
        style: TextStyle(color: _muted, height: 1.5),
      ),
      const SizedBox(height: 22),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 700 ? 2 : 1;
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: columns == 2 ? 1.2 : 1.4,
            children: [
              _ReferenceListCard(
                title: 'Races',
                icon: Icons.groups_outlined,
                items: races,
                onAdd: onAddRace,
                onRemove: onRemoveRace,
                onOpen: onOpenRace,
              ),
              _ReferenceListCard(
                title: 'Classes',
                icon: Icons.military_tech_outlined,
                items: classes,
                onAdd: onAddClass,
                onRemove: onRemoveClass,
                onOpen: onOpenClass,
              ),
              _GearCategoryCard(onOpen: onOpenGear),
              _SpellReferenceCard(onOpen: onOpenSpells),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: _forest),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Reference data is stored on this device. Removing an option '
                  'does not erase it from characters that already use it.',
                  style: TextStyle(color: _muted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _GearCategoryCard extends StatelessWidget {
  const _GearCategoryCard({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.backpack_outlined, color: _forest, size: 20),
              SizedBox(width: 9),
              Text(
                'Gear',
                style: TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final category in _gearCategories)
                ActionChip(
                  key: ValueKey('gear-category-$category'),
                  label: Text(category),
                  onPressed: () => onOpen(category),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SpellReferenceCard extends StatelessWidget {
  const _SpellReferenceCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      key: const ValueKey('spell-reference-card'),
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, color: _forest, size: 20),
                SizedBox(width: 9),
                Text(
                  'Spells',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Divider(height: 25),
            Text(
              'Create and manage your campaign spell reference.',
              style: TextStyle(color: _muted, height: 1.5),
            ),
          ],
        ),
      ),
    ),
  );
}

class _GearReferenceDetailPage extends StatelessWidget {
  const _GearReferenceDetailPage({
    required this.category,
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final String category;
  final List<GearReferenceItem> items;
  final VoidCallback onAdd;
  final ValueChanged<GearReferenceItem> onEdit;
  final ValueChanged<GearReferenceItem> onRemove;

  @override
  Widget build(BuildContext context) {
    final isArmor = category == 'Armor';
    final isShield = category == 'Shield';
    final isHelm = category == 'Helms';
    final isEquipment = category == 'Equipment';
    final isContainer = category == 'Containers';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('GEAR REFERENCE'),
        const SizedBox(height: 8),
        _PageTitle(category),
        const SizedBox(height: 22),
        if (items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'No $category items yet. Add one to build this table.',
                style: const TextStyle(color: _muted),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                key: ValueKey('gear-table-$category'),
                columns: [
                  DataColumn(
                    label: Text(
                      isArmor
                          ? 'Armor'
                          : isShield
                          ? 'Shield'
                          : isHelm
                          ? 'Helm'
                          : isContainer
                          ? 'Container'
                          : 'Name',
                    ),
                  ),
                  if (isArmor) const DataColumn(label: Text('AC Modifier')),
                  if (isShield) const DataColumn(label: Text('AC')),
                  if (isShield) const DataColumn(label: Text('# of Foes')),
                  if (isHelm) const DataColumn(label: Text('AC')),
                  if (isHelm) const DataColumn(label: Text('Vs')),
                  if (isEquipment || isContainer)
                    const DataColumn(label: Text('Enc')),
                  if (isEquipment || isContainer)
                    const DataColumn(label: Text('Worn')),
                  if (isContainer) const DataColumn(label: Text('Capacity')),
                  if (category == 'Weapons')
                    const DataColumn(label: Text('Damage')),
                  if (category == 'Weapons')
                    const DataColumn(label: Text('Special')),
                  if (category == 'Weapons')
                    const DataColumn(label: Text('Attack type')),
                  const DataColumn(label: Text('')),
                ],
                rows: [
                  for (final item in items)
                    DataRow(
                      key: ValueKey('gear-row-${item.category}-${item.name}'),
                      cells: [
                        DataCell(Text(item.name)),
                        if (isArmor)
                          DataCell(Text('${item.armorModifier ?? 0}')),
                        if (isShield) DataCell(Text('${item.shieldAc ?? 0}')),
                        if (isShield) DataCell(Text('${item.foes ?? 0}')),
                        if (isHelm) DataCell(Text('${item.helmAc ?? 0}')),
                        if (isHelm)
                          DataCell(Text(item.vs.isEmpty ? '—' : item.vs)),
                        if (isEquipment || isContainer)
                          DataCell(
                            Text(
                              item.encumbrance.isEmpty ? '—' : item.encumbrance,
                            ),
                          ),
                        if (isEquipment || isContainer)
                          DataCell(Text(item.worn ? 'W' : '—')),
                        if (isContainer)
                          DataCell(
                            Text(item.capacity.isEmpty ? '—' : item.capacity),
                          ),
                        if (category == 'Weapons')
                          DataCell(
                            Text(item.damage.isEmpty ? '—' : item.damage),
                          ),
                        if (category == 'Weapons')
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: Text(
                                item.special.isEmpty ? '—' : item.special,
                              ),
                            ),
                          ),
                        if (category == 'Weapons')
                          DataCell(Text(item.attackType)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Edit ${item.name}',
                                onPressed: () => onEdit(item),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                              ),
                              IconButton(
                                tooltip: 'Remove ${item.name}',
                                onPressed: () => onRemove(item),
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          key: ValueKey('add-gear-$category'),
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: Text('Add $category item'),
        ),
      ],
    );
  }
}

class _SpellReferenceDetailPage extends StatefulWidget {
  const _SpellReferenceDetailPage({
    required this.items,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
  });

  final List<SpellReferenceItem> items;
  final VoidCallback onAdd;
  final ValueChanged<SpellReferenceItem> onEdit;
  final ValueChanged<SpellReferenceItem> onRemove;

  @override
  State<_SpellReferenceDetailPage> createState() =>
      _SpellReferenceDetailPageState();
}

class _SpellReferenceDetailPageState extends State<_SpellReferenceDetailPage> {
  static const _columns = [
    'Spell Name',
    'Class',
    'Level',
    'CT',
    'R',
    'D',
    'SV',
    'SR',
    'Comp',
  ];

  static const _filters = [
    'spellName',
    'characterClass',
    'level',
    'castingTime',
    'range',
    'duration',
    'savingThrow',
    'spellResistance',
    'components',
  ];

  final Map<String, String> _filterValues = {};

  List<String> _spellValues(SpellReferenceItem item) => [
    item.spellName,
    item.characterClass,
    item.level,
    item.castingTime,
    item.range,
    item.duration,
    item.savingThrow,
    item.spellResistance,
    item.components,
  ];

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      final values = _spellValues(item);
      for (var index = 0; index < _filters.length; index++) {
        final filter = _filterValues[_filters[index]]?.trim().toLowerCase();
        if (filter != null &&
            filter.isNotEmpty &&
            !values[index].toLowerCase().contains(filter)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('SPELL REFERENCE'),
        const SizedBox(height: 8),
        const _PageTitle('Spells'),
        const SizedBox(height: 6),
        const Text(
          'Manage campaign spell details independently from character spellbooks.',
          style: TextStyle(color: _muted),
        ),
        const SizedBox(height: 22),
        Card(
          child: widget.items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No spell reference entries yet.',
                      style: TextStyle(color: _muted),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    key: const ValueKey('spell-reference-table'),
                    headingRowHeight: 88,
                    columns: [
                      for (var index = 0; index < _columns.length; index++)
                        DataColumn(
                          label: SizedBox(
                            width: 110,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _columns[index],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  key: ValueKey(
                                    'filter-spell-${_filters[index]}',
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Filter',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => setState(
                                    () =>
                                        _filterValues[_filters[index]] = value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const DataColumn(label: Text('')),
                    ],
                    rows: [
                      for (final item in filteredItems)
                        DataRow(
                          cells: [
                            DataCell(Text(item.spellName)),
                            DataCell(Text(item.characterClass)),
                            DataCell(Text(item.level)),
                            DataCell(Text(item.castingTime)),
                            DataCell(Text(item.range)),
                            DataCell(Text(item.duration)),
                            DataCell(Text(item.savingThrow)),
                            DataCell(Text(item.spellResistance)),
                            DataCell(Text(item.components)),
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit ${item.spellName}',
                                    onPressed: () => widget.onEdit(item),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove ${item.spellName}',
                                    onPressed: () => widget.onRemove(item),
                                    icon: const Icon(Icons.close, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
        ),
        if (widget.items.isNotEmpty && filteredItems.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'No spells match these filters.',
              style: TextStyle(color: _muted),
            ),
          ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          key: const ValueKey('add-spell-reference'),
          onPressed: widget.onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add spell'),
        ),
      ],
    );
  }
}

class _SpellReferenceDialog extends StatefulWidget {
  const _SpellReferenceDialog({this.initialItem});

  final SpellReferenceItem? initialItem;

  @override
  State<_SpellReferenceDialog> createState() => _SpellReferenceDialogState();
}

class _SpellReferenceDialogState extends State<_SpellReferenceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;

  static const _fields = [
    ('Spell Name', true),
    ('Class', true),
    ('Level', true),
    ('CT', false),
    ('R', false),
    ('D', false),
    ('SV', false),
    ('SR', false),
    ('Comp', false),
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _controllers = [
      TextEditingController(text: item?.spellName ?? ''),
      TextEditingController(text: item?.characterClass ?? ''),
      TextEditingController(text: item?.level ?? ''),
      TextEditingController(text: item?.castingTime ?? ''),
      TextEditingController(text: item?.range ?? ''),
      TextEditingController(text: item?.duration ?? ''),
      TextEditingController(text: item?.savingThrow ?? ''),
      TextEditingController(text: item?.spellResistance ?? ''),
      TextEditingController(text: item?.components ?? ''),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final values = _controllers
        .map((controller) => controller.text.trim())
        .toList();
    Navigator.of(context).pop(
      SpellReferenceItem(
        spellName: values[0],
        characterClass: values[1],
        level: values[2],
        castingTime: values[3],
        range: values[4],
        duration: values[5],
        savingThrow: values[6],
        spellResistance: values[7],
        components: values[8],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initialItem == null ? 'Add spell' : 'Edit spell'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < _fields.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _controllers[index],
                    decoration: InputDecoration(
                      labelText: _fields[index].$1,
                      border: const OutlineInputBorder(),
                    ),
                    validator: _fields[index].$2
                        ? (value) => value == null || value.trim().isEmpty
                              ? 'Required'
                              : null
                        : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );
}

class _GearItemDialog extends StatefulWidget {
  const _GearItemDialog({required this.category, this.initialItem});

  final String category;
  final GearReferenceItem? initialItem;

  @override
  State<_GearItemDialog> createState() => _GearItemDialogState();
}

class _GearItemDialogState extends State<_GearItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _armorModifier;
  late final TextEditingController _shieldAc;
  late final TextEditingController _foes;
  late final TextEditingController _helmAc;
  late final TextEditingController _vs;
  late final TextEditingController _encumbrance;
  late final TextEditingController _capacity;
  late bool _worn;
  late final TextEditingController _damage;
  late final TextEditingController _special;
  late String _attackType;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialItem?.name ?? '');
    _armorModifier = TextEditingController(
      text: '${widget.initialItem?.armorModifier ?? ''}',
    );
    _shieldAc = TextEditingController(
      text: '${widget.initialItem?.shieldAc ?? 0}',
    );
    _foes = TextEditingController(text: '${widget.initialItem?.foes ?? 0}');
    _helmAc = TextEditingController(text: '${widget.initialItem?.helmAc ?? 0}');
    _vs = TextEditingController(text: widget.initialItem?.vs ?? '');
    _encumbrance = TextEditingController(
      text: widget.initialItem?.encumbrance ?? '',
    );
    _capacity = TextEditingController(text: widget.initialItem?.capacity ?? '');
    _worn = widget.initialItem?.worn ?? false;
    _damage = TextEditingController(text: widget.initialItem?.damage ?? '');
    _special = TextEditingController(text: widget.initialItem?.special ?? '');
    _attackType =
        widget.initialItem?.attackType ??
        _inferWeaponAttackType(widget.initialItem?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _armorModifier.dispose();
    _shieldAc.dispose();
    _foes.dispose();
    _helmAc.dispose();
    _vs.dispose();
    _encumbrance.dispose();
    _capacity.dispose();
    _damage.dispose();
    _special.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      GearReferenceItem(
        category: widget.category,
        name: _name.text.trim(),
        armorModifier: widget.category == 'Armor'
            ? int.parse(_armorModifier.text.trim())
            : null,
        shieldAc: widget.category == 'Shield'
            ? int.parse(_shieldAc.text.trim())
            : null,
        foes: widget.category == 'Shield' ? int.parse(_foes.text.trim()) : null,
        helmAc: widget.category == 'Helms'
            ? int.parse(_helmAc.text.trim())
            : null,
        vs: widget.category == 'Helms' ? _vs.text.trim() : '',
        encumbrance:
            widget.category == 'Equipment' || widget.category == 'Containers'
            ? _encumbrance.text.trim()
            : '',
        worn:
            (widget.category == 'Equipment' ||
                widget.category == 'Containers') &&
            _worn,
        capacity: widget.category == 'Containers' ? _capacity.text.trim() : '',
        attackType: _attackType,
        damage: widget.category == 'Weapons' ? _damage.text.trim() : '',
        special: widget.category == 'Weapons' ? _special.text.trim() : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      '${widget.initialItem == null ? 'Add' : 'Edit'} ${widget.category} item',
    ),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const ValueKey('gear-item-name'),
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: widget.category == 'Armor'
                  ? 'Armor name'
                  : 'Item name',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a name' : null,
          ),
          if (widget.category == 'Armor')
            TextFormField(
              key: const ValueKey('gear-armor-modifier'),
              controller: _armorModifier,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'AC modifier'),
              validator: (value) => int.tryParse(value ?? '') == null
                  ? 'Enter a whole number'
                  : null,
            ),
          if (widget.category == 'Shield') ...[
            TextFormField(
              key: const ValueKey('gear-shield-ac'),
              controller: _shieldAc,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'AC'),
              validator: (value) => int.tryParse(value ?? '') == null
                  ? 'Enter a whole number'
                  : null,
            ),
            TextFormField(
              key: const ValueKey('gear-shield-foes'),
              controller: _foes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '# of Foes'),
              validator: (value) => int.tryParse(value ?? '') == null
                  ? 'Enter a whole number'
                  : null,
            ),
          ],
          if (widget.category == 'Helms') ...[
            TextFormField(
              key: const ValueKey('gear-helm-ac'),
              controller: _helmAc,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'AC'),
              validator: (value) => int.tryParse(value ?? '') == null
                  ? 'Enter a whole number'
                  : null,
            ),
            TextFormField(
              key: const ValueKey('gear-helm-vs'),
              controller: _vs,
              decoration: const InputDecoration(labelText: 'Vs'),
            ),
          ],
          if (widget.category == 'Equipment' ||
              widget.category == 'Containers') ...[
            TextFormField(
              key: const ValueKey('gear-encumbrance'),
              controller: _encumbrance,
              decoration: const InputDecoration(labelText: 'Enc'),
            ),
            CheckboxListTile(
              key: const ValueKey('gear-item-worn'),
              value: _worn,
              contentPadding: EdgeInsets.zero,
              title: const Text('Worn'),
              onChanged: (value) => setState(() => _worn = value ?? false),
            ),
          ],
          if (widget.category == 'Containers')
            TextFormField(
              key: const ValueKey('gear-container-capacity'),
              controller: _capacity,
              decoration: const InputDecoration(labelText: 'Capacity'),
            ),
          if (widget.category == 'Weapons')
            TextFormField(
              key: const ValueKey('gear-weapon-damage'),
              controller: _damage,
              decoration: const InputDecoration(labelText: 'Damage'),
            ),
          if (widget.category == 'Weapons')
            TextFormField(
              key: const ValueKey('gear-weapon-special'),
              controller: _special,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Special'),
            ),
          if (widget.category == 'Weapons')
            DropdownButtonFormField<String>(
              key: const ValueKey('gear-weapon-attack-type'),
              initialValue: _attackType,
              decoration: const InputDecoration(labelText: 'Attack type'),
              items: const [
                DropdownMenuItem(value: 'Melee', child: Text('Melee')),
                DropdownMenuItem(value: 'Ranged', child: Text('Ranged')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _attackType = value);
              },
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _save,
        child: Text(widget.initialItem == null ? 'Add' : 'Save'),
      ),
    ],
  );
}

class _ReferenceListCard extends StatelessWidget {
  const _ReferenceListCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    required this.onOpen,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _forest, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${items.length}',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
          const Divider(height: 25),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      'No options yet. Add one to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  )
                : ListView(
                    children: [
                      for (final item in items)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(item),
                          onTap: () => onOpen(item),
                          trailing: IconButton(
                            tooltip: 'Remove $item',
                            onPressed: () => onRemove(item),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add ${title == 'Races' ? 'Race' : 'Class'}'),
          ),
        ],
      ),
    ),
  );
}

class _RaceReferenceDetails {
  const _RaceReferenceDetails(
    this.baseMove,
    this.attributeModifiers,
    this.classModifiers,
  );

  final int baseMove;
  final String attributeModifiers;
  final String classModifiers;
}

const _raceReferenceDetails = <String, _RaceReferenceDetails>{
  'Dwarf': _RaceReferenceDetails(
    20,
    '+1 CON, -1 DEX',
    'Rogue/Assassin: +2 Find Traps (structures only)',
  ),
  'Elf': _RaceReferenceDetails(
    30,
    '+1 DEX, -1 CON',
    'Ranger: +2 Move Silent, +2 Find Traps\n'
        'Rogue/Assassin: +2 Listen, +2 Move Silent, +2 Find Traps',
  ),
  'Gnome': _RaceReferenceDetails(
    20,
    '+1 INT, -1 STR',
    'Rogue/Assassin: +3 Listen',
  ),
  'Half-Elf': _RaceReferenceDetails(
    30,
    'Human Lineage: None\nElf Lineage: +1 DEX, -1 CON',
    'Ranger: +2 Move Silent, +2 Find Traps\n'
        'Rogue/Assassin: +2 Find Traps, +2 Move Silent\n'
        'Elf Lineage: +2 Listen',
  ),
  'Halfling': _RaceReferenceDetails(
    20,
    '+1 DEX, -1 STR',
    'Ranger: +2 Conceal, +2 Move Silent\n'
        'Rogue/Assassin: +2 Hide, +2 Move Silent',
  ),
  'Half-Orc': _RaceReferenceDetails(
    30,
    '+1 CON, +1 STR, -2 CHA',
    'Ranger: +2 Track',
  ),
  'Human': _RaceReferenceDetails(30, 'None', 'None'),
};

Map<String, int> _raceAttributeModifiers(String race, String lineage) {
  final normalizedRace = race.trim().toLowerCase();
  final modifiers = switch (normalizedRace) {
    'dwarf' => {'Constitution': 1, 'Dexterity': -1},
    'elf' => {'Dexterity': 1, 'Constitution': -1},
    'gnome' => {'Intelligence': 1, 'Strength': -1},
    'half-elf' when lineage.trim().toLowerCase() == 'elf' => {
      'Dexterity': 1,
      'Constitution': -1,
    },
    'halfling' => {'Dexterity': 1, 'Strength': -1},
    'half-orc' => {'Constitution': 1, 'Strength': 1, 'Charisma': -2},
    _ => const <String, int>{},
  };
  return {
    for (final ability in CharacterSheet.abilityNames)
      ability: modifiers[ability] ?? 0,
  };
}

const _classProgressions = <String, List<List<String>>>{
  'assassin': [
    ['1', 'd6', '-', '-'],
    ['2', 'd6', '1', '1,751'],
    ['3', 'd6', '1', '3,501'],
    ['4', 'd6', '1', '7,001'],
    ['5', 'd6', '2', '14,001'],
    ['6', 'd6', '2', '25,001'],
    ['7', 'd6', '2', '50,001'],
    ['8', 'd6', '3', '90,001'],
    ['9', 'd6', '3', '150,001'],
    ['10', 'd6', '3', '200,001'],
    ['11', '2', '4', '350,001'],
    ['12', '2', '4', '500,001'],
    ['13', '2', '4', '650,001'],
    ['14', '2', '4', '800,001'],
    ['15', '2', '4', '950,001'],
    ['16', '2', '4', '1,100,001'],
    ['17', '2', '4', '1,250,001'],
    ['18', '2', '4', '1,400,001'],
    ['19', '2', '4', '1,550,001'],
    ['20', '2', '4', '1,700,001'],
  ],
  'barbarian': [
    ['1', 'd12', '-', '0'],
    ['2', 'd12', '1', '2,101'],
    ['3', 'd12', '2', '4,701'],
    ['4', 'd12', '3', '9,401'],
    ['5', 'd12', '4', '20,001'],
    ['6', 'd12', '5', '40,001'],
    ['7', 'd12', '6', '80,001'],
    ['8', 'd12', '7', '170,001'],
    ['9', 'd12', '8', '340,001'],
    ['10', 'd12', '9', '600,001'],
    ['11', '5', '10', '800,001'],
    ['12', '5', '11', '1,000,001'],
    ['13', '2', '4', '1,200,001'],
    ['14', '2', '4', '1,400,001'],
    ['15', '2', '4', '1,600,001'],
    ['16', '2', '4', '1,800,001'],
    ['17', '2', '4', '2,000,001'],
    ['18', '2', '4', '2,200,001'],
    ['19', '2', '4', '2,400,001'],
    ['20', '2', '4', '2,600,001'],
  ],
  'bard': [
    ['1', 'd10', '-', '0'],
    ['2', 'd10', '1', '1,501'],
    ['3', 'd10', '2', '3,251'],
    ['4', 'd10', '3', '7,501'],
    ['5', 'd10', '4', '15,001'],
    ['6', 'd10', '5', '30,001'],
    ['7', 'd10', '6', '60,001'],
    ['8', 'd10', '7', '120,001'],
    ['9', 'd10', '8', '240,001'],
    ['10', 'd10', '9', '450,001'],
    ['11', '4', '10', '625,001'],
    ['12', '4', '11', '800,001'],
    ['13', '4', '11', '975,001'],
    ['14', '4', '11', '1,150,001'],
    ['15', '4', '11', '1,325,001'],
    ['16', '4', '11', '1,500,001'],
    ['17', '4', '11', '1,675,001'],
    ['18', '4', '11', '1,850,001'],
    ['19', '4', '11', '2,025,001'],
    ['20', '4', '11', '2,200,001'],
  ],
  'cleric': [
    ['1', 'd8', '-', '0'],
    ['2', 'd8', '1', '2,251'],
    ['3', 'd8', '1', '5,001'],
    ['4', 'd8', '2', '9,001'],
    ['5', 'd8', '2', '18,001'],
    ['6', 'd8', '3', '35,001'],
    ['7', 'd8', '3', '70,001'],
    ['8', 'd8', '4', '140,001'],
    ['9', 'd8', '4', '300,001'],
    ['10', 'd8', '5', '425,001'],
    ['11', '3', '5', '650,001'],
    ['12', '3', '6', '900,001'],
    ['13', '3', '6', '1,150,001'],
    ['14', '3', '6', '1,400,001'],
    ['15', '3', '6', '1,650,001'],
    ['16', '3', '6', '1,900,001'],
    ['17', '3', '6', '2,150,001'],
    ['18', '3', '6', '2,400,001'],
    ['19', '3', '6', '2,650,001'],
    ['20', '3', '6', '2,900,001'],
  ],
  'druid': [
    ['1', 'd8', '-', '0'],
    ['2', 'd8', '1', '2,001'],
    ['3', 'd8', '1', '4,251'],
    ['4', 'd8', '2', '8,501'],
    ['5', 'd8', '2', '17,001'],
    ['6', 'd8', '3', '35,001'],
    ['7', 'd8', '3', '70,001'],
    ['8', 'd8', '4', '180,001'],
    ['9', 'd8', '4', '275,001'],
    ['10', 'd8', '5', '400,001'],
    ['11', '3', '5', '525,001'],
    ['12', '3', '6', '650,001'],
    ['13', '3', '6', '825,001'],
    ['14', '3', '6', '1,000,001'],
    ['15', '3', '6', '1,175,001'],
    ['16', '3', '6', '1,350,001'],
    ['17', '3', '6', '1,525,001'],
    ['18', '3', '6', '1,700,001'],
    ['19', '3', '6', '1,875,001'],
    ['20', '3', '6', '2,050,001'],
  ],
  'fighter': [
    ['1', 'd10', '1', '0'],
    ['2', 'd10', '2', '2,001'],
    ['3', 'd10', '3', '4,001'],
    ['4', 'd10', '4', '8,501'],
    ['5', 'd10', '5', '17,001'],
    ['6', 'd10', '6', '34,001'],
    ['7', 'd10', '7', '68,001'],
    ['8', 'd10', '8', '136,001'],
    ['9', 'd10', '9', '272,001'],
    ['10', 'd10', '10', '500,001'],
    ['11', '4', '11', '750,001'],
    ['12', '4', '12', '1,000,001'],
    ['13', '4', '6', '1,250,001'],
    ['14', '4', '6', '1,500,001'],
    ['15', '4', '6', '1,750,001'],
    ['16', '4', '6', '2,000,001'],
    ['17', '4', '6', '2,250,001'],
    ['18', '4', '6', '2,500,001'],
    ['19', '4', '6', '2,750,001'],
    ['20', '4', '6', '3,000,001'],
  ],
  'illusionist': [
    ['1', 'd4', '-', '0'],
    ['2', 'd4', '1', '2,601'],
    ['3', 'd4', '1', '5,201'],
    ['4', 'd4', '1', '10,401'],
    ['5', 'd4', '1', '20,801'],
    ['6', 'd4', '2', '42,501'],
    ['7', 'd4', '2', '85,001'],
    ['8', 'd4', '2', '170,001'],
    ['9', 'd4', '2', '340,001'],
    ['10', 'd4', '3', '500,001'],
    ['11', '1', '3', '750,001'],
    ['12', '1', '3', '900,001'],
    ['13', '1', '3', '1,050,001'],
    ['14', '1', '3', '1,200,001'],
    ['15', '1', '3', '1,350,001'],
    ['16', '1', '3', '1,500,001'],
    ['17', '1', '3', '1,650,001'],
    ['18', '1', '3', '1,800,001'],
    ['19', '1', '3', '1,950,001'],
    ['20', '1', '3', '2,100,001'],
  ],
  'knight': [
    ['1', 'd10', '-', '0'],
    ['2', 'd10', '1', '2,251'],
    ['3', 'd10', '2', '4,501'],
    ['4', 'd10', '3', '9,001'],
    ['5', 'd10', '4', '18,001'],
    ['6', 'd10', '5', '36,001'],
    ['7', 'd10', '6', '72,001'],
    ['8', 'd10', '7', '150,001'],
    ['9', 'd10', '8', '300,001'],
    ['10', 'd10', '9', '600,001'],
    ['11', '4', '10', '725,001'],
    ['12', '4', '11', '900,001'],
    ['13', '4', '11', '1,075,001'],
    ['14', '4', '11', '1,250,001'],
    ['15', '4', '11', '1,425,001'],
    ['16', '4', '11', '1,600,001'],
    ['17', '4', '11', '1,775,001'],
    ['18', '4', '11', '1,950,001'],
    ['19', '4', '11', '2,125,001'],
    ['20', '4', '11', '2,300,001'],
  ],
  'monk': [
    ['1', 'd12', '-', '0'],
    ['2', 'd12', '1', '1,751'],
    ['3', 'd12', '2', '4,001'],
    ['4', 'd12', '3', '8,501'],
    ['5', 'd12', '4', '20,001'],
    ['6', 'd12', '5', '40,001'],
    ['7', 'd12', '6', '80,001'],
    ['8', 'd12', '7', '160,001'],
    ['9', 'd12', '8', '325,001'],
    ['10', 'd12', '9', '550,001'],
    ['11', '5', '10', '750,001'],
    ['12', '5', '11', '1,250,001'],
    ['13', '5', '11', '1,500,001'],
    ['14', '5', '11', '1,750,001'],
    ['15', '5', '11', '2,000,001'],
    ['16', '5', '11', '2,250,001'],
    ['17', '5', '11', '2,500,001'],
    ['18', '5', '11', '2,750,001'],
    ['19', '5', '11', '3,000,001'],
    ['20', '5', '11', '3,250,001'],
  ],
  'paladin': [
    ['1', 'd10', '-', '0'],
    ['2', 'd10', '1', '2,701'],
    ['3', 'd10', '2', '5,501'],
    ['4', 'd10', '3', '12,001'],
    ['5', 'd10', '4', '24,001'],
    ['6', 'd10', '5', '48,001'],
    ['7', 'd10', '6', '95,001'],
    ['8', 'd10', '7', '180,001'],
    ['9', 'd10', '8', '360,001'],
    ['10', 'd10', '9', '700,001'],
    ['11', '4', '10', '1,000,001'],
    ['12', '4', '11', '1,300,001'],
    ['13', '4', '11', '1,600,001'],
    ['14', '4', '11', '1,900,001'],
    ['15', '4', '11', '2,200,001'],
    ['16', '4', '11', '2,500,001'],
    ['17', '4', '11', '2,800,001'],
    ['18', '4', '11', '3,100,001'],
    ['19', '4', '11', '3,400,001'],
    ['20', '4', '11', '3,700,001'],
  ],
  'ranger': [
    ['1', 'd10', '-', '0'],
    ['2', 'd10', '1', '2,251'],
    ['3', 'd10', '2', '4,501'],
    ['4', 'd10', '3', '9,001'],
    ['5', 'd10', '4', '18,001'],
    ['6', 'd10', '5', '40,001'],
    ['7', 'd10', '6', '75,001'],
    ['8', 'd10', '7', '150,001'],
    ['9', 'd10', '8', '250,001'],
    ['10', 'd10', '9', '500,001'],
    ['11', '4', '10', '725,001'],
    ['12', '4', '11', '950,001'],
    ['13', '4', '11', '1,175,001'],
    ['14', '4', '11', '1,400,001'],
    ['15', '4', '11', '1,625,001'],
    ['16', '4', '11', '1,850,001'],
    ['17', '4', '11', '2,075,001'],
    ['18', '4', '11', '2,300,001'],
    ['19', '4', '11', '2,525,001'],
    ['20', '4', '11', '2,750,001'],
  ],
  'rogue': [
    ['1', 'd6', '-', '0'],
    ['2', 'd6', '1', '1,251'],
    ['3', 'd6', '1', '2,501'],
    ['4', 'd6', '1', '6,001'],
    ['5', 'd6', '2', '12,001'],
    ['6', 'd6', '2', '24,001'],
    ['7', 'd6', '2', '48,001'],
    ['8', 'd6', '3', '80,001'],
    ['9', 'd6', '3', '120,001'],
    ['10', 'd6', '3', '175,001'],
    ['11', '2', '4', '325,001'],
    ['12', '2', '4', '450,001'],
    ['13', '2', '4', '575,001'],
    ['14', '2', '4', '700,001'],
    ['15', '2', '4', '825,001'],
    ['16', '2', '4', '950,001'],
    ['17', '2', '4', '1,075,001'],
    ['18', '2', '4', '1,200,001'],
    ['19', '2', '4', '1,325,001'],
    ['20', '2', '4', '1,450,001'],
  ],
  'wizard': [
    ['1', 'd4', '-', '0'],
    ['2', 'd4', '1', '2,601'],
    ['3', 'd4', '1', '5,201'],
    ['4', 'd4', '1', '10,401'],
    ['5', 'd4', '1', '20,801'],
    ['6', 'd4', '2', '42,501'],
    ['7', 'd4', '2', '85,001'],
    ['8', 'd4', '2', '170,001'],
    ['9', 'd4', '2', '340,001'],
    ['10', 'd4', '3', '500,001'],
    ['11', '1', '3', '750,001'],
    ['12', '1', '3', '1,000,001'],
    ['13', '1', '3', '1,250,001'],
    ['14', '1', '3', '1,500,001'],
    ['15', '1', '3', '1,750,001'],
    ['16', '1', '3', '2,000,001'],
    ['17', '1', '3', '2,250,001'],
    ['18', '1', '3', '2,500,001'],
    ['19', '1', '3', '2,750,001'],
    ['20', '1', '3', '3,000,001'],
  ],
};

const _clericDruidSpellsPerDay = <List<int>>[
  [3, 1, 0, 0, 0, 0, 0, 0, 0, 0],
  [4, 2, 0, 0, 0, 0, 0, 0, 0, 0],
  [4, 2, 1, 0, 0, 0, 0, 0, 0, 0],
  [4, 3, 2, 0, 0, 0, 0, 0, 0, 0],
  [4, 3, 2, 1, 0, 0, 0, 0, 0, 0],
  [5, 3, 3, 2, 0, 0, 0, 0, 0, 0],
  [5, 4, 3, 2, 1, 0, 0, 0, 0, 0],
  [5, 4, 3, 3, 2, 0, 0, 0, 0, 0],
  [5, 4, 4, 3, 2, 1, 0, 0, 0, 0],
  [5, 4, 4, 3, 3, 2, 0, 0, 0, 0],
  [6, 5, 4, 4, 3, 2, 1, 0, 0, 0],
  [6, 5, 4, 4, 3, 3, 2, 0, 0, 0],
  [6, 5, 5, 4, 4, 3, 2, 1, 0, 0],
  [6, 5, 5, 4, 4, 3, 3, 2, 0, 0],
  [6, 5, 5, 5, 4, 4, 3, 2, 1, 0],
  [6, 6, 5, 5, 4, 4, 3, 3, 2, 0],
  [7, 6, 5, 5, 5, 4, 4, 3, 2, 1],
  [7, 6, 6, 5, 5, 4, 4, 3, 3, 2],
  [7, 6, 6, 5, 5, 5, 4, 4, 3, 2],
  [7, 6, 6, 6, 5, 5, 4, 4, 3, 3],
];

bool _isSpellcastingReferenceClass(String name) =>
    const {'cleric', 'druid', 'illusionist', 'wizard'}.contains(
      name.trim().toLowerCase(),
    );

const _illusionistWizardSpellsPerDay = <List<int>>[
  [4, 2, 0, 0, 0, 0, 0, 0, 0, 0],
  [4, 3, 0, 0, 0, 0, 0, 0, 0, 0],
  [4, 3, 1, 0, 0, 0, 0, 0, 0, 0],
  [4, 3, 2, 0, 0, 0, 0, 0, 0, 0],
  [5, 4, 2, 1, 0, 0, 0, 0, 0, 0],
  [5, 4, 3, 2, 0, 0, 0, 0, 0, 0],
  [5, 4, 3, 2, 1, 0, 0, 0, 0, 0],
  [5, 4, 3, 3, 2, 0, 0, 0, 0, 0],
  [5, 5, 4, 3, 2, 1, 0, 0, 0, 0],
  [6, 5, 4, 3, 3, 2, 0, 0, 0, 0],
  [6, 5, 4, 4, 3, 2, 1, 0, 0, 0],
  [6, 5, 4, 4, 3, 3, 2, 0, 0, 0],
  [6, 5, 5, 4, 4, 3, 2, 1, 0, 0],
  [6, 6, 5, 4, 4, 3, 3, 2, 0, 0],
  [6, 6, 5, 5, 4, 4, 3, 2, 1, 0],
  [7, 6, 5, 5, 4, 4, 3, 3, 2, 0],
  [7, 6, 5, 5, 5, 4, 4, 3, 2, 1],
  [7, 6, 6, 5, 5, 4, 4, 3, 3, 2],
  [7, 6, 6, 5, 5, 5, 4, 4, 3, 2],
  [7, 7, 6, 6, 5, 5, 4, 4, 3, 3],
];

List<int> _spellSlotsForClassLevel(String className, int level) {
  final classLevel = className.trim().toLowerCase();
  final progression =
      classLevel == 'illusionist' || classLevel == 'wizard'
      ? _illusionistWizardSpellsPerDay
      : _clericDruidSpellsPerDay;
  return level < 1 || level > progression.length
      ? List<int>.filled(10, 0)
      : progression[level - 1];
}

class ReferenceDetailPage extends StatelessWidget {
  const ReferenceDetailPage({
    super.key,
    required this.kind,
    required this.name,
  });

  final String kind;
  final String name;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Eyebrow('$kind REFERENCE'),
      const SizedBox(height: 8),
      _PageTitle(name),
      const SizedBox(height: 22),
      if (kind == 'Class') _buildClassTable() else _buildRaceTable(),
    ],
  );

  Widget _buildClassTable() {
    final progression = _classProgressions[name.toLowerCase()] ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Class progression'),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              key: ValueKey('class-progression-$name'),
              columns: const [
                DataColumn(label: Text('Level')),
                DataColumn(label: Text('HD')),
                DataColumn(label: Text('BtH')),
                DataColumn(label: Text('Exp.')),
              ],
              rows: [
                for (final values in progression)
                  DataRow(
                    cells: [for (final value in values) DataCell(Text(value))],
                  ),
              ],
            ),
          ),
        ),
        if (progression.isEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Progression rows can be added to this reference table.',
            style: TextStyle(color: _muted),
          ),
        ],
        if (_isSpellcastingReferenceClass(name)) ...[
          const SizedBox(height: 24),
          _SectionHeading(
            title:
                name.trim().toLowerCase() == 'cleric' ||
                    name.trim().toLowerCase() == 'druid'
                ? 'Cleric and Druid spells per day'
                : 'Illusionist and Wizard spells per day',
          ),
          const SizedBox(height: 12),
          _SpellsPerDayReferenceTable(className: name),
        ],
      ],
    );
  }

  Widget _buildRaceTable() {
    final matchingDetails = _raceReferenceDetails.entries
        .where((entry) => entry.key.toLowerCase() == name.trim().toLowerCase())
        .map((entry) => entry.value)
        .toList();
    final details = matchingDetails.isEmpty ? null : matchingDetails.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Race modifiers'),
        const SizedBox(height: 12),
        if (details == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'No race modifiers are defined for this custom race.',
                style: TextStyle(color: _muted),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                key: ValueKey('race-details-$name'),
                columns: const [
                  DataColumn(label: Text('Race')),
                  DataColumn(label: Text('Base Move')),
                  DataColumn(label: Text('Attribute Modifiers')),
                  DataColumn(label: Text('Class Modifiers')),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(Text(name)),
                      DataCell(Text('${details.baseMove}')),
                      DataCell(Text(details.attributeModifiers)),
                      DataCell(Text(details.classModifiers)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SpellsPerDayReferenceTable extends StatelessWidget {
  const _SpellsPerDayReferenceTable({required this.className});

  final String className;

  @override
  Widget build(BuildContext context) {
    final isArcane = className.trim().toLowerCase() == 'illusionist' ||
        className.trim().toLowerCase() == 'wizard';
    final progression = isArcane
        ? _illusionistWizardSpellsPerDay
        : _clericDruidSpellsPerDay;
    const spellLevels = [
      '0',
      '1st',
      '2nd',
      '3rd',
      '4th',
      '5th',
      '6th',
      '7th',
      '8th',
      '9th',
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          key: ValueKey(
            isArcane
                ? 'illusionist-wizard-spells-per-day'
                : 'cleric-druid-spells-per-day',
          ),
          columns: [
            const DataColumn(label: Text('Level')),
            for (final spellLevel in spellLevels)
              DataColumn(label: Text(spellLevel)),
          ],
          rows: [
            for (
              var index = 0;
              index < progression.length;
              index++
            )
              DataRow(
                cells: [
                  DataCell(Text('${index + 1}')),
                  for (final count in progression[index])
                    DataCell(Text('$count')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatefulWidget {
  const _NotesCard({required this.initialValue, required this.onChanged});
  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends State<_NotesCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _NotesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        minLines: 5,
        maxLines: 12,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Quest hooks, allies, discoveries, and other notes...',
          border: InputBorder.none,
          filled: false,
        ),
        onChanged: widget.onChanged,
      ),
    ),
  );
}

class CharacterFormDialog extends StatefulWidget {
  const CharacterFormDialog({
    super.key,
    this.character,
    this.races = const [],
    this.classes = const [],
  });
  final CharacterSheet? character;
  final List<String> races;
  final List<String> classes;

  @override
  State<CharacterFormDialog> createState() => _CharacterFormDialogState();
}

class _CharacterFormDialogState extends State<CharacterFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _race;
  late String _raceLineage;
  late final TextEditingController _characterClass;
  late final List<TextEditingController> _additionalClasses;
  late final TextEditingController _alignment;
  late final TextEditingController _background;
  late final TextEditingController _currentHp;
  late final TextEditingController _maxHp;
  late final TextEditingController _experience;
  late final TextEditingController _diceCount;
  late final TextEditingController _dieSize;
  late final Map<String, TextEditingController> _abilityScores;
  final Map<String, int?> _rollAssignments = {};
  late Set<String> _primaryAttributes;
  List<int> _rolledScores = [];
  late String _classMode;
  bool _dropLowest = true;
  String? _diceError;

  @override
  void initState() {
    super.initState();
    final character = widget.character;
    _primaryAttributes = {...?character?.primaryAttributes};
    _name = TextEditingController(text: character?.name ?? '');
    _race = TextEditingController(text: character?.race ?? '');
    _raceLineage = character?.raceLineage ?? 'Human';
    _characterClass = TextEditingController(
      text: character?.characterClass ?? '',
    );
    const classModes = {'single', 'multiclass', 'classAndHalf'};
    final savedClassMode = character?.classMode;
    _classMode = classModes.contains(savedClassMode)
        ? savedClassMode!
        : 'single';
    final storedAdditionalClasses = character?.classes.skip(1).toList() ?? [];
    final allowedAdditionalCount = switch (_classMode) {
      'multiclass' => 2,
      'classAndHalf' => 1,
      _ => 0,
    };
    _additionalClasses = storedAdditionalClasses
        .take(allowedAdditionalCount)
        .map((className) => TextEditingController(text: className))
        .toList();
    if (_classMode == 'multiclass' && _additionalClasses.isEmpty) {
      _additionalClasses.add(TextEditingController());
    }
    _alignment = TextEditingController(text: character?.alignment ?? '');
    _background = TextEditingController(text: character?.background ?? '');
    _currentHp = TextEditingController(text: '${character?.currentHp ?? 1}');
    _maxHp = TextEditingController(text: '${character?.maxHp ?? 1}');
    _experience = TextEditingController(text: '${character?.experience ?? 0}');
    _diceCount = TextEditingController(text: '4');
    _dieSize = TextEditingController(text: '6');
    _abilityScores = {
      for (final ability in CharacterSheet.abilityNames)
        ability: TextEditingController(
          text: '${character?.abilities[ability] ?? 10}',
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _race,
      _characterClass,
      _alignment,
      _background,
      _currentHp,
      _maxHp,
      _experience,
      _diceCount,
      _dieSize,
      ..._abilityScores.values,
      ..._additionalClasses,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _number(TextEditingController controller, int fallback) =>
      int.tryParse(controller.text.trim()) ?? fallback;

  void _rollAbilityScores() {
    final count = int.tryParse(_diceCount.text.trim());
    final sides = int.tryParse(_dieSize.text.trim());
    if (count == null || count < 1 || count > 20) {
      setState(() => _diceError = 'Dice count must be between 1 and 20.');
      return;
    }
    if (sides == null || sides < 2 || sides > 100) {
      setState(() => _diceError = 'Die size must be between 2 and 100.');
      return;
    }
    if (_dropLowest && count < 2) {
      setState(() => _diceError = 'Roll at least 2 dice to drop the lowest.');
      return;
    }

    final random = Random();
    setState(() {
      _rolledScores = List.generate(6, (_) {
        final dice = List.generate(count, (_) => random.nextInt(sides) + 1)
          ..sort();
        return dice
            .skip(_dropLowest ? 1 : 0)
            .fold<int>(0, (sum, die) => sum + die);
      });
      _rollAssignments
        ..clear()
        ..addEntries(
          CharacterSheet.abilityNames.map((ability) => MapEntry(ability, null)),
        );
      _diceError = null;
    });
  }

  Map<String, int> _currentAbilityScores() {
    final scores = {
      for (final ability in CharacterSheet.abilityNames)
        ability: _number(_abilityScores[ability]!, 10),
    };
    for (final entry in _rollAssignments.entries) {
      final rollIndex = entry.value;
      if (rollIndex != null) {
        scores[entry.key] = _rolledScores[rollIndex];
      }
    }
    return scores;
  }

  int _raceModifierFor(String ability) =>
      _raceAttributeModifiers(_race.text, _raceLineage)[ability] ?? 0;

  int _baseAbilityScore(String ability) {
    final rollIndex = _rollAssignments[ability];
    return rollIndex == null
        ? _number(_abilityScores[ability]!, 10)
        : _rolledScores[rollIndex];
  }

  String _abilityScorePreview(String ability) {
    final baseScore = _baseAbilityScore(ability);
    final modifier = _raceModifierFor(ability);
    final modifierText = modifier == 0
        ? ''
        : ' ${modifier > 0 ? '+' : '−'} ${modifier.abs()} race';
    return 'Final score: $baseScore$modifierText = '
        '${baseScore + modifier}';
  }

  int get _constitutionModifier => CharacterSheet.modifierForScore(
    _baseAbilityScore('Constitution') + _raceModifierFor('Constitution'),
  );

  int? get _startingMaxHp {
    final hitDie = _highestHitDieForLevel(
      _selectedClassNames(),
      1,
      classMode: _classMode,
    );
    final maximum = hitDie == null ? null : _maximumHitPointsForHitDie(hitDie);
    return maximum == null
        ? null
        : _hitPointsWithConstitution(maximum, _constitutionModifier);
  }

  void _updateStartingHitPoints() {
    if (widget.character != null) return;
    final hitPoints = _startingMaxHp;
    if (hitPoints == null) return;
    _maxHp.text = '$hitPoints';
    _currentHp.text = '$hitPoints';
  }

  void _onClassChanged(String _) => _updateStartingHitPoints();

  void _onRaceChanged(String race) {
    _primaryAttributes = CharacterSheet.limitPrimaryAttributes(
      race,
      _primaryAttributes,
    );
    _updateStartingHitPoints();
  }

  void _setPrimaryAttribute(String ability, bool isPrimary) {
    setState(() {
      if (isPrimary) {
        final maxSelections = CharacterSheet.maxPrimaryAttributesForRace(
          _race.text,
        );
        if (_primaryAttributes.length >= maxSelections) return;
        _primaryAttributes.add(ability);
      } else {
        _primaryAttributes.remove(ability);
      }
    });
  }

  List<int> _availableRollIndices({String? forAbility}) {
    final assignedElsewhere = _rollAssignments.entries
        .where((entry) => entry.key != forAbility && entry.value != null)
        .map((entry) => entry.value!)
        .toSet();
    return [
      for (var index = 0; index < _rolledScores.length; index++)
        if (!assignedElsewhere.contains(index)) index,
    ];
  }

  List<String> _selectedClassNames() => [
    _characterClass.text.trim(),
    ..._additionalClasses.map((controller) => controller.text.trim()),
  ].where((className) => className.isNotEmpty).toList();

  int get _currentLevel {
    final experience = int.tryParse(_experience.text.trim());
    if (experience != null) {
      final derived = _levelForExperience(
        _selectedClassNames(),
        _classMode,
        experience,
      );
      if (derived != null) return derived;
    }
    return (widget.character?.level ?? 1).clamp(1, 20);
  }

  String? get _levelUpNotice {
    final currentLevel = _currentLevel;
    final previousLevel = widget.character?.effectiveLevel ?? 1;
    if (currentLevel <= previousLevel) return null;
    return 'Your XP qualifies you to level up to level $currentLevel.';
  }

  void _setClassMode(String? mode) {
    if (mode == null) return;
    setState(() {
      _classMode = mode;
      if (mode == 'single') {
        for (final controller in _additionalClasses) {
          controller.dispose();
        }
        _additionalClasses.clear();
      } else {
        while (_additionalClasses.length > 1) {
          _additionalClasses.removeLast().dispose();
        }
        if (_additionalClasses.isEmpty) {
          _additionalClasses.add(TextEditingController());
        }
      }
      _updateStartingHitPoints();
    });
  }

  void _addClass() {
    if (_additionalClasses.length >= 2 || _classMode != 'multiclass') return;
    setState(() => _additionalClasses.add(TextEditingController()));
  }

  void _removeClass(int index) {
    setState(() => _additionalClasses.removeAt(index).dispose());
  }

  List<String> _optionsForClass(TextEditingController controller) {
    final selectedElsewhere = <String>{
      if (!identical(controller, _characterClass))
        _characterClass.text.trim().toLowerCase(),
      for (final other in _additionalClasses)
        if (!identical(controller, other)) other.text.trim().toLowerCase(),
    }..remove('');
    return widget.classes
        .where(
          (className) =>
              !selectedElsewhere.contains(className.trim().toLowerCase()),
        )
        .toList();
  }

  String? _validateClassName(String? value) {
    if (_classMode == 'single') return null;
    if (value == null || value.trim().isEmpty) return 'Select a class';
    final selected = _selectedClassNames()
        .map((className) => className.toLowerCase())
        .toList();
    if (selected.toSet().length != selected.length) {
      return 'Choose a different class';
    }
    return null;
  }

  String _nextLevelExperienceDescription() {
    if (_currentLevel >= 20) return 'Maximum level reached.';
    final selectedClasses = _selectedClassNames();
    if (selectedClasses.isEmpty) return '';
    final required = _requiredExperienceForNextLevel(
      selectedClasses,
      _classMode,
      _currentLevel,
    );
    if (required == null) {
      return 'Next-level XP is unavailable until progression data is added '
          'for each selected class.';
    }
    if (_classMode == 'multiclass') {
      final perClass = required ~/ selectedClasses.length;
      return 'Next shared level: ${_formatNumber(required)} total XP '
          '(${_formatNumber(perClass)} XP per class, split evenly). '
          'Current share: '
          '${_formatNumber(_number(_experience, 0) ~/ selectedClasses.length)} '
          'XP per class.';
    }
    if (_classMode == 'classAndHalf') {
      final primaryRequirement = _experienceForClassLevel(
        selectedClasses.first,
        _currentLevel + 1,
      )!;
      final halfClassLevel = (_currentLevel + 1) ~/ 2;
      final halfClassRequirement = _experienceForClassLevel(
        selectedClasses[1],
        halfClassLevel,
      )!;
      return 'Next level: ${_formatNumber(primaryRequirement)} XP for '
          '${selectedClasses.first} + '
          '${_formatNumber(halfClassRequirement)} XP for '
          '${selectedClasses[1]} (level $halfClassLevel) = '
          '${_formatNumber(required)} XP total.';
    }
    return 'Next level requires ${_formatNumber(required)} total XP.';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final old = widget.character;
    final selectedClasses = _selectedClassNames();
    final startingMaxHp = _startingMaxHp;
    Navigator.pop(
      context,
      CharacterSheet(
        id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        race: _race.text.trim(),
        raceLineage: _raceLineage,
        characterClass: selectedClasses.isEmpty ? '' : selectedClasses.first,
        characterClasses: selectedClasses,
        classMode: _classMode,
        level: _currentLevel,
        alignment: _alignment.text.trim(),
        background: _background.text.trim(),
        armorModifier: old?.armorModifier ?? 0,
        armorName: old?.armorName ?? '',
        hpLevel: old?.hpLevel ?? 1,
        currentHp: _number(_currentHp, 1),
        maxHp: old == null && startingMaxHp != null
            ? startingMaxHp
            : _number(_maxHp, 1),
        experience: _number(_experience, 0),
        abilities: _currentAbilityScores(),
        primaryAttributes: CharacterSheet.limitPrimaryAttributes(
          _race.text.trim(),
          _primaryAttributes,
        ),
        spells: old?.spells ?? const [],
        equipment: old?.equipment ?? const [],
        equippedGear: old?.equippedGear ?? const [],
        notes: old?.notes ?? '',
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Enter a character name' : null;

  String? _integer(String? value) =>
      int.tryParse(value ?? '') == null ? 'Enter a whole number' : null;

  String? _abilityScoreValidator(String? value) {
    final score = int.tryParse(value ?? '');
    return score == null || score < 1 || score > 2000
        ? 'Enter a score from 1 to 2000'
        : null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.character == null ? 'Create character' : 'Edit character',
    ),
    content: SizedBox(
      width: 500,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Character name *',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              _buildDiceRoller(),
              const SizedBox(height: 12),
              _buildAbilityScoreFields(),
              const SizedBox(height: 12),
              _referenceField(
                key: const ValueKey('character-race'),
                controller: _race,
                label: 'Race',
                options: widget.races,
                onChanged: _onRaceChanged,
              ),
              if (_race.text.trim().toLowerCase() == 'half-elf') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('race-lineage'),
                  initialValue: _raceLineage,
                  decoration: const InputDecoration(labelText: 'Race lineage'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Human',
                      child: Text('Human lineage'),
                    ),
                    DropdownMenuItem(value: 'Elf', child: Text('Elf lineage')),
                  ],
                  onChanged: (lineage) {
                    if (lineage != null) {
                      setState(() {
                        _raceLineage = lineage;
                        _updateStartingHitPoints();
                      });
                    }
                  },
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const ValueKey('class-mode'),
                initialValue: _classMode,
                decoration: const InputDecoration(
                  labelText: 'Class arrangement',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'single',
                    child: Text('Single class'),
                  ),
                  DropdownMenuItem(
                    value: 'multiclass',
                    child: Text('Multiclass'),
                  ),
                  DropdownMenuItem(
                    value: 'classAndHalf',
                    child: Text('Class and a half'),
                  ),
                ],
                onChanged: _setClassMode,
              ),
              const SizedBox(height: 12),
              _buildClassFields(),
              const SizedBox(height: 12),
              _buildPrimaryAttributeFields(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      key: const ValueKey('character-level'),
                      decoration: const InputDecoration(
                        labelText: 'Level (based on XP)',
                      ),
                      child: Text('$_currentLevel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const ValueKey('character-alignment'),
                      isExpanded: true,
                      initialValue: _alignment.text.isEmpty
                          ? null
                          : _alignment.text,
                      decoration: const InputDecoration(labelText: 'Alignment'),
                      items: [
                        for (final alignment in _alignmentOptions)
                          DropdownMenuItem(
                            value: alignment,
                            child: Text(alignment),
                          ),
                        if (_alignment.text.isNotEmpty &&
                            !_alignmentOptions.contains(_alignment.text))
                          DropdownMenuItem(
                            value: _alignment.text,
                            child: Text(_alignment.text),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _alignment.text = value;
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _background,
                decoration: const InputDecoration(labelText: 'Background'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _currentHp,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Current HP',
                      ),
                      validator: _integer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxHp,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max HP'),
                      validator: _integer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _experience,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Experience points',
                ),
                validator: _integer,
                onChanged: (_) => setState(() {}),
              ),
              if (_levelUpNotice != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _levelUpNotice!,
                    key: const ValueKey('level-up-notice'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (_nextLevelExperienceDescription().isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _nextLevelExperienceDescription(),
                    key: const ValueKey('next-level-experience'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: _muted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save character')),
    ],
  );

  Widget _referenceField({
    required TextEditingController controller,
    required String label,
    required List<String> options,
    Key? key,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    if (options.isEmpty) {
      return TextFormField(
        key: key,
        controller: controller,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        onChanged: (value) => setState(() => onChanged?.call(value)),
      );
    }

    final values = [...options];
    final currentValue = controller.text.trim();
    if (currentValue.isNotEmpty && !values.contains(currentValue)) {
      values.add(currentValue);
    }
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: currentValue.isEmpty ? null : currentValue,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      items: [
        for (final value in values)
          DropdownMenuItem(value: value, child: Text(value)),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            controller.text = value;
            onChanged?.call(value);
          });
        }
      },
    );
  }

  Widget _buildPrimaryAttributeFields() {
    final maximum = CharacterSheet.maxPrimaryAttributesForRace(_race.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading(title: 'Primary attributes'),
        const SizedBox(height: 4),
        Text(
          'Choose up to $maximum primary attributes for saving throws.',
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        for (final ability in CharacterSheet.abilityNames)
          CheckboxListTile(
            key: ValueKey('creation-primary-$ability'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(ability),
            value: _primaryAttributes.contains(ability),
            onChanged:
                _primaryAttributes.contains(ability) ||
                    _primaryAttributes.length < maximum
                ? (value) => _setPrimaryAttribute(ability, value ?? false)
                : null,
          ),
      ],
    );
  }

  Widget _buildClassFields() => Column(
    children: [
      _referenceField(
        key: const ValueKey('character-class-primary'),
        controller: _characterClass,
        label: _classMode == 'single' ? 'Class' : 'Primary class',
        options: _optionsForClass(_characterClass),
        validator: _validateClassName,
        onChanged: _onClassChanged,
      ),
      for (var index = 0; index < _additionalClasses.length; index++)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              Expanded(
                child: _referenceField(
                  key: ValueKey('character-class-${index + 2}'),
                  controller: _additionalClasses[index],
                  label: _classMode == 'classAndHalf'
                      ? 'Half class'
                      : 'Class ${index + 2}',
                  options: _optionsForClass(_additionalClasses[index]),
                  validator: _validateClassName,
                  onChanged: _onClassChanged,
                ),
              ),
              if (_classMode == 'multiclass')
                IconButton(
                  key: ValueKey('remove-class-${index + 2}'),
                  tooltip: 'Remove class',
                  onPressed: () => _removeClass(index),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
            ],
          ),
        ),
      if (_classMode == 'multiclass' && _additionalClasses.length < 2)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const ValueKey('add-class'),
            onPressed: _addClass,
            icon: const Icon(Icons.add),
            label: const Text('Add class'),
          ),
        ),
      if (_classMode == 'classAndHalf')
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Half-class level: ${_currentLevel ~/ 2}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: _muted),
            ),
          ),
        ),
    ],
  );

  Widget _buildAbilityScoreFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionHeading(title: 'Ability scores'),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          for (final ability in CharacterSheet.abilityNames)
            SizedBox(
              width: 230,
              child: _rolledScores.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          key: ValueKey('create-score-$ability'),
                          controller: _abilityScores[ability],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: ability),
                          validator: _abilityScoreValidator,
                          onChanged: (_) => setState(_updateStartingHitPoints),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: Text(
                            _abilityScorePreview(ability),
                            key: ValueKey('adjusted-score-$ability'),
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                key: ValueKey('roll-assignment-$ability'),
                                initialValue: _rollAssignments[ability],
                                decoration: InputDecoration(labelText: ability),
                                items: [
                                  for (final index in _availableRollIndices(
                                    forAbility: ability,
                                  ))
                                    DropdownMenuItem(
                                      value: index,
                                      child: Text(
                                        '#${index + 1}: '
                                        '${_rolledScores[index]}',
                                      ),
                                    ),
                                ],
                                onChanged: (value) => setState(() {
                                  _rollAssignments[ability] = value;
                                  _updateStartingHitPoints();
                                }),
                                validator: (value) => value == null
                                    ? 'Assign a rolled score'
                                    : null,
                              ),
                            ),
                            IconButton(
                              key: ValueKey('clear-roll-$ability'),
                              tooltip: 'Clear $ability roll',
                              onPressed: _rollAssignments[ability] == null
                                  ? null
                                  : () => setState(() {
                                      _rollAssignments[ability] = null;
                                      _updateStartingHitPoints();
                                    }),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: Text(
                            _abilityScorePreview(ability),
                            key: ValueKey('adjusted-score-$ability'),
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
    ],
  );

  Widget _buildDiceRoller() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _SectionHeading(title: 'Roll ability scores'),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              key: const ValueKey('dice-count'),
              controller: _diceCount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of dice'),
              validator: (value) {
                final count = int.tryParse(value ?? '');
                return count == null || count < 1 || count > 20
                    ? 'Enter 1–20 dice'
                    : null;
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              key: const ValueKey('die-size'),
              controller: _dieSize,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Die size (sides)'),
              validator: (value) {
                final sides = int.tryParse(value ?? '');
                return sides == null || sides < 2 || sides > 100
                    ? 'Enter 2–100 sides'
                    : null;
              },
            ),
          ),
        ],
      ),
      CheckboxListTile(
        key: const ValueKey('drop-lowest'),
        contentPadding: EdgeInsets.zero,
        title: const Text('Drop the lowest die'),
        value: _dropLowest,
        onChanged: (value) => setState(() {
          _dropLowest = value ?? false;
          _diceError = null;
        }),
      ),
      if (_diceError != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _diceError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      Wrap(
        spacing: 8,
        children: [
          FilledButton.tonalIcon(
            key: const ValueKey('roll-ability-scores'),
            onPressed: _rollAbilityScores,
            icon: const Icon(Icons.casino_outlined),
            label: const Text('Roll 6 scores'),
          ),
          if (_rolledScores.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _rolledScores = [];
                _rollAssignments.clear();
                _diceError = null;
                _updateStartingHitPoints();
              }),
              child: const Text('Enter scores manually'),
            ),
        ],
      ),
      if (_rolledScores.isNotEmpty) ...[
        const SizedBox(height: 8),
        const Text('Available scores'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final index in _availableRollIndices())
              Chip(
                key: ValueKey('available-roll-$index'),
                label: Text('Roll ${index + 1}: ${_rolledScores[index]}'),
              ),
          ],
        ),
      ],
    ],
  );
}

Future<String?> _askForText(
  BuildContext context,
  String title,
  String hint,
) async {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextEntryDialog(title: title, hint: hint),
  );
}

class _TextEntryDialog extends StatefulWidget {
  const _TextEntryDialog({required this.title, required this.hint});
  final String title;
  final String hint;

  @override
  State<_TextEntryDialog> createState() => _TextEntryDialogState();
}

class _TextEntryDialogState extends State<_TextEntryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      decoration: InputDecoration(hintText: widget.hint),
      onSubmitted: (value) => Navigator.pop(context, value.trim()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: const Text('Add'),
      ),
    ],
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: _forest,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
      fontSize: 10,
    ),
  );
}

class _PageTitle extends StatelessWidget {
  const _PageTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: _ink,
      fontSize: 30,
      height: 1.15,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel!, style: const TextStyle(color: _forest)),
        ),
    ],
  );
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 9,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

String _modifier(int score) => _signed(CharacterSheet.modifierForScore(score));

String _signed(int value) => value >= 0 ? '+$value' : '$value';

String _formatNumber(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (match) => ',',
);

String _orDash(String value) => value.isEmpty ? '—' : value;

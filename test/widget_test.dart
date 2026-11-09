import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cnc_companion/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('creates a character and updates sheet sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Mira Stone',
    );
    final classField = find.byKey(const ValueKey('character-class-primary'));
    await tester.ensureVisible(classField);
    await tester.tap(classField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assassin').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    expect(find.text('Mira Stone'), findsOneWidget);
    expect(find.text('Assassin'), findsOneWidget);
    expect(find.text('HIT POINTS'), findsOneWidget);

    await tester.tap(find.text('Abilities'));
    await tester.pumpAndSettle();
    expect(find.text('Ability scores'), findsOneWidget);
    expect(find.text('10'), findsNWidgets(6));
    await tester.tap(find.byTooltip('Increase Strength'));
    await tester.pumpAndSettle();
    expect(find.text('11'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase Strength'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Increase Strength'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saving Throws'));
    await tester.pumpAndSettle();
    expect(find.text('Saving throws'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(6));
    final savingHeader = find.ancestor(
      of: find.text('TARGET NUMBER'),
      matching: find.byType(Row),
    );
    expect(
      tester
          .widgetList<Text>(
            find.descendant(
              of: savingHeader.first,
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .toList(),
      [
        'ATTRIBUTE',
        'TARGET NUMBER',
        'STAT MODIFIER',
        'LEVEL MOD',
        'MODIFIED TARGET',
      ],
    );
    expect(find.byKey(const ValueKey('modifier-Strength')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('modifier-Strength'))).data,
      '+1',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('target-Strength'))).data,
      '18',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('level-Strength'))).data,
      '1',
    );
    await tester.tap(find.byKey(const ValueKey('primary-Strength')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('target-Strength'))).data,
      '12',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('modified-Strength'))).data,
      '10',
    );

    await tester.tap(find.text('Spells'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add spell'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Light');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsOneWidget);

    await tester.tap(find.text('Gear & Notes'));
    await tester.pumpAndSettle();
    expect(find.text('Gear & notes'), findsOneWidget);
    expect(find.text('Adventure notes'), findsOneWidget);
  });

  testWidgets('Cleric spell slots show on the character sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Cleric Test',
    );
    final classField = find.byKey(const ValueKey('character-class-primary'));
    await tester.ensureVisible(classField);
    await tester.tap(classField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cleric').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spells'));
    await tester.pumpAndSettle();
    final tableFinder = find.descendant(
      of: find.byKey(const ValueKey('character-spells-per-day-cleric')),
      matching: find.byType(DataTable),
    );
    final table = tester.widget<DataTable>(tableFinder);
    expect(table.rows.single.cells.map((cell) => (cell.child as Text).data), [
      '1',
      '3',
      '1',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
    ]);
  });

  testWidgets('Cleric and Druid reference spell table matches supplied rows', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: const ReferenceDetailPage(kind: 'Class', name: 'Cleric'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final table = tester.widget<DataTable>(
      find.byKey(const ValueKey('cleric-druid-spells-per-day')),
    );
    expect(table.rows, hasLength(20));
    expect(table.rows[0].cells.map((cell) => (cell.child as Text).data), [
      '1',
      '3',
      '1',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
    ]);
    expect(table.rows[19].cells.map((cell) => (cell.child as Text).data), [
      '20',
      '7',
      '6',
      '6',
      '6',
      '5',
      '5',
      '4',
      '4',
      '3',
      '3',
    ]);
  });

  testWidgets('Illusionist and Wizard spell slots use supplied progression', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: const ReferenceDetailPage(
              kind: 'Class',
              name: 'Illusionist',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final table = tester.widget<DataTable>(
      find.byKey(const ValueKey('illusionist-wizard-spells-per-day')),
    );
    expect(table.rows, hasLength(20));
    expect(table.rows[0].cells.map((cell) => (cell.child as Text).data), [
      '1',
      '4',
      '2',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
    ]);
    expect(table.rows[19].cells.map((cell) => (cell.child as Text).data), [
      '20',
      '7',
      '7',
      '6',
      '6',
      '5',
      '5',
      '4',
      '4',
      '3',
      '3',
    ]);
  });

  testWidgets('Wizard character sheet includes wizard spell slots', (
    WidgetTester tester,
  ) async {
    final character = CharacterSheet.fromJson({
      'id': 'wizard-spell-slots',
      'name': 'Wizard Test',
      'race': 'Human',
      'characterClass': 'Wizard',
      'classes': ['Wizard'],
      'classMode': 'single',
      'level': 1,
      'experience': 0,
      'currentHp': 1,
      'maxHp': 1,
    });
    SharedPreferences.setMockInitialValues({
      'cnc_companion.characters.v1': jsonEncode([character.toJson()]),
    });
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spells'));
    await tester.pumpAndSettle();

    final table = tester.widget<DataTable>(
      find.descendant(
        of: find.byKey(const ValueKey('character-spells-per-day-wizard')),
        matching: find.byType(DataTable),
      ),
    );
    expect(table.rows.single.cells.map((cell) => (cell.child as Text).data), [
      '1',
      '4',
      '2',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
    ]);
  });

  testWidgets('Cleric spells known include only spells up to current access', (
    WidgetTester tester,
  ) async {
    final spells = [
      for (final (name, spellClass, spellLevel) in [
        ('Guidance', 'Cleric', '0'),
        ('Bless', 'Cleric', '1'),
        ('Silence', 'Cleric', '2'),
        ('High Circle', 'Cleric', '3'),
        ('Entangle', 'Druid', '1'),
      ])
        SpellReferenceItem(
          spellName: name,
          characterClass: spellClass,
          level: spellLevel,
          castingTime: '',
          range: '',
          duration: '',
          savingThrow: '',
          spellResistance: '',
          components: '',
        ).toJson(),
    ];
    final character = CharacterSheet.fromJson({
      'id': 'cleric-known-spells',
      'name': 'Cleric Test',
      'race': 'Human',
      'characterClass': 'Cleric',
      'classes': ['Cleric'],
      'classMode': 'single',
      'level': 3,
      'experience': 5001,
      'currentHp': 10,
      'maxHp': 10,
      'spells': [],
    });
    SharedPreferences.setMockInitialValues({
      'cnc_companion.characters.v1': jsonEncode([character.toJson()]),
      'cnc_companion.reference.spells.v1': jsonEncode(spells),
    });
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spells'));
    await tester.pumpAndSettle();

    expect(find.text('Guidance'), findsOneWidget);
    expect(find.text('Bless'), findsOneWidget);
    expect(find.text('Silence'), findsOneWidget);
    expect(find.text('High Circle'), findsNothing);
    expect(find.text('Entangle'), findsNothing);
    expect(find.byKey(const ValueKey('add-known-spell-cleric')), findsNothing);
  });

  testWidgets(
    'Wizard known spells can only be selected from spell references',
    (WidgetTester tester) async {
      final wizardSpell = SpellReferenceItem(
        spellName: 'Light',
        characterClass: 'Wizard',
        level: '1',
        castingTime: '1 action',
        range: 'Touch',
        duration: '1 hour',
        savingThrow: 'None',
        spellResistance: 'No',
        components: 'V, S',
      );
      final referenceSpells = [
        wizardSpell,
        SpellReferenceItem(
          spellName: 'Fireball',
          characterClass: 'Wizard',
          level: '3',
          castingTime: '',
          range: '',
          duration: '',
          savingThrow: '',
          spellResistance: '',
          components: '',
        ),
        SpellReferenceItem(
          spellName: 'Bless',
          characterClass: 'Cleric',
          level: '1',
          castingTime: '',
          range: '',
          duration: '',
          savingThrow: '',
          spellResistance: '',
          components: '',
        ),
      ];
      final character = CharacterSheet.fromJson({
        'id': 'wizard-known-spells',
        'name': 'Wizard Test',
        'race': 'Human',
        'characterClass': 'Wizard',
        'classes': ['Wizard'],
        'classMode': 'single',
        'level': 1,
        'experience': 0,
        'currentHp': 1,
        'maxHp': 1,
        'spells': [],
      });
      SharedPreferences.setMockInitialValues({
        'cnc_companion.characters.v1': jsonEncode([character.toJson()]),
        'cnc_companion.reference.spells.v1': jsonEncode(
          referenceSpells.map((spell) => spell.toJson()).toList(),
        ),
      });
      await tester.pumpWidget(const CncCompanionApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spells'));
      await tester.pumpAndSettle();

      expect(find.text('No Wizard spells selected yet.'), findsOneWidget);
      final addSpellButton = find.byKey(
        const ValueKey('add-known-spell-wizard'),
      );
      await tester.ensureVisible(addSpellButton);
      await tester.tap(addSpellButton);
      await tester.pumpAndSettle();
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Fireball'), findsNothing);
      expect(find.text('Bless'), findsNothing);
      await tester.tap(
        find.byKey(
          ValueKey('select-reference-spell-${wizardSpell.selectionKey}'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add selected (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('No Wizard spells selected yet.'), findsNothing);
      final preferences = await SharedPreferences.getInstance();
      final savedCharacters = jsonDecode(
        preferences.getString('cnc_companion.characters.v1')!,
      ) as List<dynamic>;
      expect((savedCharacters.single as Map)['spells'], [
        wizardSpell.selectionKey,
      ]);
    },
  );

  testWidgets('deleting a character requires confirmation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Delete Test',
    );
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    final deleteButton = find.byKey(const ValueKey('delete-character'));
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.text('Delete character?'), findsOneWidget);
    expect(find.text('Remove Delete Test from this device?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Test'), findsOneWidget);

    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Delete Test'), findsNothing);
    expect(
      find.text('Every great tale starts\nwith a character.'),
      findsOneWidget,
    );

    final preferences = await SharedPreferences.getInstance();
    expect(
      jsonDecode(preferences.getString('cnc_companion.characters.v1')!),
      isEmpty,
    );
  });

  testWidgets('level up adds selected hit die HP to maximum HP', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Fighter One',
    );
    final classField = find.byKey(const ValueKey('character-class-primary'));
    await tester.ensureVisible(classField);
    await tester.tap(classField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fighter').last);
    await tester.pumpAndSettle();
    final constitution = find.byKey(
      const ValueKey('create-score-Constitution'),
    );
    await tester.ensureVisible(constitution);
    await tester.enterText(constitution, '16');
    await tester.ensureVisible(
      find.widgetWithText(TextFormField, 'Experience points'),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Experience points'),
      '2001',
    );
    await tester.ensureVisible(find.text('Save character'));
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    expect(find.text('12 / 12'), findsOneWidget);
    final levelUpButton = find.byKey(const ValueKey('level-up'));
    await tester.ensureVisible(levelUpButton);
    await tester.tap(levelUpButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('Hit Die d10 · CON +2'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('level-up-hit-points')),
      '6',
    );
    await tester.pumpAndSettle();
    expect(find.text('HP added: 6 +2 CON = 8'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm-level-up')));
    await tester.pumpAndSettle();

    expect(find.text('12 / 20'), findsOneWidget);
    expect(find.byKey(const ValueKey('level-up')), findsNothing);
    final preferences = await SharedPreferences.getInstance();
    final savedCharacters = jsonDecode(
      preferences.getString('cnc_companion.characters.v1')!,
    ) as List<dynamic>;
    expect(savedCharacters.single['maxHp'], 20);
    expect(savedCharacters.single['hpLevel'], 2);
  });

  testWidgets('class-and-a-half starts with the higher class Hit Die', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Fighter Monk',
    );
    await tester.tap(find.byKey(const ValueKey('class-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class and a half').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('character-class-primary')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fighter').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('character-class-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monk').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save character'));
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    expect(find.text('12 / 12'), findsOneWidget);
  });

  testWidgets('multiclass starts with the highest class Hit Die', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Monk Fighter',
    );
    await tester.tap(find.byKey(const ValueKey('class-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Multiclass').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('character-class-primary')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fighter').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('character-class-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monk').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save character'));
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    expect(find.text('12 / 12'), findsOneWidget);
  });

  testWidgets('class-and-a-half uses half-class level Hit Die progression', (
    WidgetTester tester,
  ) async {
    final character = CharacterSheet.fromJson({
      'id': 'half-class-hit-die',
      'name': 'Ranger Monk',
      'race': 'Human',
      'characterClass': 'Ranger',
      'classes': ['Ranger', 'Monk'],
      'classMode': 'classAndHalf',
      'level': 20,
      'hpLevel': 18,
      'experience': 3300002,
      'currentHp': 100,
      'maxHp': 100,
    });
    SharedPreferences.setMockInitialValues({
      'cnc_companion.characters.v1': jsonEncode([character.toJson()]),
    });
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('level-up')));
    await tester.tap(find.byKey(const ValueKey('level-up')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hit Die d12'), findsOneWidget);
  });

  testWidgets('class-and-a-half uses primary and half-class XP thresholds', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Ranger Monk',
    );

    final mode = find.byKey(const ValueKey('class-mode'));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Class and a half').last);
    await tester.pumpAndSettle();

    final primaryClass = find.byKey(const ValueKey('character-class-primary'));
    await tester.ensureVisible(primaryClass);
    await tester.tap(primaryClass);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ranger').last);
    await tester.pumpAndSettle();

    final halfClass = find.byKey(const ValueKey('character-class-2'));
    await tester.ensureVisible(halfClass);
    await tester.tap(halfClass);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monk').last);
    await tester.pumpAndSettle();

    final experience = find.widgetWithText(TextFormField, 'Experience points');
    await tester.ensureVisible(experience);
    await tester.enterText(experience, '258501');
    await tester.pumpAndSettle();
    expect(find.text('8'), findsOneWidget);
    expect(
      find.text('Your XP qualifies you to level up to level 8.'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Next level: 250,001 XP for Ranger + 8,501 XP for Monk '
        '(level 4) = 258,502 XP total.',
      ),
      findsOneWidget,
    );
    await tester.enterText(experience, '258502');
    await tester.pumpAndSettle();
    expect(find.text('9'), findsOneWidget);
    expect(
      find.text('Your XP qualifies you to level up to level 9.'),
      findsOneWidget,
    );
    await tester.enterText(experience, '520001');
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Next level: 500,001 XP for Ranger + 20,001 XP for Monk '
        '(level 5) = 520,002 XP total.',
      ),
      findsOneWidget,
    );
    await tester.enterText(experience, '520002');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('character-level')),
        matching: find.text('10'),
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Save character'));
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ranger / Monk'), findsOneWidget);
    expect(find.textContaining('Level 10'), findsOneWidget);
  });

  testWidgets('multiclass selection allows up to three classes', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();

    final mode = find.byKey(const ValueKey('class-mode'));
    await tester.ensureVisible(mode);
    await tester.tap(mode);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Multiclass').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('character-class-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-class')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('add-class')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('character-class-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-class')), findsNothing);
  });

  testWidgets('rolls configurable scores and assigns each to an ability', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Rolled Hero',
    );
    final race = find.byKey(const ValueKey('character-race'));
    await tester.ensureVisible(race);
    await tester.tap(race);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dwarf').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('dice-count')));
    await tester.enterText(find.byKey(const ValueKey('dice-count')), '2');
    await tester.enterText(find.byKey(const ValueKey('die-size')), '2');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('roll-ability-scores')),
      200,
      scrollable: find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('roll-ability-scores')));
    await tester.pumpAndSettle();
    expect(find.byType(Chip), findsNWidgets(6));

    final strengthAssignment = find.byKey(
      const ValueKey('roll-assignment-Strength'),
    );
    await tester.ensureVisible(strengthAssignment);
    await tester.tap(strengthAssignment);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('#1:').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('available-roll-0')), findsNothing);
    expect(find.byType(Chip), findsNWidgets(5));

    final clearStrength = find.byKey(const ValueKey('clear-roll-Strength'));
    await tester.ensureVisible(clearStrength);
    await tester.tap(clearStrength);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('available-roll-0')), findsOneWidget);
    expect(find.byType(Chip), findsNWidgets(6));

    final rolledDexterityScore = int.parse(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('available-roll-0')),
              matching: find.byType(Text),
            ),
          )
          .data!
          .split(': ')
          .last,
    );
    final dexterityAssignment = find.byKey(
      const ValueKey('roll-assignment-Dexterity'),
    );
    await tester.ensureVisible(dexterityAssignment);
    await tester.tap(dexterityAssignment);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('#1:').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('adjusted-score-Dexterity')))
          .data,
      'Final score: $rolledDexterityScore − 1 race = '
      '${rolledDexterityScore - 1}',
    );
    await tester.tap(find.byKey(const ValueKey('clear-roll-Dexterity')));
    await tester.pumpAndSettle();

    for (var index = 0; index < CharacterSheet.abilityNames.length; index++) {
      final ability = CharacterSheet.abilityNames[index];
      final assignment = find.byKey(ValueKey('roll-assignment-$ability'));
      await tester.ensureVisible(assignment);
      await tester.tap(assignment);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('#${index + 1}:').last);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    final characters = jsonDecode(
      preferences.getString('cnc_companion.characters.v1')!,
    ) as List<dynamic>;
    final abilities = characters.single['abilities'] as Map<String, dynamic>;
    expect(abilities.keys, containsAll(CharacterSheet.abilityNames));
    expect(abilities.values, everyElement(anyOf(1, 2)));
    final savedCharacter = CharacterSheet.fromJson(
      characters.single as Map<String, dynamic>,
    );
    expect(
      savedCharacter.effectiveAbilities['Dexterity'],
      (abilities['Dexterity'] as int) - 1,
    );
  });

  testWidgets('saved characters are restored when the app is reopened', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Alden',
    );
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saving Throws'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('primary-Strength')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();

    expect(find.text('Alden'), findsOneWidget);
    expect(find.text('HIT POINTS'), findsOneWidget);
    await tester.tap(find.text('Saving Throws'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Checkbox>(find.byKey(const ValueKey('primary-Strength')))
          .value,
      isTrue,
    );
  });

  testWidgets('Humans can select three primary attributes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Human',
    );
    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<String>).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Human').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saving Throws'));
    await tester.pumpAndSettle();
    for (final ability in ['Strength', 'Dexterity', 'Constitution']) {
      await tester.tap(find.byKey(ValueKey('primary-$ability')));
      await tester.pumpAndSettle();
    }

    for (final ability in ['Strength', 'Dexterity', 'Constitution']) {
      expect(
        tester.widget<Checkbox>(find.byKey(ValueKey('primary-$ability'))).value,
        isTrue,
      );
    }
    expect(
      tester
          .widget<Checkbox>(find.byKey(const ValueKey('primary-Intelligence')))
          .onChanged,
      isNull,
    );
  });

  testWidgets('other races can select only two primary attributes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Elf',
    );
    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<String>).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elf').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saving Throws'));
    await tester.pumpAndSettle();
    for (final ability in ['Strength', 'Dexterity']) {
      await tester.tap(find.byKey(ValueKey('primary-$ability')));
      await tester.pumpAndSettle();
    }

    expect(
      tester
          .widget<Checkbox>(find.byKey(const ValueKey('primary-Strength')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<Checkbox>(find.byKey(const ValueKey('primary-Dexterity')))
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<Checkbox>(find.byKey(const ValueKey('primary-Constitution')))
          .onChanged,
      isNull,
    );
  });

  testWidgets('primary attributes can be selected during character creation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Primary Human',
    );

    final race = find.byKey(const ValueKey('character-race'));
    await tester.ensureVisible(race);
    await tester.tap(race);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Human').last);
    await tester.pumpAndSettle();

    for (final ability in ['Strength', 'Dexterity', 'Constitution']) {
      final primary = find.byKey(ValueKey('creation-primary-$ability'));
      await tester.ensureVisible(primary);
      await tester.tap(primary);
      await tester.pumpAndSettle();
    }

    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('creation-primary-Strength')),
          )
          .value,
      isTrue,
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('creation-primary-Intelligence')),
          )
          .onChanged,
      isNull,
    );

    await tester.ensureVisible(find.text('Save character'));
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    final savedCharacters = jsonDecode(
      preferences.getString('cnc_companion.characters.v1')!,
    ) as List<dynamic>;
    expect(
      Set<String>.from(savedCharacters.single['primaryAttributes'] as List),
      {'Strength', 'Dexterity', 'Constitution'},
    );
  });

  testWidgets('reference data can be added and selected for a character', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('cnc_companion.reference.races.v1'), [
      'Dwarf',
      'Elf',
      'Gnome',
      'Half-Elf',
      'Half-Orc',
      'Halfling',
      'Human',
    ]);
    expect(preferences.getStringList('cnc_companion.reference.classes.v1'), [
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
    ]);

    await tester.tap(find.text('Add race and class reference data'));
    await tester.pumpAndSettle();
    expect(find.text('Reference data'), findsOneWidget);
    await tester.tap(find.text('Dwarf').first);
    await tester.pumpAndSettle();
    final raceRules = tester.widget<DataTable>(
      find.byKey(const ValueKey('race-details-Dwarf')),
    );
    expect(
      raceRules.columns.map((column) => (column.label as Text).data).toList(),
      ['Race', 'Base Move', 'Attribute Modifiers', 'Class Modifiers'],
    );
    expect(raceRules.rows, hasLength(1));
    expect(
      raceRules.rows.single.cells.map((cell) => (cell.child as Text).data),
      [
        'Dwarf',
        '20',
        '+1 CON, -1 DEX',
        'Rogue/Assassin: +2 Find Traps (structures only)',
      ],
    );
    expect(find.text('+1 CON, -1 DEX'), findsOneWidget);

    await tester.tap(find.byTooltip('Back to reference data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assassin').first);
    await tester.pumpAndSettle();
    final classProgression = tester.widget<DataTable>(
      find.byKey(const ValueKey('class-progression-Assassin')),
    );
    expect(
      classProgression.columns
          .map((column) => (column.label as Text).data)
          .toList(),
      ['Level', 'HD', 'BtH', 'Exp.'],
    );
    expect(classProgression.rows, hasLength(20));
    expect(
      classProgression.rows.first.cells.map(
        (cell) => (cell.child as Text).data,
      ),
      ['1', 'd6', '-', '-'],
    );
    expect(
      classProgression.rows[1].cells.map((cell) => (cell.child as Text).data),
      ['2', 'd6', '1', '1,751'],
    );
    expect(
      classProgression.rows.last.cells.map((cell) => (cell.child as Text).data),
      ['20', '2', '4', '1,700,001'],
    );

    await tester.tap(find.byTooltip('Back to reference data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Barbarian').first);
    await tester.pumpAndSettle();
    final barbarianProgression = tester.widget<DataTable>(
      find.byKey(const ValueKey('class-progression-Barbarian')),
    );
    expect(barbarianProgression.rows, hasLength(20));
    expect(
      barbarianProgression.rows.first.cells.map(
        (cell) => (cell.child as Text).data,
      ),
      ['1', 'd12', '-', '0'],
    );
    expect(
      barbarianProgression.rows[12].cells.map(
        (cell) => (cell.child as Text).data,
      ),
      ['13', '2', '4', '1,200,001'],
    );
    expect(
      barbarianProgression.rows.last.cells.map(
        (cell) => (cell.child as Text).data,
      ),
      ['20', '2', '4', '2,600,001'],
    );

    await tester.tap(find.byTooltip('Back to reference data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bard').first);
    await tester.pumpAndSettle();
    final bardProgression = tester.widget<DataTable>(
      find.byKey(const ValueKey('class-progression-Bard')),
    );
    expect(bardProgression.rows, hasLength(20));
    expect(
      bardProgression.rows.first.cells.map((cell) => (cell.child as Text).data),
      ['1', 'd10', '-', '0'],
    );
    expect(
      bardProgression.rows[10].cells.map((cell) => (cell.child as Text).data),
      ['11', '4', '10', '625,001'],
    );
    expect(
      bardProgression.rows.last.cells.map((cell) => (cell.child as Text).data),
      ['20', '4', '11', '2,200,001'],
    );

    await tester.tap(find.byTooltip('Back to reference data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Race'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Aardvark');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();
    expect(
      preferences.getStringList('cnc_companion.reference.races.v1')!.first,
      'Aardvark',
    );

    await tester.tap(find.text('Add Class'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Acolyte');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();
    expect(
      preferences.getStringList('cnc_companion.reference.classes.v1')!.first,
      'Acolyte',
    );

    await tester.tap(find.byTooltip('Back to character sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Elara',
    );

    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(dropdowns.first);
    await tester.tap(dropdowns.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aardvark').last);
    await tester.pumpAndSettle();
    final classField = find.byKey(const ValueKey('character-class-primary'));
    await tester.ensureVisible(classField);
    await tester.tap(classField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acolyte').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    expect(find.text('Aardvark  ·  Acolyte  ·  Level 1'), findsOneWidget);
  });

  testWidgets('spell reference entries can be added and persisted', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add race and class reference data'));
    await tester.pumpAndSettle();
    final spellCard = find.byKey(const ValueKey('spell-reference-card'));
    await tester.ensureVisible(spellCard);
    await tester.tap(spellCard);
    await tester.pumpAndSettle();

    final addButton = find.byKey(const ValueKey('add-spell-reference'));
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    final spellFields = find.byType(TextFormField);
    const values = [
      'Light',
      'Wizard',
      '1',
      '1 action',
      'Touch',
      '1 hour/level',
      'None',
      'No',
      'V, S',
    ];
    for (var index = 0; index < values.length; index++) {
      await tester.enterText(spellFields.at(index), values[index]);
    }
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final table = tester.widget<DataTable>(find.byType(DataTable).last);
    expect(
      table.columns
          .take(9)
          .map(
            (column) =>
                (((column.label as SizedBox).child as Column).children.first
                        as Text)
                    .data,
          ),
      ['Spell Name', 'Class', 'Level', 'CT', 'R', 'D', 'SV', 'SR', 'Comp'],
    );
    expect(find.text('Light'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    final savedItems = jsonDecode(
      preferences.getString('cnc_companion.reference.spells.v1')!,
    ) as List<dynamic>;
    expect(savedItems.single['spellName'], 'Light');
    expect(savedItems.single['class'], 'Wizard');
    expect(savedItems.single['comp'], 'V, S');
    for (final field in [
      'spellName',
      'characterClass',
      'level',
      'castingTime',
      'range',
      'duration',
      'savingThrow',
      'spellResistance',
      'components',
    ]) {
      expect(find.byKey(ValueKey('filter-spell-$field')), findsOneWidget);
    }

    await tester.enterText(
      find.byKey(const ValueKey('filter-spell-characterClass')),
      'cleric',
    );
    await tester.pumpAndSettle();
    expect(find.text('No spells match these filters.'), findsOneWidget);
    expect(find.text('Light'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('filter-spell-characterClass')),
      'wizard',
    );
    await tester.enterText(
      find.byKey(const ValueKey('filter-spell-components')),
      'v, s',
    );
    await tester.pumpAndSettle();
    expect(find.text('Light'), findsOneWidget);
  });

  testWidgets('gear reference tables contain armor and editable subtables', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add race and class reference data'));
    await tester.pumpAndSettle();

    final armorCategory = find.byKey(const ValueKey('gear-category-Armor'));
    await tester.ensureVisible(armorCategory);
    await tester.tap(armorCategory);
    await tester.pumpAndSettle();

    final armorTable = tester.widget<DataTable>(
      find.byKey(const ValueKey('gear-table-Armor')),
    );
    expect(armorTable.rows, hasLength(25));
    expect(
      armorTable.rows.first.cells
          .take(2)
          .map((cell) => (cell.child as Text).data),
      ['Padded Armor', '1'],
    );
    expect(
      armorTable.rows.last.cells
          .take(2)
          .map((cell) => (cell.child as Text).data),
      ['Polish Hussar', '8'],
    );

    await tester.tap(find.byTooltip('Back to reference data'));
    await tester.pumpAndSettle();
    final shieldCategory = find.byKey(const ValueKey('gear-category-Shield'));
    await tester.ensureVisible(shieldCategory);
    await tester.tap(shieldCategory);
    await tester.pumpAndSettle();
    final shieldTable = tester.widget<DataTable>(
      find.byKey(const ValueKey('gear-table-Shield')),
    );
    expect(shieldTable.rows, hasLength(7));
    expect(shieldTable.columns.map((column) => (column.label as Text).data), [
      'Shield',
      'AC',
      '# of Foes',
      '',
    ]);
    expect(
      shieldTable.rows.map(
        (row) => row.cells.take(3).map((cell) => (cell.child as Text).data),
      ),
      [
        ['Buckler', '1', '1'],
        ['Shield, Small Steel', '1', '1'],
        ['Shield, Small Wooden', '1', '1'],
        ['Shield, Medium Steel', '1', '2'],
        ['Shield, Medium Wooden', '1', '2'],
        ['Shield, Large Steel', '1', '3'],
        ['Shield, Large Wooden', '1', '3'],
      ],
    );

    await tester.tap(find.byKey(const ValueKey('add-gear-Shield')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('gear-item-name')),
      'Kite Shield',
    );
    await tester.enterText(find.byKey(const ValueKey('gear-shield-ac')), '2');
    await tester.enterText(find.byKey(const ValueKey('gear-shield-foes')), '4');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();
    expect(find.text('Kite Shield'), findsOneWidget);
    await tester.tap(find.byTooltip('Edit Kite Shield'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('gear-item-name')),
      'Round Shield',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Round Shield'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    final gear = jsonDecode(
      preferences.getString('cnc_companion.reference.gear.v1')!,
    ) as List<dynamic>;
    expect(
      gear.any(
        (entry) =>
            entry['category'] == 'Shield' &&
            entry['name'] == 'Round Shield' &&
            entry['shieldAc'] == 2 &&
            entry['foes'] == 4,
      ),
      isTrue,
    );
  });

  testWidgets('weapon catalog seeds and persists detailed weapon reference', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'cnc_companion.reference.gear.v1': jsonEncode([
        const GearReferenceItem(
          category: 'Shield',
          name: 'Campaign Shield',
        ).toJson(),
      ]),
    });
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    final gear =
        (jsonDecode(preferences.getString('cnc_companion.reference.gear.v1')!)
                as List<dynamic>)
            .map(
              (item) => GearReferenceItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
    expect(gear.where((item) => item.category == 'Weapons'), hasLength(97));
    expect(gear.any((item) => item.name == 'Campaign Shield'), isTrue);
    expect(gear.where((item) => item.category == 'Shield'), hasLength(8));

    await tester.tap(find.text('Add race and class reference data'));
    await tester.pumpAndSettle();
    final weaponsCategory = find.byKey(const ValueKey('gear-category-Weapons'));
    await tester.ensureVisible(weaponsCategory);
    await tester.tap(weaponsCategory);
    await tester.pumpAndSettle();

    final weaponTable = tester.widget<DataTable>(
      find.byKey(const ValueKey('gear-table-Weapons')),
    );
    expect(weaponTable.columns.map((column) => (column.label as Text).data), [
      'Name',
      'Damage',
      'Special',
      'Attack type',
      '',
    ]);
    final rangedAxe = weaponTable.rows.firstWhere(
      (row) =>
          row.key ==
          const ValueKey('gear-row-Weapons-Axe, Hand/Throwing (Ranged)'),
    );
    expect(
      [
        (rangedAxe.cells[0].child as Text).data,
        (rangedAxe.cells[1].child as Text).data,
        ((rangedAxe.cells[2].child as ConstrainedBox).child as Text).data,
        (rangedAxe.cells[3].child as Text).data,
      ],
      ['Axe, Hand/Throwing (Ranged)', '1d6', '10 ft.', 'Ranged'],
    );
    final corbin = gear.firstWhere((item) => item.name == 'Bec De Corbin');
    expect(corbin.damage, '1d10');
    expect(corbin.special, '+2 vs. chain, plate or scale armors, Two Handed');
    expect(corbin.attackType, 'Melee');
  });

  testWidgets('helm, equipment, and container catalogs include supplied data', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'cnc_companion.reference.gear.v1': jsonEncode([
        const GearReferenceItem(
          category: 'Equipment',
          name: 'Custom Equipment',
        ).toJson(),
      ]),
    });
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    final gear =
        (jsonDecode(preferences.getString('cnc_companion.reference.gear.v1')!)
                as List<dynamic>)
            .map(
              (entry) => GearReferenceItem.fromJson(
                Map<String, dynamic>.from(entry as Map),
              ),
            )
            .toList();

    expect(gear.where((item) => item.category == 'Helms'), hasLength(11));
    expect(gear.where((item) => item.category == 'Equipment').length, 116);
    expect(gear.where((item) => item.category == 'Containers'), hasLength(21));
    expect(gear.any((item) => item.name == 'Custom Equipment'), isTrue);
    final armet = gear.firstWhere((item) => item.name == 'Armet');
    expect(armet.helmAc, 6);
    expect(armet.vs, 'Head only');
    final backpack = gear.firstWhere(
      (item) => item.category == 'Containers' && item.name == 'Backpack',
    );
    expect(backpack.encumbrance, '2');
    expect(backpack.worn, isTrue);
    expect(backpack.capacity, '8');
    final canteen = gear.firstWhere(
      (item) => item.category == 'Containers' && item.name == 'Canteen',
    );
    expect(canteen.capacity, '0.5');

    await tester.tap(find.text('Add race and class reference data'));
    await tester.pumpAndSettle();
    for (final entry in [
      ('Helms', ['Helm', 'AC', 'Vs', '']),
      ('Equipment', ['Name', 'Enc', 'Worn', '']),
      ('Containers', ['Container', 'Enc', 'Worn', 'Capacity', '']),
    ]) {
      final category = find.byKey(ValueKey('gear-category-${entry.$1}'));
      await tester.ensureVisible(category);
      await tester.tap(category);
      await tester.pumpAndSettle();
      final table = tester.widget<DataTable>(
        find.byKey(ValueKey('gear-table-${entry.$1}')),
      );
      expect(
        table.columns.map((column) => (column.label as Text).data),
        entry.$2,
      );
      if (entry.$1 == 'Equipment') {
        final backpack = table.rows.firstWhere(
          (row) => row.key == const ValueKey('gear-row-Equipment-Backpack'),
        );
        expect(
          backpack.cells.take(3).map((cell) => (cell.child as Text).data),
          ['Backpack', '2', 'W'],
        );
      }
      if (entry.$1 == 'Containers') {
        final canteenRow = table.rows.firstWhere(
          (row) => row.key == const ValueKey('gear-row-Containers-Canteen'),
        );
        expect(
          canteenRow.cells.take(4).map((cell) => (cell.child as Text).data),
          ['Canteen', '1', '—', '0.5'],
        );
      }
      await tester.tap(find.byTooltip('Back to reference data'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('character alignment is selected from the standard dropdown', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Aligned Hero',
    );
    final alignment = find.byKey(const ValueKey('character-alignment'));
    await tester.ensureVisible(alignment);
    await tester.tap(alignment);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chaotic Good').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    final savedCharacters = jsonDecode(
      preferences.getString('cnc_companion.characters.v1')!,
    ) as List<dynamic>;
    expect(savedCharacters.single['alignment'], 'Chaotic Good');
  });

  testWidgets('armor is equipped from Gear and magical bonuses affect AC', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Armored One',
    );

    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gear & Notes'));
    await tester.pumpAndSettle();

    final armorDropdown = find.byKey(const ValueKey('add-equipped-Armor-'));
    await tester.ensureVisible(armorDropdown);
    await tester.tap(armorDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Padded Armor (+1 AC)').last);
    await tester.pumpAndSettle();
    final shieldDropdown = find.byKey(const ValueKey('add-equipped-Shield-'));
    await tester.ensureVisible(shieldDropdown);
    await tester.tap(shieldDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buckler (+1 AC, 1 foes)').last);
    await tester.pumpAndSettle();
    final magicalCheckbox = find.byType(Checkbox).first;
    await tester.ensureVisible(magicalCheckbox);
    await tester.tap(magicalCheckbox);
    await tester.pumpAndSettle();
    final magicModifier = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(magicModifier);
    await tester.tap(magicModifier);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+2').last);
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    final savedCharacters = jsonDecode(
      preferences.getString('cnc_companion.characters.v1')!,
    ) as List<dynamic>;
    expect(savedCharacters.single['armorName'], 'Padded Armor');
    expect(savedCharacters.single['armorModifier'], 1);
    expect(savedCharacters.single['armorClass'], 14);
    final equippedGear =
        savedCharacters.single['equippedGear'] as List<dynamic>;
    final armor = equippedGear.firstWhere(
      (item) => item['category'] == 'Armor',
    );
    final shield = equippedGear.firstWhere(
      (item) => item['category'] == 'Shield',
    );
    expect(armor['magical'], isTrue);
    expect(armor['magicModifier'], 2);
    expect(shield['shieldAc'], 1);
    expect(shield['foes'], 1);
    expect(find.byKey(const ValueKey('armor-selection')), findsNothing);

    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('armor-class-breakdown')), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('armor-class-base-calculation')),
          )
          .data,
      '10 base +3 Armor (Padded Armor) +0 Dexterity = 13',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('armor-class-shield-calculation')),
          )
          .data,
      '+1 Buckler shield bonus applies against up to 1 attacker: AC 14.',
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('armor-class-extra-attackers')),
          )
          .data,
      'Against any additional attackers, the shield bonus does not apply: AC 13.',
    );
  });

  test(
    'weapon To Hit uses attack type and only that weapon magic modifier',
    () {
      final character = CharacterSheet(
        id: 'to-hit-test',
        name: 'Archer',
        race: 'Human',
        characterClass: 'Fighter',
        characterClasses: const ['Fighter'],
        level: 2,
        alignment: '',
        background: '',
        armorModifier: 0,
        currentHp: 10,
        maxHp: 10,
        experience: 2001,
        abilities: const {
          'Strength': 16,
          'Dexterity': 14,
          'Constitution': 10,
          'Intelligence': 10,
          'Wisdom': 10,
          'Charisma': 10,
        },
        primaryAttributes: const {},
        spells: const [],
        equipment: const [],
        notes: '',
        equippedGear: const [
          EquippedGearItem(
            id: 'magic-sword',
            category: 'Weapons',
            name: 'Magic Sword',
            magical: true,
            magicModifier: 2,
          ),
          EquippedGearItem(
            id: 'longbow',
            category: 'Weapons',
            name: 'Longbow',
            attackType: 'Ranged',
          ),
        ],
      );

      expect(character.classBth, 2);
      expect(character.toHitForWeapon(character.equippedGear[0]), 6);
      expect(character.toHitForWeapon(character.equippedGear[1]), 3);
    },
  );

  testWidgets('equipped weapons show separate To Hit values on the overview', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'cnc_companion.reference.gear.v1': jsonEncode([
        const GearReferenceItem(
          category: 'Weapons',
          name: 'Longsword',
        ).toJson(),
        const GearReferenceItem(
          category: 'Weapons',
          name: 'Shortbow',
          attackType: 'Ranged',
        ).toJson(),
      ]),
    });
    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a character'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Character name *'),
      'Weapon Tester',
    );
    final classField = find.byKey(const ValueKey('character-class-primary'));
    await tester.ensureVisible(classField);
    await tester.tap(classField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fighter').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save character'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gear & Notes'));
    await tester.pumpAndSettle();
    final weaponDropdown = find.byKey(const ValueKey('add-equipped-Weapons-'));
    await tester.ensureVisible(weaponDropdown);
    await tester.tap(weaponDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Longsword').last);
    await tester.pumpAndSettle();
    final nextWeaponDropdown = find.byWidgetPredicate(
      (widget) =>
          widget is DropdownButtonFormField<String> &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'add-equipped-Weapons-',
          ),
    );
    await tester.ensureVisible(nextWeaponDropdown);
    await tester.tap(nextWeaponDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shortbow').last);
    await tester.pumpAndSettle();

    final firstMagicalCheckbox = find.byType(Checkbox).first;
    await tester.ensureVisible(firstMagicalCheckbox);
    await tester.tap(firstMagicalCheckbox);
    await tester.pumpAndSettle();
    final magicModifier = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(magicModifier);
    await tester.tap(magicModifier);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+2').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();

    expect(find.text('To Hit'), findsOneWidget);
    expect(find.text('Longsword'), findsOneWidget);
    expect(find.text('Shortbow'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
  });

  testWidgets('class progressions match supplied rows', (
    WidgetTester tester,
  ) async {
    const progressions = {
      'Cleric': [
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
      'Druid': [
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
      'Fighter': [
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
      'Illusionist': [
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
      'Knight': [
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
      'Monk': [
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
      'Paladin': [
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
      'Ranger': [
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
      'Rogue': [
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
      'Wizard': [
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

    for (final entry in progressions.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReferenceDetailPage(kind: 'Class', name: entry.key),
            ),
          ),
        ),
      );
      final table = tester.widget<DataTable>(
        find.byKey(ValueKey('class-progression-${entry.key}')),
      );
      expect(table.rows, hasLength(20));
      expect(
        table.rows
            .map(
              (row) =>
                  row.cells.map((cell) => (cell.child as Text).data!).toList(),
            )
            .toList(),
        entry.value,
        reason: '${entry.key} progression',
      );
    }
  });

  testWidgets('renames saved Hafling options and characters to Halfling', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'cnc_companion.reference.defaults_seeded.v1': true,
      'cnc_companion.reference.races.v1': ['Dwarf', 'Hafling', 'Human'],
      'cnc_companion.reference.classes.v1': [],
      'cnc_companion.characters.v1': jsonEncode([
        {
          'id': 'legacy-race',
          'name': 'Legacy',
          'race': 'Hafling',
          'primaryAttributes': <String>[],
        },
      ]),
    });

    await tester.pumpWidget(const CncCompanionApp());
    await tester.pumpAndSettle();

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('cnc_companion.reference.races.v1'), [
      'Dwarf',
      'Halfling',
      'Human',
    ]);
    final characters = jsonDecode(
      preferences.getString('cnc_companion.characters.v1')!,
    ) as List<dynamic>;
    expect(characters.single['race'], 'Halfling');

    await tester.ensureVisible(find.text('Edit details'));
    await tester.tap(find.text('Edit details'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byType(DropdownButtonFormField<String>).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Halfling'), findsWidgets);
    expect(find.text('Hafling'), findsNothing);
  });

  test('legacy ancestry data loads as Race', () {
    final character = CharacterSheet.fromJson({
      'id': 'legacy',
      'name': 'Old Sheet',
      'ancestry': 'Dwarf',
    });

    expect(character.race, 'Dwarf');
    expect(character.toJson()['race'], 'Dwarf');
  });

  testWidgets('race reference tables show supplied base movement', (
    WidgetTester tester,
  ) async {
    const baseMoves = {
      'Human': '30',
      'Dwarf': '20',
      'Elf': '30',
      'Gnome': '20',
      'Half-Orc': '30',
      'Half-Elf': '30',
      'Halfling': '20',
    };

    for (final entry in baseMoves.entries) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReferenceDetailPage(kind: 'Race', name: entry.key),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final table = tester.widget<DataTable>(
        find.byKey(ValueKey('race-details-${entry.key}')),
      );
      expect(table.columns.map((column) => (column.label as Text).data), [
        'Race',
        'Base Move',
        'Attribute Modifiers',
        'Class Modifiers',
      ]);
      expect(
        (table.rows.single.cells[1].child as Text).data,
        entry.value,
        reason: '${entry.key} base move',
      );
    }
  });

  test('ability modifiers match the Castles and Crusades score table', () {
    const expectedModifiers = [
      -4,
      -3,
      -3,
      -2,
      -2,
      -1,
      -1,
      -1,
      0,
      0,
      0,
      0,
      1,
      1,
      1,
      2,
      2,
      3,
      3,
    ];

    for (var index = 0; index < expectedModifiers.length; index++) {
      expect(
        CharacterSheet.modifierForScore(index + 1),
        expectedModifiers[index],
        reason: 'Score ${index + 1}',
      );
    }
  });

  test('Armor Class uses armor modifier and effective Dexterity', () {
    final character = CharacterSheet.fromJson({
      'id': 'armor-class',
      'name': 'Armored',
      'race': 'Elf',
      'armorModifier': 2,
      'abilities': {'Dexterity': 16},
    });

    expect(character.statModifierFor('Dexterity'), 2);
    expect(character.armorClass, 14);
    final shielded = CharacterSheet.fromJson({
      'id': 'shielded-class',
      'name': 'Shielded',
      'race': 'Elf',
      'armorModifier': 2,
      'abilities': {'Dexterity': 16},
      'equippedGear': [
        {
          'id': 'buckler',
          'category': 'Shield',
          'name': 'Buckler',
          'shieldAc': 1,
          'foes': 1,
        },
      ],
    });
    expect(shielded.armorClass, 15);
    expect(
      CharacterSheet.fromJson({
        'id': 'legacy-armor',
        'name': 'Legacy armor',
        'race': 'Elf',
        'armorClass': 14,
        'abilities': {'Dexterity': 16},
      }).armorClass,
      14,
    );
  });

  test('modified saving target includes target, stat modifier, and level', () {
    final character = CharacterSheet.fromJson({
      'id': 'saving-throw-example',
      'name': 'Example',
      'level': 4,
      'abilities': {'Strength': 18},
      'primaryAttributes': ['Strength'],
    });

    expect(character.targetNumberFor('Strength'), 12);
    expect(character.statModifierFor('Strength'), 3);
    expect(character.level, 4);
    expect(character.modifiedTargetFor('Strength'), 5);
  });

  test('multiclass XP is split and uses shared-level requirements', () {
    final character = CharacterSheet.fromJson({
      'id': 'multiclass',
      'name': 'Three Classes',
      'characterClass': 'Ranger',
      'classes': ['Ranger', 'Monk', 'Wizard'],
      'classMode': 'multiclass',
      'level': 8,
      'experience': 1020002,
    });

    expect(character.classes, ['Ranger', 'Monk', 'Wizard']);
    expect(character.experiencePerClass, 340000);
    expect(character.experienceRequiredForNextLevel, 1020003);
    expect(character.copyWith(experience: 1020002).effectiveLevel, 8);
    expect(character.copyWith(experience: 1020003).effectiveLevel, 9);

    final restored = CharacterSheet.fromJson(character.toJson());
    expect(restored.classes, character.classes);
    expect(restored.classMode, 'multiclass');
    expect(restored.effectiveLevel, 8);
  });

  test('character level is derived from class experience progression', () {
    final ranger = CharacterSheet.fromJson({
      'id': 'ranger',
      'name': 'Ranger',
      'characterClass': 'Ranger',
      'level': 1,
      'experience': 250000,
    });
    expect(ranger.effectiveLevel, 8);
    expect(ranger.copyWith(experience: 250001).effectiveLevel, 9);

    final assassin = CharacterSheet.fromJson({
      'id': 'assassin',
      'name': 'Assassin',
      'characterClass': 'Assassin',
      'level': 1,
      'experience': 0,
    });
    expect(assassin.effectiveLevel, 1);
  });

  test('race attribute modifiers apply after rolled values and lineage', () {
    const expectedModifiers = {
      'Dwarf': {'Dexterity': -1, 'Constitution': 1},
      'Elf': {'Dexterity': 1, 'Constitution': -1},
      'Gnome': {'Strength': -1, 'Intelligence': 1},
      'Halfling': {'Strength': -1, 'Dexterity': 1},
      'Half-Orc': {'Strength': 1, 'Constitution': 1, 'Charisma': -2},
    };
    for (final entry in expectedModifiers.entries) {
      final character = CharacterSheet.fromJson({
        'id': entry.key,
        'name': entry.key,
        'race': entry.key,
        'abilities': {
          for (final ability in CharacterSheet.abilityNames) ability: 10,
        },
      });
      for (final ability in CharacterSheet.abilityNames) {
        expect(
          character.effectiveAbilities[ability],
          10 + (entry.value[ability] ?? 0),
          reason: '${entry.key} $ability',
        );
      }
    }

    final halfElf = CharacterSheet.fromJson({
      'id': 'half-elf',
      'name': 'Half-Elf',
      'race': 'Half-Elf',
      'raceLineage': 'Elf',
      'abilities': {'Dexterity': 12, 'Constitution': 14},
    });
    expect(halfElf.effectiveAbilities['Dexterity'], 13);
    expect(halfElf.effectiveAbilities['Constitution'], 13);
    expect(CharacterSheet.fromJson(halfElf.toJson()).raceLineage, 'Elf');
  });

  test(
    'primary attribute count is limited when race changes or data loads',
    () {
      final human = CharacterSheet.fromJson({
        'id': 'human',
        'name': 'Human',
        'race': 'Human',
        'primaryAttributes': ['Strength', 'Dexterity', 'Constitution'],
      });
      expect(human.primaryAttributes, {
        'Strength',
        'Dexterity',
        'Constitution',
      });

      final elf = human.copyWith(race: 'Elf');
      expect(elf.primaryAttributes, {'Strength', 'Dexterity'});
      expect(
        CharacterSheet.fromJson({
          'id': 'old',
          'name': 'Old character',
          'race': 'Dwarf',
          'primaryAttributes': ['Strength', 'Dexterity', 'Constitution'],
        }).primaryAttributes,
        {'Strength', 'Dexterity'},
      );
    },
  );
}

# C&C Companion

A Flutter companion for creating and managing Castles & Crusades characters.
Character sheets are saved locally on the device.

## Character sheet

- Create, edit, switch between, and delete characters.
- Track race, class, level, alignment, background, armor class, hit points,
  and experience.
- Character level is automatically determined from XP and the supplied class
  progression. Choose single-class, multiclass (up to three classes with XP
  split evenly and a shared level), or class-and-a-half advancement.
- First-level characters start with maximum HP for the highest selected class
  Hit Die, modified by Constitution. Each earned level can be applied once;
  roll or choose HP based on the highest selected Hit Die, add the Constitution
  modifier, and apply the total to Max HP (with at least 1 HP gained per level).
- Equip armor, helms, shields, containers, weapons, and equipment in Gear &
  Notes. One armor, helm, and shield can be equipped at a time; weapons and
  other gear can be added as needed. Each equipped item can be marked magical
  and assigned a -5 to +5 modifier.
- Armor Class is calculated as 10 + the equipped armor's base and magical
  modifiers + the equipped shield's AC value + Dexterity modifier. Without
  equipped armor, the legacy armor modifier is retained for existing characters.
  The Overview shows each part of the AC calculation. A shield's AC bonus
  applies only against up to the number of attackers listed for that shield;
  additional attackers do not receive its bonus.
- Overview To Hit values use class BtH plus Strength for melee weapons or
  Dexterity for ranged weapons, adding a weapon's magical modifier only to
  attacks made with that weapon. Weapon attack type is editable in its Gear
  reference entry.
- XP that qualifies for a higher level displays a level-up notice. Assigned
  ability rolls receive the selected race's attribute modifiers, and the
  sheet displays the resulting scores. The underlying assigned scores remain
  unchanged, so changing a race does not stack modifiers.
- View the XP required for the next level. Class-and-a-half adds the
  half-class XP threshold at half the primary level, rounded down.
- Enter ability scores when creating or editing a character, or roll six
  configurable dice-based scores and assign each roll to an attribute. The
  default is 4d6, dropping the lowest die. Unassigned scores stay visible in
  the available pool; clearing an assignment returns that roll to the pool.
- Review and update the six ability scores and their modifiers.
- Select up to three primary attributes for Humans or two for other races.
  Saving throw target numbers, stat modifiers, level modifiers, and modified
  target numbers update automatically.
- Saving throw modified targets are calculated as target number minus the
  ability modifier and character level.
- Record spells, equipment, and adventure notes.
- Maintain local reference tables for campaign races, classes, and gear.
  Gear reference entries populate the corresponding selection in Gear & Notes.
  The Weapons table is seeded with the supplied weapon catalog, including
  damage, special properties, and melee/ranged type; entries can be edited
  along with custom weapon references. The Shields table includes AC bonuses
  and the number of foes each shield can defend against.
  Helm references include head-only AC and the protected location. Equipment
  references include encumbrance and whether an item is worn; container
  references also include capacity. Character alignments are selected from the
  standard nine-alignment list.

Open **Reference data** from the sidebar (desktop) or the book icon / empty
character screen (mobile) to manage race and class options. Race options are
seeded alphabetically as Dwarf, Elf, Gnome, Halfling, Half-Elf, Half-Orc, and
Human. Classes are seeded alphabetically from Assassin through Wizard. Custom
entries are saved on the device. Existing characters keep their recorded race
and class even if an option is later removed from the reference lists.
Previously saved `Hafling` options and character races are migrated to
`Halfling`.
The Spells reference page stores campaign spell details separately from each
character's spellbook. Spell entries can be added, edited, and removed using
the Spell Name, Class, Level, CT, R, D, SV, SR, and Comp fields. Use the
filter field beneath any table header to narrow spells by that column; filters
can be combined.
Cleric and Druid class references include the supplied level 1–20 spells-per-day
table. Their character Spellbook sections show daily slots for the character's
current class level. Illusionist and Wizard references and character Spellbook
sections use their supplied arcane spells-per-day progression.
The Spells section shows Cleric and Druid reference spells up to the highest
spell level available to that character. Wizard and Illusionist spell lists are
chosen from matching-class spells in the Spells reference data.
Select any race or class in the Reference Data lists to open its individual
reference page. Race pages show base movement, attribute modifiers, and class
modifiers; class pages include a progression table with Level, HD, BtH, and
Exp. columns.
The Assassin, Barbarian, Bard, Cleric, Druid, Fighter, Illusionist, Knight,
Monk, Paladin, Ranger, Rogue, and Wizard pages include their supplied 1–20
progressions. Remaining class tables are ready for campaign reference data.

Run the app with `flutter run`. Run the widget tests with `flutter test`.

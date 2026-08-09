import 'package:flutter_test/flutter_test.dart';
import 'package:simplymind/models/mind_map.dart';

void main() {
  test('category round-trips through JSON; missing means Home', () {
    final home = MindMap.create(title: 'Home map', centerX: 0, centerY: 0);
    expect(home.category, isNull);
    expect(home.categoryOrHome, kHomeCategory);
    expect(home.isInHome, isTrue);

    final encoded = MindMap.decode(home.encode());
    expect(encoded.category, isNull);
    expect(encoded.toJson().containsKey('category'), isFalse);

    final work = MindMap.create(
      title: 'Work map',
      centerX: 0,
      centerY: 0,
      category: 'Work',
    );
    expect(work.category, 'Work');
    expect(work.categoryOrHome, 'Work');

    final restored = MindMap.decode(work.encode(pretty: true));
    expect(restored.category, 'Work');
    expect(restored.toJson()['category'], 'Work');
  });

  test('setting category to Home or empty clears the field', () {
    final map = MindMap.create(
      title: 'T',
      centerX: 0,
      centerY: 0,
      category: 'Personal',
    );
    map.setCategory(kHomeCategory);
    expect(map.category, isNull);
    expect(map.isInHome, isTrue);

    map.setCategory('Ideas');
    expect(map.category, 'Ideas');
    map.setCategory('');
    expect(map.category, isNull);
  });

  test('copy preserves category; duplicate keeps category', () {
    final map = MindMap.create(
      title: 'T',
      centerX: 0,
      centerY: 0,
      category: 'School',
    );
    final copy = map.copy(newMapId: newId());
    expect(copy.category, 'School');
    expect(copy.id, isNot(map.id));
  });

  test('deleting a category reassigns maps to Home', () {
    // Mirrors home_screen _deleteCategory persistence logic.
    final maps = [
      MindMap.create(title: 'A', centerX: 0, centerY: 0, category: 'Work'),
      MindMap.create(title: 'B', centerX: 0, centerY: 0, category: 'Work'),
      MindMap.create(title: 'C', centerX: 0, centerY: 0, category: 'Home'),
      MindMap.create(title: 'D', centerX: 0, centerY: 0),
    ];
    const deleted = 'Work';
    for (final m in maps) {
      if (m.category == deleted) m.setCategory(null);
    }
    expect(maps.every((m) => m.isInHome || m.category != deleted), isTrue);
    expect(maps.where((m) => m.title == 'A' || m.title == 'B').every((m) => m.isInHome),
        isTrue);
    expect(maps.where((m) => m.title == 'C' || m.title == 'D').every((m) => m.isInHome),
        isTrue);
  });

  test('category offer threshold constant is 17', () {
    expect(kCategoryOfferThreshold, 17);
  });
}

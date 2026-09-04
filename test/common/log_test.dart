/*
 * Trireme for Deluge - A Deluge thin client for Android.
 * Copyright (C) 2018  Aashrava Holla
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:trireme/common/log.dart';

void main() {
  setUp(Log.clear);

  test('records entries even when console printing is disabled', () {
    expect(Log.level, Log.none);

    Log.e('tag', 'boom');

    expect(Log.entries, hasLength(1));
    expect(Log.entries.single.tag, 'tag');
    expect(Log.entries.single.message, 'boom');
    expect(Log.entries.single.level, Log.error);
  });

  test('keeps only the newest entries after reaching the cap', () {
    for (var i = 0; i < Log.maxEntries + 10; i++) {
      Log.d('tag', 'entry $i');
    }

    expect(Log.entries, hasLength(Log.maxEntries));
    expect(Log.entries.first.message, 'entry 10');
    expect(Log.entries.last.message, 'entry ${Log.maxEntries + 9}');
  });

  test('clear empties the buffer', () {
    Log.i('tag', 'something');
    expect(Log.entries, isNotEmpty);

    Log.clear();

    expect(Log.entries, isEmpty);
  });

  test('entries render with timestamp, level, tag and message', () {
    Log.w('banner', 'careful');

    final line = Log.entries.single.toString();
    expect(line, contains('W/banner: careful'));
    expect(line, matches(RegExp(r'^\d{2}:\d{2}:\d{2}\.\d{3} ')));
  });

  test('broadcasts new entries', () async {
    final seen = <LogEntry>[];
    final subscription = Log.entryStream.listen(seen.add);

    Log.i('tag', 'first');
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(seen, hasLength(1));
    expect(seen.single.message, 'first');
  });
}

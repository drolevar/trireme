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
import 'package:trireme/settings/debug.dart';

import '../support/pump.dart';

void main() {
  setUp(Log.clear);

  testWidgets('shows connection state and the captured in-app log',
      (tester) async {
    Log.d('TorrentListController', 'Full list refresh completed: items=1');

    await tester.pumpWidget(triremeApp(const DebugScreen()));
    await tester.pump();

    expect(find.text('Debug'), findsOneWidget);
    expect(find.text('Client attached'), findsOneWidget);
    expect(find.text('no'), findsOneWidget);
    expect(
      find.textContaining(
          'D/TorrentListController: Full list refresh completed: items=1'),
      findsOneWidget,
    );

    await unmountAndDrainTimers(tester);
  });
}

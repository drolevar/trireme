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

import 'dart:async';
import 'dart:collection';

class LogEntry {
  final DateTime time;
  final int level;
  final String tag;
  final String message;

  const LogEntry(this.time, this.level, this.tag, this.message);

  String get levelName {
    switch (level) {
      case Log.error:
        return "E";
      case Log.warn:
        return "W";
      case Log.info:
        return "I";
      case Log.debug:
        return "D";
      default:
        return "V";
    }
  }

  String get timestamp {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(time.hour)}:${two(time.minute)}:${two(time.second)}"
        ".${time.millisecond.toString().padLeft(3, '0')}";
  }

  @override
  String toString() => "$timestamp $levelName/$tag: $message";
}

class Log {
  static const none = 10;
  static const error = 8;
  static const warn = 6;
  static const info = 4;
  static const debug = 2;
  static const verbose = 0;

  // Controls printing only. Recording is unconditional, because the whole
  // point of the in-app log is to be there for a problem that has already
  // happened -- nobody gets to raise the level in advance.
  static int level = none;

  static const maxEntries = 500;

  static final Queue<LogEntry> _entries = Queue<LogEntry>();
  static final StreamController<LogEntry> _entryStream =
      StreamController<LogEntry>.broadcast();

  /// Newest last, capped at [maxEntries].
  static List<LogEntry> get entries => List.unmodifiable(_entries);

  static Stream<LogEntry> get entryStream => _entryStream.stream;

  static void clear() => _entries.clear();

  static void v(String tag, String msg) {
    _log(tag, msg, verbose);
  }

  static void d(String tag, String msg) {
    _log(tag, msg, debug);
  }

  static void i(String tag, String msg) {
    _log(tag, msg, info);
  }

  static void w(String tag, String msg) {
    _log(tag, msg, warn);
  }

  static void e(String tag, String msg) {
    _log(tag, msg, error);
  }

  static void _log(String tag, String msg, int level) {
    final entry = LogEntry(DateTime.now(), level, tag, msg);
    _entries.addLast(entry);
    while (_entries.length > maxEntries) {
      _entries.removeFirst();
    }
    _entryStream.add(entry);

    if (level >= Log.level) {
      print("$tag : $msg");
    }
  }
}

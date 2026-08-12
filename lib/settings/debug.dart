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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:trireme/common/common.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<StatefulWidget> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  static const _tag = "_DebugScreenState";

  late TriremeRepository repository;
  StreamSubscription<LogEntry>? _logSubscription;
  StreamSubscription<Object>? _errorSubscription;

  var _errorCount = 0;
  Object? _lastError;
  DateTime? _lastErrorTime;

  String? _probeResult;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    repository = RepositoryProvider.repositoryOf(context);

    _logSubscription?.cancel();
    _logSubscription = Log.entryStream.listen((_) {
      if (mounted) setState(() {});
    });

    _errorSubscription?.cancel();
    _errorSubscription = repository.errorStream().listen((e) {
      if (!mounted) return;
      setState(() {
        _errorCount++;
        _lastError = e;
        _lastErrorTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = Log.entries.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.settingsDebug),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: Strings.debugCopyLog,
            onPressed: entries.isEmpty ? null : _copyLog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: Strings.debugClearLog,
            onPressed: entries.isEmpty ? null : _clearLog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatus(),
          const Divider(height: 1.0),
          Expanded(child: _buildLog(entries)),
        ],
      ),
    );
  }

  Widget _buildStatus() {
    final ready = repository.isReady();
    // Reading client at all throws when none was ever attached.
    final disposed = ready ? repository.client.isDisposed : null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(Strings.debugClientAttached, ready ? "yes" : "no"),
          _row(Strings.debugClientDisposed,
              disposed == null ? "-" : (disposed ? "yes" : "no")),
          _row(Strings.debugErrorsSeen, _errorCount.toString()),
          if (_lastError != null)
            _row(Strings.debugLastError,
                "${_formatTime(_lastErrorTime!)}  $_lastError"),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            children: [
              OutlinedButton(
                onPressed: _pingDaemon,
                child: Text(Strings.debugPingDaemon),
              ),
              OutlinedButton(
                onPressed: _querySessionPaused,
                child: Text(Strings.debugQuerySessionPaused),
              ),
            ],
          ),
          if (_probeResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(_probeResult!),
            ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140.0, child: Text(label)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildLog(List<LogEntry> entries) {
    if (entries.isEmpty) {
      return Center(child: Text(Strings.debugNoLog));
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Text(
            entry.toString(),
            style: TextStyle(
              fontFamily: "monospace",
              fontSize: 12.0,
              color: entry.level >= Log.warn
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(t.hour)}:${two(t.minute)}:${two(t.second)}";
  }

  void _pingDaemon() async {
    setState(() => _probeResult = "${Strings.debugPingDaemon}...");
    try {
      final info = await repository.getDaemonInfo();
      Log.i(_tag, "Daemon info: $info");
      if (mounted) setState(() => _probeResult = "daemon: $info");
    } catch (e) {
      Log.e(_tag, "Daemon ping failed: $e");
      if (mounted) setState(() => _probeResult = "daemon ping failed: $e");
    }
  }

  void _querySessionPaused() async {
    setState(() => _probeResult = "${Strings.debugQuerySessionPaused}...");
    try {
      final paused = await repository.isSessionPaused();
      Log.i(_tag, "isSessionPaused: $paused");
      if (mounted) setState(() => _probeResult = "isSessionPaused: $paused");
    } catch (e) {
      Log.e(_tag, "isSessionPaused failed: $e");
      if (mounted) setState(() => _probeResult = "isSessionPaused failed: $e");
    }
  }

  void _copyLog() async {
    final text = Log.entries.map((e) => e.toString()).join("\n");
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(Strings.debugLogCopied)));
  }

  void _clearLog() {
    Log.clear();
    setState(() {
      _errorCount = 0;
      _lastError = null;
      _lastErrorTime = null;
      _probeResult = null;
    });
  }
}

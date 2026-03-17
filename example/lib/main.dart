import 'dart:convert';

import 'package:eventflux/eventflux.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const EventFluxDemoApp());
}

class EventFluxDemoApp extends StatelessWidget {
  const EventFluxDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventFlux Demo',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const SSEDemoPage(),
    );
  }
}

class SSEDemoPage extends StatefulWidget {
  const SSEDemoPage({super.key});

  @override
  State<SSEDemoPage> createState() => _SSEDemoPageState();
}

class _SSEDemoPageState extends State<SSEDemoPage> {
  static const _sseUrl =
      'https://stream.wikimedia.org/v2/stream/recentchange';
  static const _maxEvents = 20;

  EventFlux? _eventFlux;
  EventFluxStatus _status = EventFluxStatus.disconnected;
  final List<Map<String, dynamic>> _events = [];
  String? _errorMessage;

  @override
  void dispose() {
    _eventFlux?.disconnect();
    _eventFlux = null;
    super.dispose();
  }

  void _connect() {
    if (_status == EventFluxStatus.connected ||
        _status == EventFluxStatus.connectionInitiated) {
      return;
    }

    setState(() {
      _status = EventFluxStatus.connectionInitiated;
      _errorMessage = null;
    });

    _eventFlux = EventFlux.spawn();
    _eventFlux!.connect(
      EventFluxConnectionType.get,
      _sseUrl,
      onSuccessCallback: (response) {
        setState(() => _status = EventFluxStatus.connected);
        response?.stream?.listen((event) {
          if (event.data.isNotEmpty) {
            try {
              final parsed =
                  jsonDecode(event.data) as Map<String, dynamic>;
              setState(() {
                _events.insert(0, parsed);
                if (_events.length > _maxEvents) {
                  _events.removeLast();
                }
              });
            } catch (_) {
              // skip non-JSON lines
            }
          }
        });
      },
      onError: (exception) {
        setState(() {
          _status = EventFluxStatus.error;
          _errorMessage =
              exception.message ?? 'Connection error';
        });
      },
      onConnectionClose: () {
        if (mounted) {
          setState(() => _status = EventFluxStatus.disconnected);
        }
      },
      autoReconnect: true,
      reconnectConfig: ReconnectConfig(
        mode: ReconnectMode.exponential,
        interval: const Duration(seconds: 2),
        maxAttempts: 5,
        onReconnect: () {
          if (mounted) {
            setState(
                () => _status = EventFluxStatus.connectionInitiated);
          }
        },
      ),
      webConfig: kIsWeb
          ? WebConfig(
              mode: WebConfigRequestMode.cors,
              credentials: WebConfigRequestCredentials.omit,
            )
          : null,
    );
  }

  void _disconnect() {
    _eventFlux?.disconnect();
    _eventFlux = null;
    if (mounted) {
      setState(() => _status = EventFluxStatus.disconnected);
    }
  }

  Color get _statusColor => switch (_status) {
        EventFluxStatus.connected => Colors.green,
        EventFluxStatus.connectionInitiated => Colors.orange,
        EventFluxStatus.error => Colors.red,
        EventFluxStatus.disconnected => Colors.grey,
      };

  String get _statusLabel => switch (_status) {
        EventFluxStatus.connected => 'Connected',
        EventFluxStatus.connectionInitiated => 'Connecting…',
        EventFluxStatus.error => 'Error',
        EventFluxStatus.disconnected => 'Disconnected',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EventFlux SSE Demo'),
      ),
      body: Column(
        children: [
          // Status bar + controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _statusLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                if (_status == EventFluxStatus.connected ||
                    _status ==
                        EventFluxStatus.connectionInitiated)
                  FilledButton.tonal(
                    onPressed: _disconnect,
                    child: const Text('Disconnect'),
                  )
                else
                  FilledButton(
                    onPressed: _connect,
                    child: const Text('Connect'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Event list
          Expanded(
            child: _events.isEmpty
                ? Center(
                    child: Text(
                      _status == EventFluxStatus.disconnected
                          ? 'Tap Connect to start streaming Wikipedia edits'
                          : 'Waiting for events…',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _events.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = _events[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          (e['title'] as String?) ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${e['wiki'] ?? ''}  •  ${e['type'] ?? ''}',
                        ),
                        trailing: Text(
                          (e['user'] as String?) ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

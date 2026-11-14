import 'dart:async';

import 'package:aquagrow_mobile/app/shell/offline_banner.dart';
import 'package:aquagrow_mobile/core/constants/app_constants.dart';
import 'package:aquagrow_mobile/core/models/sensor_reading.dart';
import 'package:aquagrow_mobile/core/simulation/pod_simulator.dart';
import 'package:aquagrow_mobile/data/data_providers.dart';
import 'package:aquagrow_mobile/features/sync/application/sync_providers.dart';
import 'package:aquagrow_mobile/features/sync/domain/sync_queue.dart';
import 'package:aquagrow_mobile/features/sync/domain/telemetry_uploader.dart';
import 'package:aquagrow_mobile/features/sync/presentation/sync_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _CountingUploader implements TelemetryUploader {
  int uploaded = 0;

  @override
  Future<void> upload(List<SensorReading> readings) async {
    uploaded += readings.length;
  }
}

SensorReading _reading(int i) => SensorReading(
      id: 'r$i',
      deviceId: 'pod-alpha',
      ph: 6,
      tdsPpm: 800,
      ecMs: 1.6,
      waterTempC: 21,
      waterLevelPct: 80,
      recordedAt: DateTime(2026, 11, 15, 10).add(Duration(seconds: i)),
    );

void main() {
  test('pluralises the message', () {
    expect(SyncListener.messageFor(1), 'Back online · 1 reading synced');
    expect(SyncListener.messageFor(37), 'Back online · 37 readings synced');
  });

  testWidgets('shows readings synced when the connection returns',
      (tester) async {
    final offline = StreamController<bool>();
    addTearDown(offline.close);
    final queue =
        InMemorySyncQueue(capacity: AppConstants.maxOfflineQueueItems);
    final uploader = _CountingUploader();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          podSimulatorProvider.overrideWithValue(
            PodSimulator(clock: () => DateTime(2026, 11, 15, 10)),
          ),
          isOfflineProvider.overrideWith((ref) => offline.stream),
          syncQueueProvider.overrideWithValue(queue),
          telemetryUploaderProvider.overrideWithValue(uploader),
          readingCacheProvider.overrideWithValue((_) async {}),
        ],
        child: const MaterialApp(
          home: SyncListener(child: Scaffold(body: Text('Home'))),
        ),
      ),
    );

    offline.add(true);
    await tester.pump();
    for (var i = 0; i < 37; i++) {
      await queue.add(_reading(i));
    }

    offline.add(false);
    await tester.pump();
    await tester.pump();

    expect(uploader.uploaded, 37);
    expect(find.text('Back online · 37 readings synced'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:aquagrow_mobile/core/errors/app_failure.dart';
import 'package:aquagrow_mobile/core/interfaces/i_control_repository.dart';
import 'package:aquagrow_mobile/data/supabase/supabase_control_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeControlSource implements ControlSource {
  Map<String, dynamic> row = {
    'id': 'pod-1',
    'is_online': true,
    'pump_on': true,
    'light_on': true,
    'light_brightness': 80,
    'mist_on': true,
    'ph_dose_requested_at': null,
  };
  final updates = <Map<String, dynamic>>[];
  // ignore: close_sinks, closed in tearDown.
  final changesController = StreamController<Map<String, dynamic>>.broadcast();
  bool failing = false;

  @override
  Future<Map<String, dynamic>> fetchDevice(String podId) async {
    if (failing) throw Exception('offline');
    return row;
  }

  @override
  Stream<Map<String, dynamic>> deviceChanges(String podId) =>
      changesController.stream;

  @override
  Future<void> updateDevice(String podId, Map<String, dynamic> values) async =>
      updates.add(values);
}

void main() {
  late FakeControlSource source;
  late SupabaseControlRepository repo;

  setUp(() {
    source = FakeControlSource();
    repo = SupabaseControlRepository(
      source,
      clock: () => DateTime.utc(2026, 11, 16, 15),
    );
  });
  tearDown(() => source.changesController.close());

  test('watchActuators emits the row now, then each realtime change', () async {
    final states = repo.watchActuators('pod-1').take(2).toList();
    await Future<void>.delayed(Duration.zero);
    source.changesController.add({
      ...source.row,
      'pump_on': false,
      'light_brightness': 40,
    });

    final result = await states;
    expect(result.first.pumpOn, isTrue);
    expect(result.last.pumpOn, isFalse);
    expect(result.last.lightBrightness, 40);
  });

  test('commands write the wanted state on the device row', () async {
    await repo.setPump('pod-1', on: false);
    await repo.setLight('pod-1', on: true, brightness: 140);
    final dose = await repo.dosePhDown('pod-1');
    await repo.markRefilled('pod-1');
    await repo.setMist('pod-1', on: false);

    expect(dose, PhDoseResult.applied);
    expect(source.updates, [
      {'pump_on': false},
      {'light_on': true, 'light_brightness': 100},
      {'ph_dose_requested_at': '2026-11-16T15:00:00.000Z'},
      {'refill_requested_at': '2026-11-16T15:00:00.000Z'},
      {'mist_on': false},
    ]);
  });

  test('an offline pod refuses commands with a DeviceFailure', () async {
    source.row = {...source.row, 'is_online': false};

    await expectLater(
      repo.setPump('pod-1', on: false),
      throwsA(isA<DeviceFailure>()),
    );
    expect(source.updates, isEmpty);
  });

  test('no connection is a friendly NetworkFailure', () async {
    source.failing = true;

    await expectLater(
      repo.setLight('pod-1', on: false),
      throwsA(isA<NetworkFailure>()),
    );
  });
}

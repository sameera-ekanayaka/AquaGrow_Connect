import 'package:aquagrow_mobile/core/models/sensor_metric.dart';
import 'package:aquagrow_mobile/core/models/sensor_status.dart';
import 'package:aquagrow_mobile/features/alerts/domain/alert_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 11, 15, 10);
  late AlertRules rules;

  setUp(() => rules = AlertRules());

  SensorStatus? ph(SensorStatus status, DateTime at) => rules.evaluate(
        podId: 'pod-alpha',
        metric: SensorMetric.ph,
        status: status,
        now: at,
      );

  test('normal to critical raises one critical alert', () {
    expect(ph(SensorStatus.normal, t0), isNull);
    expect(
      ph(SensorStatus.critical, t0.add(const Duration(seconds: 2))),
      SensorStatus.critical,
    );
  });

  test('staying critical raises no more alerts', () {
    ph(SensorStatus.critical, t0);
    for (var i = 1; i <= 200; i++) {
      expect(
        ph(SensorStatus.critical, t0.add(Duration(seconds: 2 * i))),
        isNull,
      );
    }
  });

  test('a pod that is already critical on the first reading raises an alert',
      () {
    expect(ph(SensorStatus.critical, t0), SensorStatus.critical);
  });

  test('cooldown blocks a repeat within 5 minutes', () {
    expect(ph(SensorStatus.critical, t0), SensorStatus.critical);
    expect(ph(SensorStatus.normal, t0.add(const Duration(minutes: 1))), isNull);
    expect(
      ph(
        SensorStatus.critical,
        t0.add(const Duration(minutes: 4, seconds: 59)),
      ),
      isNull,
    );
  });

  test('recovery then a new drop after the cooldown raises again', () {
    expect(ph(SensorStatus.critical, t0), SensorStatus.critical);
    expect(ph(SensorStatus.normal, t0.add(const Duration(minutes: 2))), isNull);
    expect(
      ph(SensorStatus.critical, t0.add(const Duration(minutes: 5))),
      SensorStatus.critical,
    );
  });

  test(
      'warning then critical raises both, critical then warning raises nothing',
      () {
    expect(ph(SensorStatus.warning, t0), SensorStatus.warning);
    expect(
      ph(SensorStatus.critical, t0.add(const Duration(seconds: 2))),
      SensorStatus.critical,
    );
    expect(
      ph(SensorStatus.warning, t0.add(const Duration(seconds: 4))),
      isNull,
    );
  });

  test('pods and metrics are tracked separately', () {
    expect(ph(SensorStatus.critical, t0), SensorStatus.critical);
    expect(
      rules.evaluate(
        podId: 'pod-beta',
        metric: SensorMetric.ph,
        status: SensorStatus.critical,
        now: t0,
      ),
      SensorStatus.critical,
    );
    expect(
      rules.evaluate(
        podId: 'pod-alpha',
        metric: SensorMetric.waterLevel,
        status: SensorStatus.critical,
        now: t0,
      ),
      SensorStatus.critical,
    );
  });

  test('reset forgets past alerts', () {
    ph(SensorStatus.critical, t0);
    rules.reset();
    expect(
      ph(SensorStatus.critical, t0.add(const Duration(seconds: 1))),
      SensorStatus.critical,
    );
  });
}

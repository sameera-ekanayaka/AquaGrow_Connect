import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The time Home uses for "Updated 12s ago" and the crop's day number.
///
/// Tests override it with the simulator's fixed clock so text never depends
/// on the real time.
final homeClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

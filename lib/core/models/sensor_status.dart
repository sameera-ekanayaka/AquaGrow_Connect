/// Whether a reading is inside its target range.
///
/// - [normal]: inside the target range.
/// - [warning]: outside the target, but not yet harmful. Shown in amber.
/// - [critical]: harmful to plants if not fixed soon. Shown in red and raises an alert.
enum SensorStatus { normal, warning, critical }

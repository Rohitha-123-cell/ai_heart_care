import 'package:flutter/foundation.dart';
import '../../models/gender.dart';

/// Base class for all Gender BLoC events
@immutable
abstract class GenderEvent {}

/// Event fired when user selects a gender
class SelectGender extends GenderEvent {
  final Gender gender;

  SelectGender({required this.gender});

  @override
  String toString() => 'SelectGender(gender: $gender)';
}

/// Event fired when user presses the Next button
class GenderNextPressed extends GenderEvent {
  GenderNextPressed();

  @override
  String toString() => 'GenderNextPressed()';
}

/// Event fired when user presses the Back button
class GenderBackPressed extends GenderEvent {
  GenderBackPressed();

  @override
  String toString() => 'GenderBackPressed()';
}

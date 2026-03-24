/// Gender enum for patient selection
enum Gender {
  male,
  female,
}

/// Extension to get display name for gender
extension GenderExtension on Gender {
  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
    }
  }
}

import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

enum AppAuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsHealthData,
  error,
}

class AppAuthState extends Equatable {
  final AppAuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool hasHealthData;

  const AppAuthState({
    this.status = AppAuthStatus.initial,
    this.user,
    this.errorMessage,
    this.hasHealthData = false,
  });

  AppAuthState copyWith({
    AppAuthStatus? status,
    User? user,
    String? errorMessage,
    bool? hasHealthData,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      hasHealthData: hasHealthData ?? this.hasHealthData,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, hasHealthData];
}

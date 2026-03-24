import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AppAuthState> {
  final SupabaseClient _client;

  AuthBloc({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        super(const AppAuthState()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(state.copyWith(status: AppAuthStatus.loading));

    try {
      await _client.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );

      // Check if user has health data
      final hasHealthData = await _checkUserHasHealthData();

      if (hasHealthData) {
        emit(state.copyWith(
          status: AppAuthStatus.authenticated,
          user: _client.auth.currentUser,
          hasHealthData: true,
        ));
      } else {
        emit(state.copyWith(
          status: AppAuthStatus.needsHealthData,
          user: _client.auth.currentUser,
          hasHealthData: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AppAuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(state.copyWith(status: AppAuthStatus.loading));

    try {
      await _client.auth.signUp(
        email: event.email,
        password: event.password,
      );

      emit(state.copyWith(
        status: AppAuthStatus.needsHealthData,
        user: _client.auth.currentUser,
        hasHealthData: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AppAuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    await _client.auth.signOut();
    emit(const AppAuthState(status: AppAuthStatus.unauthenticated));
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    final user = _client.auth.currentUser;

    if (user != null) {
      final hasHealthData = await _checkUserHasHealthData();
      
      emit(state.copyWith(
        status: hasHealthData ? AppAuthStatus.authenticated : AppAuthStatus.needsHealthData,
        user: user,
        hasHealthData: hasHealthData,
      ));
    } else {
      emit(const AppAuthState(status: AppAuthStatus.unauthenticated));
    }
  }

  Future<bool> _checkUserHasHealthData() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      // Check if user has health data in health_metrics table
      final response = await _client
          .from('health_metrics')
          .select()
          .eq('user_id', user.id)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      // If table doesn't exist or error, assume no health data
      return false;
    }
  }
}

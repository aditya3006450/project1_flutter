import 'package:bloc/bloc.dart';
import 'package:project1_flutter/app/pages/login/bloc/login_events.dart';
import 'package:project1_flutter/app/pages/login/bloc/login_state.dart';
import 'package:project1_flutter/core/repositories/auth_repository.dart';
import 'package:project1_flutter/core/storage/hive_storage.dart';
import 'package:project1_flutter/core/storage/storage_keys.dart';

class LoginBloc extends Bloc<LoginEvents, LoginStates> {
  final AuthRepository authRepository;
  String _email = '';
  String _password = '';

  LoginBloc(this.authRepository) : super(LoginInitial()) {
    on<EmailChanged>((event, emit) {
      _email = event.email;
    });

    on<PasswordChanged>((event, emit) {
      _password = event.password;
    });

    on<LoginSubmitted>((event, emit) async {
      emit(LoginLoading());
      try {
        String token = await authRepository.login(
          email: _email,
          password: _password,
        );
        HiveStorage().set(StorageKeys.authToken, token);
        emit(LoginSuccess(token));
      } catch (e) {
        emit(LoginFailure(e.toString()));
      }
    });
  }
}

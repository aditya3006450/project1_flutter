import 'package:bloc/bloc.dart';
import 'package:project1_flutter/app/pages/signup/bloc/signup_events.dart';
import 'package:project1_flutter/app/pages/signup/bloc/signup_state.dart';
import 'package:project1_flutter/core/repositories/auth_repository.dart';

class SignupBloc extends Bloc<SignupEvents, SignupState> {
  final AuthRepository authRepository;
  String _email = "";
  SignupBloc(this.authRepository) : super(SignupInitial()) {
    on<EmailChanged>((event, emit) {
      _email = event.email;
    });

    on<SignupSubmitted>((event, emit) async {
      emit(SignupLoading());
      try {
        bool status = await authRepository.signup(email: _email);
        if (status) {
          emit(SignupSuccess());
        } else {
          throw "unable to signup";
        }
      } catch (e) {
        emit(SignupFailure(e.toString()));
      }
    });
  }
}

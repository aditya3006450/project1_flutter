abstract class LoginStates {}

class LoginInitial extends LoginStates {}

class LoginLoading extends LoginStates {}

class LoginSuccess extends LoginStates {
  final String token;
  LoginSuccess(this.token);
}

class LoginFailure extends LoginStates {
  final String error;
  LoginFailure(this.error);
}

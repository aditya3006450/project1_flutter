abstract class LoginEvents {}

class EmailChanged extends LoginEvents {
  final String email;

  EmailChanged(this.email);
}

class PasswordChanged extends LoginEvents {
  final String password;
  PasswordChanged(this.password);
}

class LoginSubmitted extends LoginEvents {}

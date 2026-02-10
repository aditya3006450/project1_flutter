abstract class SignupEvents {}

class EmailChanged extends SignupEvents {
  final String email;
  EmailChanged(this.email);
}

class SignupSubmitted extends SignupEvents {}

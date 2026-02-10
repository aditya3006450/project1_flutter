import 'package:project1_flutter/constants/constants.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final Dio dio = Dio();
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      LOGIN_URL,
      data: {"email": email, "password": password},
    );
    if (response.statusCode == 200) {
      return response.data['token'];
    }
    throw Exception('Login failed with status: ${response.statusCode}');
  }

  Future<bool> signup({required String email}) async {
    final response = await dio.post(SIGNUP_URL, data: {"email": email});
    if (response.statusCode == 201) {
      return true;
    }
    throw Exception('Login failed with status: ${response.statusCode}');
  }
}

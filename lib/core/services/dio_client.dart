import 'package:dio/dio.dart';
import 'package:project1_flutter/core/storage/hive_storage.dart';
import 'package:project1_flutter/core/storage/storage_keys.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = HiveStorage().get<String>(StorageKeys.authToken);
          if (token != null) {
            options.headers['authorization'] = token;
          }
          return handler.next(options);
        },
      ),
    );
  }
}

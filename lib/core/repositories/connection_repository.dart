import 'package:project1_flutter/constants/constants.dart';
import 'package:project1_flutter/core/services/dio_client.dart';

class ConnectionRepository {
  final _dio = DioClient().dio;

  List<Map<String, dynamic>> _parseResponse(dynamic data) {
    if (data is List) {
      return data.map((item) => Map<String, dynamic>.from(item)).toList();
    } else if (data is Map<String, dynamic>) {
      if (data.containsKey('res') && data['res'] is List) {
        return (data['res'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (data.containsKey('data') && data['data'] is List) {
        return (data['data'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (data.containsKey('requests') && data['requests'] is List) {
        return (data['requests'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (data.containsKey('results') && data['results'] is List) {
        return (data['results'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        return [data];
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getConnectedTo() async {
    final response = await _dio.get(USER_CONNECTION_CONNECTED_TO_URL);
    if (response.statusCode == 200) {
      return _parseResponse(response.data);
    }
    throw Exception('Failed to load connected_to: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getConnectedFrom() async {
    final response = await _dio.get(USER_CONNECTION_CONNECTED_FROM_URL);
    if (response.statusCode == 200) {
      return _parseResponse(response.data);
    }
    throw Exception('Failed to load connected_from: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getSentRequests() async {
    final response = await _dio.get(USER_CONNECTION_SENT_REQUESTS_URL);
    if (response.statusCode == 200) {
      return _parseResponse(response.data);
    }
    throw Exception('Failed to load sent requests: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getReceivedRequests() async {
    final response = await _dio.get(USER_CONNECTION_RECEIVED_REQUESTS_URL);
    if (response.statusCode == 200) {
      return _parseResponse(response.data);
    }
    throw Exception('Failed to load received requests: ${response.statusCode}');
  }

  Future<void> acceptConnection(String toEmail) async {
    final response = await _dio.post(
      USER_CONNECTION_ACCEPT_URL,
      data: {'to_email': toEmail},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to accept connection: ${response.statusCode}');
    }
  }

  Future<void> sendRequest(String toEmail) async {
    final response = await _dio.post(
      USER_CONNECTION_SEND_REQUEST_URL,
      data: {'to_email': toEmail},
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send request: ${response.statusCode}');
    }
  }
}

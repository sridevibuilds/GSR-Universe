// Core API Network Client Manager
import 'package:dio/dio.dart';
import '../security/secure_storage.dart';
import '../errors/exceptions.dart';

class ApiClient {
  final Dio dio;
  final SecureStorage secureStorage;

  static const String defaultBaseUrl = 'http://10.243.137.70:5000';
  static final String _baseUrl = defaultBaseUrl;
  static void Function()? onSessionExpired;

  String get baseUrl => dio.options.baseUrl.isNotEmpty ? dio.options.baseUrl : _baseUrl;

  ApiClient(this.dio, this.secureStorage) {
    dio.options.baseUrl = _baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // Token expired or invalid
          if (e.response?.statusCode == 401) {
            if (onSessionExpired != null) {
              onSessionExpired!();
            }
          }

          // Connection timeouts mapping
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError) {
            return handler.reject(
              DioException(
                requestOptions: e.requestOptions,
                error: NetworkException("Connection timed out. Please check if the server is running."),
              ),
            );
          }

          // Standardize error mapping
          final dynamic responseData = e.response?.data;
          String errMsg = "An unexpected error occurred.";
          if (responseData is Map && responseData.containsKey('message')) {
            errMsg = responseData['message'];
          } else if (e.message != null) {
            errMsg = e.message!;
          }

          return handler.reject(
            DioException(
              requestOptions: e.requestOptions,
              error: ServerException(errMsg, statusCode: e.response?.statusCode),
            ),
          );
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is ServerException) throw e.error as ServerException;
      if (e.error is NetworkException) throw e.error as NetworkException;
      throw ServerException(e.message ?? "API fetch request failed.");
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is ServerException) throw e.error as ServerException;
      if (e.error is NetworkException) throw e.error as NetworkException;
      throw ServerException(e.message ?? "API post request failed.");
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.put(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is ServerException) throw e.error as ServerException;
      if (e.error is NetworkException) throw e.error as NetworkException;
      throw ServerException(e.message ?? "API update request failed.");
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.delete(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.error is ServerException) throw e.error as ServerException;
      if (e.error is NetworkException) throw e.error as NetworkException;
      throw ServerException(e.message ?? "API delete request failed.");
    }
  }
}

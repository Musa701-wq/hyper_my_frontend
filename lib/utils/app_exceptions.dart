import 'dart:io';
import 'package:http/http.dart' as http;

class AppException implements Exception {
  final String message;
  final String? technicalDetails;

  AppException(this.message, [this.technicalDetails]);

  @override
  String toString() => message;

  static AppException fromError(dynamic error) {
    if (error is SocketException) {
      return AppException(
        'Unable to connect. Please check your internet connection and try again.',
        error.toString(),
      );
    } else if (error is http.ClientException) {
      if (error.message.contains('Connection refused')) {
        return AppException(
          'Service temporarily unavailable. Please try again in a few moments.',
          error.toString(),
        );
      }
      return AppException(
        'Connection issue detected. Please check your network and retry.',
        error.toString(),
      );
    } else if (error is FormatException) {
      return AppException(
        'We encountered a problem while loading data. Please try again.',
        error.toString(),
      );
    } else {
      return AppException(
        'Oops! Something went wrong. Please try again later.',
        error.toString(),
      );
    }
  }
}

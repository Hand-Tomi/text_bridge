abstract class ApiException implements Exception {
  const ApiException({this.error, this.message});

  final Object? error;
  final String? message;
}

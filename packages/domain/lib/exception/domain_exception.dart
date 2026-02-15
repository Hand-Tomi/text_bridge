abstract class DomainException implements Exception {
  const DomainException({this.error, this.message});

  final Object? error;
  final String? message;
}

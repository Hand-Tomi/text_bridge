import 'domain_exception.dart';

class UnexpectedStatusCodeException extends DomainException {
  const UnexpectedStatusCodeException({
    super.error,
    super.message,
    required this.statusCode,
  });

  final int statusCode;
}

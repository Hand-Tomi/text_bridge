import 'api_exception.dart';

class BadResponseApiException extends ApiException {
  const BadResponseApiException({
    super.error,
    super.message,
    required this.statusCode,
  });

  final int statusCode;
}

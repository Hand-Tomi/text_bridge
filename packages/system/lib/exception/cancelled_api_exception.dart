import 'api_exception.dart';

class CancelledApiException extends ApiException {
  const CancelledApiException({super.error, super.message});
}

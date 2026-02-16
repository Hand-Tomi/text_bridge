import 'api_exception.dart';

class UnknownErrorApiException extends ApiException {
  const UnknownErrorApiException({super.error, super.message});
}

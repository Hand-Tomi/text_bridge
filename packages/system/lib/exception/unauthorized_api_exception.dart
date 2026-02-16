import 'api_exception.dart';

class UnauthorizedApiException extends ApiException {
  const UnauthorizedApiException({super.error, super.message});
}

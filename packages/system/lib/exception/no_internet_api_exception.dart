import 'api_exception.dart';

class NoInternetApiException extends ApiException {
  const NoInternetApiException({super.error, super.message});
}

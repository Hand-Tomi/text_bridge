import 'api_exception.dart';

class TimeoutApiException extends ApiException {
  const TimeoutApiException({super.error, super.message});
}

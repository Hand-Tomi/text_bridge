import 'domain_exception.dart';

class TimeoutException extends DomainException {
  const TimeoutException({super.error, super.message});
}

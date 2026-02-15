import 'domain_exception.dart';

class NetworkException extends DomainException {
  const NetworkException({super.error, super.message});
}

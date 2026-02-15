import 'domain_exception.dart';

class UnknownException extends DomainException {
  const UnknownException({super.error, super.message});
}

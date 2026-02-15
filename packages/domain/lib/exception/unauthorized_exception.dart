import 'domain_exception.dart';

class UnauthorizedException extends DomainException {
  const UnauthorizedException({super.error, super.message});
}

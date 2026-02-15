import 'package:freezed_annotation/freezed_annotation.dart';

import '../exception/domain_exception.dart';

part 'result.freezed.dart';

@freezed
sealed class Result<T extends Object?> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(DomainException exception) = Failure<T>;
  const factory Result.successVoid() = SuccessVoid<T>;
}

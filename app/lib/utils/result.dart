// Copyright 2026 Christian Delicaat. All rights reserved.

/// Utility class to wrap result data
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok._;
  const factory Result.error(Exception error) = Error._;
}

final class Ok<T> extends Result<T> {
  final T value;

  const Ok._(this.value);

  @override
  String toString() => 'Result<$T>.ok($value)';
}

final class Error<T> extends Result<T> {
  final Exception error;

  const Error._(this.error);

  @override
  String toString() => 'Result<$T>.error($error)';
}
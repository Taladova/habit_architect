/// Result type simple (style Either) sans dépendance externe.
///
/// - Ok(value)  => succès
/// - Err(failure) => échec
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final Object failure; // Failure recommandé, mais reste flexible
  const Err(this.failure);
}

/// Everything that can go wrong while loading trip data, in a form the
/// presentation layer can switch over exhaustively.
sealed class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The API could not be reached, or did not answer in time.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Could not reach the server.']);
}

/// The API answered with a non-2xx status code.
final class ServerFailure extends Failure {
  const ServerFailure(this.statusCode)
    : super('The server responded with an error ($statusCode).');

  final int statusCode;
}

/// The API answered, but the data is malformed or unusable.
final class DataFailure extends Failure {
  const DataFailure([super.message = 'The server returned invalid data.']);
}

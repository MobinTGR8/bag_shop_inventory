class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() {
    return code == null
        ? 'AppException: $message'
        : 'AppException[$code]: $message';
  }
}

class ConfigurationException extends AppException {
  const ConfigurationException(super.message, {super.code = 'configuration'});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code = 'network'});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code = 'permission'});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code = 'validation'});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code = 'not_found'});
}

class SyncException extends AppException {
  const SyncException(super.message, {super.code = 'sync'});
}

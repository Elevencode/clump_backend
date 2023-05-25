class AppResponseModel {
  final dynamic data;
  final dynamic error;
  final dynamic message;

  const AppResponseModel({
    this.data,
    this.error,
    this.message,
  });

  Map<String, dynamic> toJson() => {
        'data': data ?? '',
        'error': error ?? '',
        'message': message ?? '',
      };
}

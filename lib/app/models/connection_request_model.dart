class ConnectionRequestModel {
  final String fromEmail;
  final String toEmail;
  final bool isAccepted;

  ConnectionRequestModel({
    required this.fromEmail,
    required this.toEmail,
    required this.isAccepted,
  });

  factory ConnectionRequestModel.fromJson(Map<String, dynamic> json) {
    return ConnectionRequestModel(
      fromEmail: json['from_email']?.toString() ?? '',
      toEmail: json['to_email']?.toString() ?? '',
      isAccepted: json['is_accepted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from_email': fromEmail,
      'to_email': toEmail,
      'is_accepted': isAccepted,
    };
  }

  bool get isValid => fromEmail.isNotEmpty && toEmail.isNotEmpty;
}

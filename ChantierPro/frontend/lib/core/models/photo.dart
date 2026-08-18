import '../api/api_config.dart';

/// Miroir du DTO backend `PhotoResponse`.
class Photo {
  final int id;
  final String urlPhoto;
  final DateTime? dateUpload;
  final int? rapportId;

  const Photo({
    required this.id,
    required this.urlPhoto,
    this.dateUpload,
    this.rapportId,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => Photo(
        id: (json['id'] as num).toInt(),
        urlPhoto: json['urlPhoto'] ?? '',
        dateUpload: json['dateUpload'] != null
            ? DateTime.tryParse(json['dateUpload'])
            : null,
        rapportId:
            json['rapportId'] != null ? (json['rapportId'] as num).toInt() : null,
      );

  /// URL absolue affichable dans un Image.network.
  String get fullUrl => ApiConfig.resolveUrl(urlPhoto);
}

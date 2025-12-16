class AppSettingsModel {
  final String id;
  final String settingKey;
  final String? settingValue;
  final String? description;
  final DateTime updatedAt;

  AppSettingsModel({
    required this.id,
    required this.settingKey,
    this.settingValue,
    this.description,
    required this.updatedAt,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      id: json['id'],
      settingKey: json['setting_key'],
      settingValue: json['setting_value'],
      description: json['description'],
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'setting_key': settingKey,
      'setting_value': settingValue,
      'description': description,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AppSettingsModel copyWith({
    String? id,
    String? settingKey,
    String? settingValue,
    String? description,
    DateTime? updatedAt,
  }) {
    return AppSettingsModel(
      id: id ?? this.id,
      settingKey: settingKey ?? this.settingKey,
      settingValue: settingValue ?? this.settingValue,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// نموذج مساعد لإدارة إعدادات التطبيق
class AppSettings {
  static const String whatsappNumber = 'whatsapp_number';
  static const String facebookUrl = 'facebook_url';
  static const String instagramUrl = 'instagram_url';
  static const String appLogoUrl = 'app_logo_url';
  static const String deliveryFee = 'delivery_fee';
  static const String promotionalOffer = 'promotional_offer';

  static String? _whatsappNumber;
  static String? _facebookUrl;
  static String? _instagramUrl;
  static String? _appLogoUrl;
  static double? _deliveryFee;
  static String? _promotionalOffer;

  // Getters
  static String? get whatsappNumberValue => _whatsappNumber;
  static String? get facebookUrlValue => _facebookUrl;
  static String? get instagramUrlValue => _instagramUrl;
  static String? get appLogoUrlValue => _appLogoUrl;
  static double? get deliveryFeeValue => _deliveryFee;
  static String? get promotionalOfferValue => _promotionalOffer;

  // Setters
  static void setWhatsappNumber(String? value) => _whatsappNumber = value;
  static void setFacebookUrl(String? value) => _facebookUrl = value;
  static void setInstagramUrl(String? value) => _instagramUrl = value;
  static void setAppLogoUrl(String? value) => _appLogoUrl = value;
  static void setDeliveryFee(double? value) => _deliveryFee = value;
  static void setPromotionalOffer(String? value) => _promotionalOffer = value;

  // تحديث الإعدادات من قائمة النماذج
  static void updateFromModels(List<AppSettingsModel> models) {
    for (final model in models) {
      switch (model.settingKey) {
        case whatsappNumber:
          _whatsappNumber = model.settingValue;
          break;
        case facebookUrl:
          _facebookUrl = model.settingValue;
          break;
        case instagramUrl:
          _instagramUrl = model.settingValue;
          break;
        case appLogoUrl:
          _appLogoUrl = model.settingValue;
          break;
        case deliveryFee:
          _deliveryFee = model.settingValue != null 
              ? double.tryParse(model.settingValue!) 
              : null;
          break;
        case promotionalOffer:
          _promotionalOffer = model.settingValue;
          break;
      }
    }
  }

  // مسح جميع الإعدادات
  static void clear() {
    _whatsappNumber = null;
    _facebookUrl = null;
    _instagramUrl = null;
    _appLogoUrl = null;
    _deliveryFee = null;
    _promotionalOffer = null;
  }
}






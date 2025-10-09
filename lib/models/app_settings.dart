class AppSettings {
  int numberOfRounds;
  int intervalInMinutes;

  AppSettings({
    this.numberOfRounds = 4,
    this.intervalInMinutes = 1, // Padrão de 1 min para testes
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      numberOfRounds: json['numberOfRounds'] as int? ?? 4,
      intervalInMinutes: json['intervalInMinutes'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numberOfRounds': numberOfRounds,
      'intervalInMinutes': intervalInMinutes,
    };
  }
}
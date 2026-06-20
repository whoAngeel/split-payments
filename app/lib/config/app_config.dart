class AppConfig {
  final String baseUrl;

  const AppConfig({required this.baseUrl});
}

const appConfig = AppConfig(baseUrl: 'http://192.168.1.13:4000');

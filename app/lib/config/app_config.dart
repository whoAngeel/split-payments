class AppConfig {
  final String baseUrl;

  const AppConfig({required this.baseUrl});
}

const appConfig = AppConfig(baseUrl: 'http://localhost:4000');

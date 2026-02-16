enum EnvironmentType { dev, prod }

class FlavorConfig {
  const FlavorConfig({required this.flavor, required this.isDebugMode});

  final EnvironmentType flavor;
  final bool isDebugMode;

  String get baseUrl => switch (flavor) {
        EnvironmentType.dev => 'https://dev-api.example.com',
        EnvironmentType.prod => 'https://api.example.com',
      };
}

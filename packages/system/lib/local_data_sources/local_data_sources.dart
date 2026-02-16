abstract interface class LocalDataSources {
  Future<void> saveAccessToken(String value);
  Future<String?> getAccessToken();
  Future<void> clearSessionData();
  Future<void> clearAllData();
}

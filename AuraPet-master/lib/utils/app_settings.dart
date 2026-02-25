class AppSettings {
  static String _background = 'assets/companion-bg.png';
  static String _pet = 'assets/penguin.png';

  static void saveBackground(String path) {
    _background = path;
  }

  static void savePet(String path) {
    _pet = path;
  }

  static String getBackground() {
    return _background;
  }

  static String getPet() {
    return _pet;
  }
}

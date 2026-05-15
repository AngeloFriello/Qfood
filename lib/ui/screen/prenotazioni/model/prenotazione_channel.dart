enum PrenotazioneChannel {
  manuale,
  flood,
  google,
}

extension PrenotazioneChannelLabel on PrenotazioneChannel {
  String get label {
    switch (this) {
      case PrenotazioneChannel.manuale:
        return 'Manuale';
      case PrenotazioneChannel.flood:
        return 'Flood';
      case PrenotazioneChannel.google:
        return 'Google';
    }
  }
}

import 'dart:typed_data';

/// Utility to generate WAV headers for PCM16 audio.
class WavHeader {
  /// Creates a WAV header for PCM16 audio.
  ///
  /// [dataLength] is the total size of audio data in bytes.
  /// [sampleRate] defaults to 16000 Hz.
  /// [channels] defaults to 1 (mono).
  static Uint8List createHeader({
    required int dataLength,
    int sampleRate = 16000,
    int channels = 1,
  }) {
    final byteRate = sampleRate * channels * 2; // 16-bit = 2 bytes
    final totalDataLen = dataLength + 36;

    final header = ByteData(44);

    // RIFF chunk descriptor
    _writeString(header, 0, 'RIFF');
    header.setUint32(4, totalDataLen, Endian.little);
    _writeString(header, 8, 'WAVE');

    // fmt sub-chunk
    _writeString(header, 12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    header.setUint16(20, 1, Endian.little); // AudioFormat (1 for PCM)
    header.setUint16(22, channels, Endian.little); // NumChannels
    header.setUint32(24, sampleRate, Endian.little); // SampleRate
    header.setUint32(28, byteRate, Endian.little); // ByteRate
    header.setUint16(32, channels * 2, Endian.little); // BlockAlign
    header.setUint16(34, 16, Endian.little); // BitsPerSample

    // data sub-chunk
    _writeString(header, 36, 'data');
    header.setUint32(40, dataLength, Endian.little); // Subchunk2Size

    return header.buffer.asUint8List();
  }

  static void _writeString(ByteData data, int offset, String value) {
    for (int i = 0; i < value.length; i++) {
      data.setUint8(offset + i, value.codeUnitAt(i));
    }
  }
}

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'ai_service.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AIService _aiService = AIService();
  
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isListening = false;
  bool _isSpeaking = false;
  
  // Callbacks
  Function(String)? onTextChanged;
  Function(bool)? onListeningStateChanged;
  Function(bool)? onSpeakingStateChanged;
  
  VoiceService() {
    _initTts();
  }
  
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      onSpeakingStateChanged?.call(false);
      _isSpeaking = false;
    });
  }
  
  Future<void> initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          onListeningStateChanged?.call(false);
          _isListening = false;
        }
      },
      onError: (error) {
        onListeningStateChanged?.call(false);
        _isListening = false;
      },
    );
  }
  
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get speechEnabled => _speechEnabled;
  String get lastWords => _lastWords;
  
  void startListening() async {
    if (!_speechEnabled) {
      await initSpeech();
    }
    
    if (_speechEnabled) {
      _lastWords = '';
      _isListening = true;
      onListeningStateChanged?.call(true);
      
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _lastWords = result.recognizedWords;
          onTextChanged?.call(_lastWords);
          
          if (result.finalResult) {
            _processVoiceInput(_lastWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );
    }
  }
  
  void stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    onListeningStateChanged?.call(false);
    
    if (_lastWords.isNotEmpty) {
      await _processVoiceInput(_lastWords);
    }
  }
  
  Future<void> _processVoiceInput(String text) async {
    // Send to AI and get response
    final response = await _aiService.sendMessage(text);
    
    // Speak the response
    await speak(response);
  }
  
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    
    _isSpeaking = true;
    onSpeakingStateChanged?.call(true);
    
    await _flutterTts.speak(text);
  }
  
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    onSpeakingStateChanged?.call(false);
  }
  
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
  }
}

import 'dart:async';
import 'package:record/record.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'microphone_source.dart';

/// A MobileMicrophoneSource utilizes the phone's mic.
class MobileMicrophoneSource extends MicrophoneSource {

  late final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  final List<Uint8List> _buffer = [];
  Stream<Uint8List>? _stream;

  MobileMicrophoneSource();

  @override MicrophoneSourceType get type => MicrophoneSourceType.mobile;

  @override
  Future<void> initialize() async {
    debugPrint("Microphone: Requesting permission...");
    final permissionStatus = await Permission.microphone.request();
    debugPrint("Microphone: Permission status is $permissionStatus");

    if (!permissionStatus.isGranted) {
      debugPrint("Microphone: Permission denied, skipping model load.");
      return;
    }

    debugPrint("Microphone: Loading speech-to-text models...");
    await super.initialize(); // AI-generated mic fix: ensure base class initialize is called
    debugPrint("Microphone: Initialization complete.");

    state = MicrophoneState.ready;

  }

  @override
  Future<void> startListening() async {
    super.startListening();

    if (state == MicrophoneState.activeListening) {
      return;
    }

    await _cleanup();

    // clear buffer multiple times to ensure empty
    _buffer.clear();
    await Future.delayed(const Duration(milliseconds: 100));
    _buffer.clear();

    // reset stream to prevent issues with audio data carrying over
    await speechToText.resetStream();
    await Future.delayed(const Duration(milliseconds: 100));

    state = MicrophoneState.activeListening;

    // create audio recorder config
    const sampleRate = 16000;
    const encoder = AudioEncoder.pcm16bits;
    const config = RecordConfig(
      encoder: encoder,
      sampleRate: sampleRate,
      numChannels: 1,
    );

    try {
      // start stream
      _stream = await _audioRecorder.startStream(config);
      debugPrint("Mobile mic listening");

      // accumulate audio chunks until active listening stops
      _audioStreamSubscription = _stream!.listen(
            (chunk) {
          if (state == MicrophoneState.activeListening && _audioStreamSubscription != null) {
            _buffer.add(chunk);
            debugPrint("Adding audio chunk to buffer.");
          }
        },
        onError: (error) {
          debugPrint("Audio stream error: $error");
          state = MicrophoneState.ready;
          _cleanup();
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("Failed to start audio recording: $e");
      state = MicrophoneState.ready;
      rethrow;
    }
  }

  @override
  Future<void> stopListening(Future<void> Function(String result) onResult) async {
    if (state != MicrophoneState.activeListening) return;

    // AI-generated mic fix: reduce delay to improve responsiveness
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint("Stopping mobile microphone listening...");

    state = MicrophoneState.ready;
    await _cleanup();

    if (_buffer.isNotEmpty && state != MicrophoneState.disposed) {
      debugPrint("Processing buffer of size: ${_buffer.length} chunks");
      final bufferCopy = List<Uint8List>.from(_buffer);
      _buffer.clear();

      final totalBytes = bufferCopy.fold<int>(0, (sum, chunk) => sum + chunk.length);
      if (totalBytes > 0) {
        final combinedBuffer = Uint8List(totalBytes);
        var offset = 0;
        for (var chunk in bufferCopy) {
          combinedBuffer.setRange(offset, offset + chunk.length, chunk);
          offset += chunk.length;
        }

        // transcribe audio data
        String? result = await transcribe(combinedBuffer);
        debugPrint("Transcription result received: '$result'");

        // AI-generated mic fix: ALWAYS call onResult to provide feedback, even if empty
        await onResult(result ?? "");
      } else {
        debugPrint("Buffer total bytes was 0");
        await onResult("");
      }
    } else {
      debugPrint("Buffer was empty or source disposed.");
      await onResult("");
    }
    
    await speechToText.resetStream();
  }

  /// Helper function to clean up the audio recorder and stream subscription.
  Future<void> _cleanup() async {
    // stop audio recorder
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (e) {
      debugPrint("Error stopping mobile audio recorder: $e");
    }

    // cancel stream subscription
    if (_audioStreamSubscription != null) {
      await _audioStreamSubscription!.cancel();
      _audioStreamSubscription = null;
    }
  }

  @override
  Future<void> dispose() async {
    await _cleanup();
    _buffer.clear();
    await _audioRecorder.dispose();
    await super.dispose();
  }

}
import 'package:flutter/material.dart';
import '../../core/services/media_manager.dart';

/// A SpeakButton is always on-screen and is tapped/toggled to start and stop the microphone recording.
class SpeakButton extends StatefulWidget {

  final MediaManager mediaManager;

  const SpeakButton({super.key, required this.mediaManager});

  @override
  State<SpeakButton> createState() => _SpeakButtonState();
}

class _SpeakButtonState extends State<SpeakButton> {

  static const IconData voiceIconOutline = IconData(0xf147, fontFamily: 'MaterialIcons'); // when not recording
  static const IconData voiceIconFilled = IconData(0xe35c, fontFamily: 'MaterialIcons'); // when recording

  bool _speaking = false;
  bool _isProcessing = false; // AI-generated mic fix: prevent overlapping taps

  /// Callback function to handle the user pressing the speak button.
  Future<void> _onSpeakButtonPressed() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // start recording
      if (!_speaking) {
        setState(() {
          _speaking = true;
        });
        await widget.mediaManager.startMicrophone();
      }
      // stop recording
      else {
        setState(() {
          _speaking = false;
        });
        await widget.mediaManager.stopMicrophone();
      }
    } finally {
      // AI-generated mic fix: ensure processing flag is reset
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      label: "Microphone",
      button: true,
      hint: _speaking ? "Activate to stop recording" : "Activate to start recording",
      child: FloatingActionButton(
        // AI-generated mic fix: disable button while processing
        onPressed: _isProcessing ? null : _onSpeakButtonPressed,
        backgroundColor: _isProcessing 
            ? Colors.grey 
            : (_speaking ? Colors.deepPurple.shade200 : Colors.deepPurple.shade100),
        child: _speaking ? Icon(voiceIconFilled) : Icon(voiceIconOutline),
      ),
    );
  }
}

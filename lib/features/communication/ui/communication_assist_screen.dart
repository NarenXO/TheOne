import 'package:flutter/material.dart';
import 'package:theone/features/communication/communication_controller.dart';
import 'package:theone/features/communication/ui/widgets/emergency_phrase_bar.dart';
import 'package:theone/features/communication/ui/widgets/mock_banner.dart';
import 'package:theone/features/communication/ui/widgets/accessible_button.dart';
import 'screens/phrase_board_screen.dart';
import 'screens/intent_composer_screen.dart';
import 'screens/menu_ocr_assist_screen.dart';
import 'screens/spoken_reply_screen.dart';
import 'screens/sign_dictionary_screen.dart';
import 'screens/sign_camera_screen.dart';

class CommunicationAssistScreen extends StatefulWidget {
  const CommunicationAssistScreen({super.key});

  @override
  State<CommunicationAssistScreen> createState() => _CommunicationAssistScreenState();
}

class _CommunicationAssistScreenState extends State<CommunicationAssistScreen> {
  final CommunicationController _controller = CommunicationController();
  int _currentIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _controller.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Assist'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings would go here
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          PhraseBoardScreen(),
          IntentComposerScreen(),
          MenuOcrAssistScreen(),
          SpokenReplyScreen(),
          SignDictionaryScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MockBanner(message: 'DEMO / MOCK MODE'),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue.shade700,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble),
                label: 'Phrases',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.edit),
                label: 'Compose',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.document_scanner),
                label: 'Menu OCR',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mic),
                label: 'Reply',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.sign_language),
                label: 'Signs',
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 4 // Signs tab
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignCameraScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
              backgroundColor: Colors.blue.shade700,
            )
          : null,
    );
  }
}

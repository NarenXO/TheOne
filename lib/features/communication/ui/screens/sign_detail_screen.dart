import 'practice_mode_screen.dart';
import 'package:flutter/material.dart';
import '../../models/sign_entry.dart';
import '../widgets/mock_banner.dart';

class SignDetailScreen extends StatefulWidget {
  final SignEntry sign;

  const SignDetailScreen({
    super.key,
    required this.sign,
  });

  @override
  State<SignDetailScreen> createState() => _SignDetailScreenState();
}

class _SignDetailScreenState extends State<SignDetailScreen> {
  double _playbackSpeed = 1.0;
  bool _isLooping = false;
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sign.nameEn),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Column(
        children: [
          const MockBanner(message: 'DEMO MODE - Mock Video Player'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video player placeholder
                  Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPlaying ? Icons.pause_circle : Icons.play_circle,
                            size: 80,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isPlaying ? 'Playing' : 'Tap to play',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.sign.nameEn,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.sign.nameTa,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(widget.sign.category),
                              backgroundColor: Colors.blue.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Description:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.sign.description,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Keywords:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.sign.keywords
                              .map((keyword) => Chip(
                                    label: Text(keyword),
                                    backgroundColor: Colors.grey.shade200,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        // Playback controls
                        const Text(
                          'Playback Controls:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isPlaying = !_isPlaying;
                                });
                              },
                              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                              label: Text(_isPlaying ? 'Pause' : 'Play'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isLooping = !_isLooping;
                                });
                              },
                              icon: Icon(_isLooping ? Icons.repeat : Icons.repeat_one),
                              label: Text(_isLooping ? 'Looping' : 'Loop'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isLooping ? Colors.green : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text('Speed: '),
                            const SizedBox(width: 8),
                            ...[0.5, 0.75, 1.0, 1.25, 1.5].map((speed) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text('${speed}x'),
                                  selected: _playbackSpeed == speed,
                                  onSelected: (selected) {
                                    setState(() {
                                      _playbackSpeed = speed;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PracticeModeScreen(sign: widget.sign),
                              ),
                            );
                          },
                          icon: const Icon(Icons.fitness_center),
                          label: const Text('Practice Mode'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

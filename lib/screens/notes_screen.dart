import 'package:flutter/material.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController _controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Optional: show dialog or help
            },
          ),
        ],
        backgroundColor: Colors.blue[700],
      ),
      backgroundColor: Colors.blue[600],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              'Want to add a note?',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            //const SizedBox(height: ),
            TextField(
              controller: _controller,
              maxLines: 6,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Type how you’re feeling...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[900],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      onPressed: () {
                        final note = _controller.text;
                        // Save note logic here
                        Navigator.pop(context);
                      },
                      child: const Text('Save Note',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Skip',
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                    )
                  ],
                )
            ),

            const Text(
              'Every emotion is valid.\nYou showed up today - and that matters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 25),
            ),
          ],
        ),
      ),
    );
  }
}

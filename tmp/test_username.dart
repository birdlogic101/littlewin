
import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final jsonFile = File('assets/data/username_components.json');
  if (!jsonFile.existsSync()) {
    print('Error: JSON file not found at assets/data/username_components.json');
    return;
  }

  final content = jsonFile.readAsStringSync();
  final data = json.decode(content);
  
  final adjectives = List<String>.from(data['adjectives']);
  final nouns = List<String>.from(data['nouns']);
  final random = Random();

  print('Testing Username Generation Format: adjective + noun + number');
  for (var i = 0; i < 5; i++) {
    final adj = adjectives[random.nextInt(adjectives.length)];
    final noun = nouns[random.nextInt(nouns.length)];
    final number = random.nextInt(1000).toString().padLeft(3, '0');
    final username = '$adj$noun$number';
    print('Generated: $username');
    
    // Check if format is right (no underscores, specific structure)
    if (username.contains('_')) {
       print('FAIL: Contains underscores');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  String _selectedColor = 'green';

  final Map<String, Color> _colorOptions = {
    'blue': Colors.blue,
    'green': Colors.green,
    'red': Colors.red,
    'purple': Colors.purple,
    'orange': Colors.orange,
    'pink': Colors.pink,
    'teal': Colors.teal,
    'indigo': Colors.indigo,
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _selectedColor = prefs.getString('primaryColor') ?? 'green';
    });
  }

  Future<void> _saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    setState(() {
      _isDarkMode = value;
    });
    _showRestartDialog();
  }

  Future<void> _savePrimaryColor(String colorKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('primaryColor', colorKey);
    setState(() {
      _selectedColor = colorKey;
    });
    _showRestartDialog();
  }

  Future<void> _resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isDarkMode');
    await prefs.remove('primaryColor');
    setState(() {
      _isDarkMode = false;
      _selectedColor = 'green';
    });
    _showRestartDialog();
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Theme Updated'),
          content: const Text(
            'Please restart the app to see the changes take effect.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.palette_outlined,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            const Text('Theme Customization'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Section
            Text(
              'Appearance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Dark Mode Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dark Mode',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch(
                    value: _isDarkMode,
                    onChanged: _saveDarkMode,
                    activeColor: _colorOptions[_selectedColor],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Primary Color Section
            Text(
              'Primary Color',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your preferred theme color',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),

            // Color Options
            ..._colorOptions.entries.map((entry) {
              final colorKey = entry.key;
              final color = entry.value;
              final isSelected = _selectedColor == colorKey;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? color.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surface,
                ),
                child: InkWell(
                  onTap: () => _savePrimaryColor(colorKey),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            colorKey[0].toUpperCase() + colorKey.substring(1),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? color
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        if (isSelected)
                          Row(
                            children: [
                              Icon(Icons.check, color: color, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Active',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 40),

            // Reset Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetToDefault,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _colorOptions[_selectedColor],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Reset to Default',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

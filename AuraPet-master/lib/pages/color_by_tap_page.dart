import 'dart:convert';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorByTapPage extends StatefulWidget {
  const ColorByTapPage({super.key});

  @override
  State<ColorByTapPage> createState() => _ColorByTapPageState();
}

class _ColorByTapPageState extends State<ColorByTapPage> {
  // --- Grid Settings ---
  final int gridWidth = 15;
  final int gridHeight = 22;
  final double cellSize = 20.0;
  bool _showingInstructions = false;

  // --- Guest ID for Firestore Testing/Guest Access ---
  static const String _guestUserId = 'GUEST_USER_TEST_ID';

  // --- Image Selection (Currently unused, using grid only) ---
  final List<String> _imageAssets = [];
  late String _selectedImage;
  late List<Color?> _gridColors;
  Color _selectedColor = Colors.red.shade200;

  // --- Saved Drawings State ---
  List<Map<String, dynamic>> _savedGrids = [];

  // --- TEMPLATE CONSTANTS ---
  static const Color _templateColor = Colors.blueGrey;

  // --- Paint Mode State ---
  bool _isFreePaintMode = false; // False = Template, True = Free Paint

  // --- 1. PREFILL MASTER MAP (House Shape) ---
  static final Map<int, Color> _initialGridMap = {};

  // Static method to calculate the house shape indices once (Implementation omitted for brevity)
  static Map<int, Color> _generateHouseMap(int width, int height, Color color) {
    final Map<int, Color> map = {};
    const int bodyStartRow = 10;
    const int bodyEndRow = 20;
    const int bodyStartCol = 4;
    const int bodyEndCol = 10;
    const int roofTopRow = 6;
    for (int r = bodyStartRow; r <= bodyEndRow; r++) {
      for (int c = bodyStartCol; c <= bodyEndCol; c++) {
        map[r * width + c] = color;
      }
    }
    int centerCol = width ~/ 2;
    for (int r = roofTopRow; r < bodyStartRow; r++) {
      int span = bodyStartRow - r;
      for (int c = centerCol - span; c <= centerCol + span; c++) {
        if (c >= bodyStartCol && c <= bodyEndCol) {
          map[r * width + c] = color;
        }
      }
    }
    return map;
  }
  // --- END OF _generateHouseMap ---

  @override
  void initState() {
    super.initState();
    if (_initialGridMap.isEmpty) {
      _initialGridMap
          .addAll(_generateHouseMap(gridWidth, gridHeight, _templateColor));
    }
    _selectedImage = _imageAssets.isNotEmpty ? _imageAssets[0] : '';
    _gridColors = List.generate(gridWidth * gridHeight, (index) {
      return _initialGridMap[index];
    });
    _loadSavedGrids();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowInstructions();
    });
  }

  // --- PERSISTENCE UTILITIES ---

  String _getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? _guestUserId;
  }

  List<int?> _serializeGridColors(List<Color?> colors) {
    return colors.map((color) => color?.value).toList();
  }

  List<Color?> _deserializeGridColors(List<dynamic> colorValues) {
    return colorValues.map((value) {
      if (value == null) return null;
      return Color(value as int);
    }).toList();
  }

  /// Load saved drawings from Firebase for the current user or guest ID
  Future<void> _loadSavedGrids() async {
    final userId = _getUserId();

    final snapshot = await FirebaseFirestore.instance
        .collection('drawings')
        .where('userId', isEqualTo: userId)
        .get();

    setState(() {
      _savedGrids =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      if (userId == _guestUserId) {
        debugPrint('Loaded drawings for GUEST/TEST user ID: $userId');
      }
    });
  }

  /// Save the current grid to the list of saved drawings in Firebase
  Future<void> _saveCurrentGrid() async {
    final userId = _getUserId();
    final isGuest = userId == _guestUserId;

    if (isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Saving as GUEST/TEST user. Log in to save permanently!')));
    }

    final serializedColors = _serializeGridColors(_gridColors);

    try {
      final docRef = await FirebaseFirestore.instance.collection('drawings').add({
        'userId': userId,
        'grid': serializedColors,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _savedGrids.add({
          'id': docRef.id,
          'userId': userId,
          'grid': serializedColors,
          'createdAt': Timestamp.now(), // Use local timestamp for immediate display
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drawing Saved!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save drawing: $e')),
      );
    }
  }

  // --- NEW DELETE FUNCTION ---
  /// Delete a saved drawing from Firebase and the local list
  Future<void> _deleteGrid(String documentId, int index) async {
    try {
      // 1. Delete from Firestore
      await FirebaseFirestore.instance
          .collection('drawings')
          .doc(documentId)
          .delete();

      // 2. Delete from local state list
      setState(() {
        _savedGrids.removeAt(index);
      });

      if (mounted) {
        // We do not close the dialog yet, just show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drawing Deleted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete drawing: $e')),
        );
      }
    }
  }

  /// Load a saved grid state onto the canvas
  void _loadGrid(Map<String, dynamic> gridData) {
    final List<dynamic> serializedColors = gridData['grid'];
    final List<Color?> loadedColors = _deserializeGridColors(serializedColors);

    setState(() {
      _gridColors = loadedColors;
    });

    if (mounted) {
      Navigator.of(context).pop(); // Close the dialog after loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Drawing Loaded!')),
      );
    }
  }

  // --- UI and interaction methods (Unchanged) ---

  void _selectColor(Color color) {
    setState(() {
      _selectedColor = color;
    });
  }

  void _colorCell(int index) {
    setState(() {
      if (_isFreePaintMode) {
        // Free Paint Mode: color any cell
        if (_gridColors[index] == _selectedColor) {
          _gridColors[index] = null; // Erase to transparent
        } else {
          _gridColors[index] = _selectedColor;
        }
      } else {
        // Template Mode: only color inside the house shape
        if (_initialGridMap.containsKey(index)) {
          if (_gridColors[index] == _selectedColor) {
            _gridColors[index] = _templateColor; // Reset to template color
          } else {
            _gridColors[index] = _selectedColor;
          }
        }
      }
    });
  }

  void _clearGrid() {
    setState(() {
      if (_isFreePaintMode) {
        // Free Paint Mode: Clear the entire canvas
        _gridColors = List.generate(gridWidth * gridHeight, (index) => null);
      } else {
        // Template Mode: Reset to the initial house shape
        _gridColors = List.generate(gridWidth * gridHeight, (index) {
          return _initialGridMap[index];
        });
      }
    });
  }

  void _changeImage(String? newImage) {
    if (newImage != null && newImage != _selectedImage) {
      setState(() {
        _selectedImage = newImage;
        _clearGrid();
      });
    }
  }

  Future<void> _checkAndShowInstructions() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final bool hasSeen = prefs.getBool('hasSeenColorByTapInstructions') ?? false;
    if (!hasSeen || hasSeen) {
      _showInstructions();
    }
  }

  // --- UI Widget Builders ---

  void _showInstructions() {
    setState(() => _showingInstructions = true);
    showDialog(
      context: context,
      barrierDismissible: false, // User must press the button to close
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("How to draw 🎨"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a color and tap the grid to color.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            Text("1. Click Pencil icon to toggle modes:"),
            Text("   • Bottle: Restricted to color inside the bottle."),
            Text("   • Free Paint: Unrestricted coloring anywhere on the grid."),
            SizedBox(height: 10),

            Text("2. Click Save icon to save your drawing."),
            SizedBox(height: 10),

            Text("3. Click Folder icon to load/delete your drawings."),
            SizedBox(height: 10),

            Text("4. Click Refresh icon to reset the current canvas."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _showingInstructions = false);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasSeenColorByTapInstructions', true);
            },
            child: const Text("Let's Start!",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLoadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Load/Delete Drawings'),
          content: SizedBox(
            width: double.maxFinite,
            child: _savedGrids.isEmpty
                ? const Text('No saved drawings found for this user/guest ID.')
                : ListView.builder(
              itemCount: _savedGrids.length,
              itemBuilder: (context, index) {
                final gridData = _savedGrids[index];
                // Ensure 'id' exists before trying to delete
                final documentId = gridData['id'] as String?;

                final timestamp = gridData['createdAt'] is Timestamp
                    ? (gridData['createdAt'] as Timestamp)
                    .toDate()
                    .toString()
                    .substring(0, 16)
                    : 'No Timestamp';

                return ListTile(
                  title: Text('Drawing ${index + 1}'),
                  subtitle: Text('Saved: $timestamp'),
                  leading: IconButton(
                    // New Delete Icon
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.red),
                    onPressed: documentId != null
                        ? () => _deleteGrid(documentId, index)
                        : null, // Disable if ID is missing
                    tooltip: 'Delete Drawing',
                  ),
                  trailing: const Icon(Icons.download),
                  onTap: () => _loadGrid(gridData),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safety check for empty assets list in the dropdown
    final List<DropdownMenuItem<String>> imageItems =
    _imageAssets.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value.split('/').last.split('.').first),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Color by Tap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRect(
          child: SizedBox(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: Colors.deepPurple.shade900.withOpacity(0.5),
              ),
            ),
          ),
        ),
        actions: [
          if (_imageAssets.isNotEmpty) // Only show dropdown if images are available
            DropdownButton<String>(
              value: _selectedImage,
              icon: const Icon(Icons.image, color: Colors.white),
              dropdownColor: Colors.deepPurple.shade300,
              style: const TextStyle(color: Colors.white),
              onChanged: _changeImage,
              items: imageItems,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearGrid,
            tooltip: _isFreePaintMode ? 'Clear Canvas' : 'Reset Template',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showInstructions,
            tooltip: 'How to use',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    // Constrain the size of the coloring canvas
                    child: SizedBox(
                      width: cellSize * gridWidth,
                      height: cellSize * gridHeight,
                      child: Stack(
                        children: [
                          // Base Image (Only display if an asset path is set)
                          if (_selectedImage.isNotEmpty)
                            Positioned.fill(
                              child: Image.asset(
                                _selectedImage,
                                fit: BoxFit.cover,
                              ),
                            ),

                          // The Interactive Grid
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridWidth,
                            ),
                            itemCount: gridWidth * gridHeight,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _colorCell(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    // Only draw color if it's not the initial transparent state
                                    color: _gridColors[index] ??
                                        Colors.transparent,
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.1),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Vertical Toolbar
                Container(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: _saveCurrentGrid,
                        tooltip: 'Save Current Drawing',
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: _showLoadDialog,
                        tooltip: 'Load Saved Drawing',
                      ),
                      IconButton(
                        icon: Icon(
                          _isFreePaintMode
                              ? Icons.brush
                              : Icons.architecture,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFreePaintMode = !_isFreePaintMode;
                            _clearGrid(); // Clear the grid when switching modes
                          });
                        },
                        tooltip: _isFreePaintMode
                            ? 'Switch to Template Mode'
                            : 'Switch to Free Paint Mode',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildColorPalette(),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    final List<Color> colors = [
      // --- 1. THE BRIGHTEST (Pure Light) ---
      Colors.white,

      // --- 2. THE TINTS (Soft Pastels/Shadow Colors) ---
      Colors.lightBlue.shade100,
      Colors.pink.shade100,
      Colors.yellow.shade200,
      Colors.cyan.shade200, // New color
      Colors.teal.shade200,
      Colors.green.shade200,
      Colors.indigo.shade200,
      Colors.purple.shade200,
      Colors.red.shade200,
      Colors.orange.shade200,
      Colors.brown.shade200,

      // --- 3. THE MID-TONES (Vibrant & Saturated) ---
      Colors.lightBlue.shade300,
      Colors.pink.shade300,
      Colors.deepOrange.shade300, // New color
      Colors.blueGrey.shade400, // New color
      Colors.grey.shade400,
      Colors.green.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
      Colors.red.shade400,
      Colors.brown.shade400,

      // --- 4. THE DEEP (Darkest/Foundational) ---
      const Color(0xFF212121), // Charcoal
      Colors.black, // Absolute Deep
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      color: Colors.grey.shade100,
      child: Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        alignment: WrapAlignment.center,
        children: colors.map((color) {
          final isSelected = _selectedColor == color;
          return GestureDetector(
            onTap: () => _selectColor(color),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: Colors.deepPurple.shade200, width: 3)
                    : null,
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: color,
                child: isSelected
                    ? Icon(Icons.check,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white)
                    : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/sleep_story.dart';
import '../../models/meditation.dart';

class ContentManagementPage extends StatefulWidget {
  const ContentManagementPage({super.key});

  @override
  _ContentManagementPageState createState() => _ContentManagementPageState();
}

class _ContentManagementPageState extends State<ContentManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Story Form State
  final _storyFormKey = GlobalKey<FormState>();
  final _storyTitleController = TextEditingController();
  final _storyAuthorController = TextEditingController();
  final _storyDescriptionController = TextEditingController();
  final _storyGenresController = TextEditingController();
  String _selectedCategory = 'Stories';
  double _selectedRating = 4.5;
  final _categories = ['Stories', 'Soundscapes', 'ASMR'];
  String? _editingStoryId;

  // Meditation Form State
  final _meditationFormKey = GlobalKey<FormState>();
  final _meditationTitleController = TextEditingController();
  final _meditationArtistController = TextEditingController();
  final _meditationDurationController = TextEditingController();

  // NEW: Meditation Category State
  String _selectedMeditationCategory = 'Meditation Tutorial';
  final List<String> _meditationCategories = ['Meditation Tutorial', 'Meditation Music'];
  String? _editingMeditationId;

  // Common File Handling
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _imageUrl;

  Uint8List? _audioBytes;
  String? _audioFileName;
  String? _audioUrl;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _storyTitleController.dispose();
    _storyAuthorController.dispose();
    _storyDescriptionController.dispose();
    _storyGenresController.dispose();
    _meditationTitleController.dispose();
    _meditationArtistController.dispose();
    _meditationDurationController.dispose();
    super.dispose();
  }

  // --- FILE PICKING & UPLOADING ---

  Future<void> _pickFile(bool isImage) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: isImage ? FileType.image : FileType.audio,
      withData: true,
    );

    if (result != null) {
      final file = result.files.single;
      setState(() {
        if (isImage) {
          _imageBytes = file.bytes;
          _imageFileName = file.name;
          _imageUrl = null;
        } else {
          _audioBytes = file.bytes;
          _audioFileName = file.name;
          _audioUrl = null;
        }
      });
    }
  }

  Future<String> _uploadFile(Uint8List bytes, String path) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putData(bytes);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // --- STORY ACTIONS ---

  void _createOrUpdateStory() async {
    if (!_storyFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final isUpdating = _editingStoryId != null;

    String? newImageUrl = _imageUrl;
    String? newAudioUrl = _audioUrl;

    try {
      if (_imageBytes != null) {
        final imagePath = 'stories/images/${DateTime.now().millisecondsSinceEpoch}-$_imageFileName';
        newImageUrl = await _uploadFile(_imageBytes!, imagePath);
      }
      if (_audioBytes != null) {
        final audioPath = 'stories/audio/${DateTime.now().millisecondsSinceEpoch}-$_audioFileName';
        newAudioUrl = await _uploadFile(_audioBytes!, audioPath);
      }

      if (newImageUrl == null || newAudioUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both image and audio files.')));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final storyData = {
        'title': _storyTitleController.text,
        'author': _storyAuthorController.text,
        'description': _storyDescriptionController.text,
        'category': _selectedCategory,
        'genre': _storyGenresController.text.split(',').map((e) => e.trim()).toList(),
        'rating': _selectedRating,
        'audioLink': newAudioUrl,
        'image': newImageUrl,
      };

      if (isUpdating) {
        await _firestore.collection('Sleep-Module').doc(_editingStoryId).update(storyData);
      } else {
        await _firestore.collection('Sleep-Module').add(storyData);
      }

      _clearForms();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Story ${isUpdating ? 'updated' : 'created'} successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- MEDITATION ACTIONS ---

  void _createOrUpdateMeditation() async {
    if (!_meditationFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final isUpdating = _editingMeditationId != null;

    String? newImageUrl = _imageUrl;
    String? newAudioUrl = _audioUrl;

    try {
      if (_imageBytes != null) {
        final imagePath = 'meditations/images/${DateTime.now().millisecondsSinceEpoch}-$_imageFileName';
        newImageUrl = await _uploadFile(_imageBytes!, imagePath);
      }
      if (_audioBytes != null) {
        final audioPath = 'meditations/audio/${DateTime.now().millisecondsSinceEpoch}-$_audioFileName';
        newAudioUrl = await _uploadFile(_audioBytes!, audioPath);
      }

      if (newImageUrl == null || newAudioUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both image and audio files.')));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final meditationData = {
        'title': _meditationTitleController.text,
        'artist': _meditationArtistController.text,
        'category': _selectedMeditationCategory, // Added Category to Firestore Data
        'duration': int.parse(_meditationDurationController.text),
        'imageUrl': newImageUrl,
        'audioUrl': newAudioUrl,
      };

      if (isUpdating) {
        await _firestore.collection('meditations').doc(_editingMeditationId).update(meditationData);
      } else {
        await _firestore.collection('meditations').add(meditationData);
      }

      _clearForms();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Meditation ${isUpdating ? 'updated' : 'created'} successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          tabs: const [
            Tab(text: 'Stories'),
            Tab(text: 'Meditations'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildStorySection(),
              _buildMeditationSection(),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStorySection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStoryForm(),
          const SizedBox(height: 32),
          _buildStoryListView(),
        ],
      ),
    );
  }

  Widget _buildMeditationSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMeditationForm(),
          const SizedBox(height: 32),
          _buildMeditationListView(),
        ],
      ),
    );
  }

  Widget _buildStoryForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _storyFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_editingStoryId == null ? 'Add' : 'Edit'} Story', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildTextField(_storyTitleController, 'Title'),
              const SizedBox(height: 16),
              _buildTextField(_storyAuthorController, 'Author'),
              const SizedBox(height: 16),
              _buildTextField(_storyDescriptionController, 'Description', maxLines: 3),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(_storyGenresController, 'Genres (comma-separated)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text('Rating: ${_selectedRating.toStringAsFixed(1)}'),
                  ),
                  Expanded(
                    flex: 2,
                    child: Slider(
                      value: _selectedRating,
                      min: 0,
                      max: 5,
                      divisions: 10,
                      label: _selectedRating.toStringAsFixed(1),
                      onChanged: (double value) {
                        setState(() {
                          _selectedRating = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFileUploadField('Thumbnail Image', () => _pickFile(true), _imageFileName, _imageUrl),
              const SizedBox(height: 16),
              _buildFileUploadField('Audio File', () => _pickFile(false), _audioFileName, _audioUrl),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _clearForms, child: const Text('Clear')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _createOrUpdateStory, child: Text(_editingStoryId == null ? 'Create' : 'Update')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeditationForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _meditationFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_editingMeditationId == null ? 'Add' : 'Edit'} Meditation', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildTextField(_meditationTitleController, 'Title'),
              const SizedBox(height: 16),
              _buildTextField(_meditationArtistController, 'Artist'),
              const SizedBox(height: 16),

              // NEW: Meditation Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedMeditationCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _meditationCategories.map((String category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedMeditationCategory = newValue!;
                  });
                },
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _meditationDurationController,
                decoration: const InputDecoration(labelText: 'Duration (minutes)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Duration (minutes)';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (int.parse(value) > 60) {
                    return 'Duration cannot be more than 60 minutes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildFileUploadField('Thumbnail Image', () => _pickFile(true), _imageFileName, _imageUrl),
              const SizedBox(height: 16),
              _buildFileUploadField('Audio File', () => _pickFile(false), _audioFileName, _audioUrl),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _clearForms, child: const Text('Clear')),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _createOrUpdateMeditation, child: Text(_editingMeditationId == null ? 'Create' : 'Update')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) => (value == null || value.isEmpty) ? 'Please enter $label' : null,
    );
  }

  Widget _buildFileUploadField(String label, VoidCallback onTap, String? fileName, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: fileName == null && url == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, color: Colors.grey.shade700, size: 40),
                  const SizedBox(height: 8),
                  Text('Tap to select a file', style: TextStyle(color: Colors.grey.shade700)),
                ],
              )
                  : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(fileName ?? 'Existing file: ${url!.split('/').last.split('?').first}', textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoryListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Sleep-Module').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Something went wrong');
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final stories = snapshot.data!.docs.map((doc) => SleepStory.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: Image.network(story.image, width: 50, height: 50, fit: BoxFit.cover),
                title: Text(story.title),
                subtitle: Text('${story.author} • ${story.category}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editStory(story)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteStory(story.id, story.image, story.audioLink)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMeditationListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('meditations').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Something went wrong');
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

        final meditations = snapshot.data!.docs.map((doc) => Meditation.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: meditations.length,
          itemBuilder: (context, index) {
            final meditation = meditations[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: Image.network(meditation.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                title: Text(meditation.title),
                // Display category in subtitle if your model supports it
                subtitle: Text('${meditation.artist}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _editMeditation(meditation)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteMeditation(meditation.id, meditation.imageUrl, meditation.audioUrl)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- FORM HELPERS ---

  void _clearForms() {
    _storyFormKey.currentState?.reset();
    _storyTitleController.clear();
    _storyAuthorController.clear();
    _storyDescriptionController.clear();
    _storyGenresController.clear();

    _meditationFormKey.currentState?.reset();
    _meditationTitleController.clear();
    _meditationArtistController.clear();
    _meditationDurationController.clear();

    setState(() {
      _editingStoryId = null;
      _editingMeditationId = null;
      _selectedCategory = 'Stories';
      _selectedMeditationCategory = 'Meditation Tutorial'; // Reset Category
      _selectedRating = 4.5;
      _imageBytes = null;
      _imageFileName = null;
      _imageUrl = null;
      _audioBytes = null;
      _audioFileName = null;
      _audioUrl = null;
    });
  }

  void _editStory(SleepStory story) {
    _storyTitleController.text = story.title;
    _storyAuthorController.text = story.author;
    _storyDescriptionController.text = story.description;
    _storyGenresController.text = story.genre.join(', ');
    setState(() {
      _selectedCategory = story.category;
      _selectedRating = story.rating;
      _editingStoryId = story.id;
      _imageUrl = story.image;
      _audioUrl = story.audioLink;
      _imageBytes = null;
      _audioBytes = null;
      _tabController.animateTo(0);
    });
  }

  void _editMeditation(Meditation meditation) {
    _meditationTitleController.text = meditation.title;
    _meditationArtistController.text = meditation.artist;
    _meditationDurationController.text = meditation.duration.toString();
    setState(() {
      _editingMeditationId = meditation.id;
      _imageUrl = meditation.imageUrl;
      _audioUrl = meditation.audioUrl;

      // Update Category from model if it exists
      try {
        // This requires your Meditation model to have a category field
        _selectedMeditationCategory = (meditation as dynamic).category ?? 'Meditation Tutorial';
      } catch (e) {
        _selectedMeditationCategory = 'Meditation Tutorial';
      }

      _imageBytes = null;
      _audioBytes = null;
      _tabController.animateTo(1);
    });
  }

  void _deleteStory(String id, String imageUrl, String audioUrl) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _firestore.collection('Sleep-Module').doc(id).delete();
      await _storage.refFromURL(imageUrl).delete();
      await _storage.refFromURL(audioUrl).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story deleted successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting story: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteMeditation(String id, String imageUrl, String audioUrl) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _firestore.collection('meditations').doc(id).delete();
      await _storage.refFromURL(imageUrl).delete();
      await _storage.refFromURL(audioUrl).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Meditation deleted successfully!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting meditation: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

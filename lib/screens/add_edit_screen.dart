import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hobbz_place/providers/media_provider.dart';
import 'package:hobbz_place/models/models.dart';
import 'package:hobbz_place/enums/enums.dart';

class AddEditScreen extends StatefulWidget {
  final MediaItem? existingItem;

  const AddEditScreen({super.key, this.existingItem});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _altTitlesController;
  late TextEditingController _authorController;
  late TextEditingController _currentProgressController;
  late TextEditingController _totalProgressController;
  late TextEditingController _coverUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  late TextEditingController _favQuotesController;
  late MediaCategory _selectedCategory;
  late MediaStatus _selectedStatus;
  late List<Genre> _selectedGenres;
  late double _rating;
  List<MediaItem> _duplicates = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final item = widget.existingItem;

    _titleController = TextEditingController(text: item?.title ?? '');

    _altTitlesController = TextEditingController(
      text: item?.altTitles.join(', ') ?? '',
    );

    _authorController = TextEditingController(text: item?.author ?? '');
    _currentProgressController = TextEditingController(
      text: item?.currentProgress.toString() ?? '0',
    );
    _totalProgressController = TextEditingController(
      text: item?.totalProgress?.toString() ?? '',
    );
    _coverUrlController = TextEditingController(text: item?.coverImageUrl ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _notesController = TextEditingController(text: item?.notes ?? '');
    _favQuotesController = TextEditingController(
      text: item?.favQuotes.join('\n') ?? '',
    );

    // Initialize dropdown/chip selections.
    _selectedCategory = item?.category ?? MediaCategory.manhwa;
    _selectedStatus = item?.status ?? MediaStatus.planning;
    _selectedGenres = List<Genre>.from(item?.genres ?? []);
    _rating = item?.rating ?? 0.0;
  }

  // DISPOSE - clean up controllers
  @override
  void dispose() {
    _titleController.dispose();
    _altTitlesController.dispose();
    _authorController.dispose();
    _currentProgressController.dispose();
    _totalProgressController.dispose();
    _coverUrlController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _favQuotesController.dispose();
    super.dispose();
  }

  // BUILD — the form UI
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingItem != null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TITLE FIELD
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g., Solo Leveling',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (!isEditing && value.trim().length >= 3) {
                    _checkForDuplicates();
                  } else {
                    setState(() {
                      _duplicates = [];
                    });
                  }
                },
              ),

              // Duplicate warning (if any found)
              if (_duplicates.isNotEmpty)
                _buildDuplicateWarning(theme),

              const SizedBox(height: 16),

              //Alternative titles found
              TextFormField(
                controller: _altTitlesController,
                decoration: const InputDecoration(
                  labelText: 'Alternative Titles',
                  hintText: 'Separate with commas: Title A, Title B',
                  prefixIcon: Icon(Icons.subtitles),
                ),
                maxLines: 2,
                onChanged: (value) {
                  if (!isEditing && _titleController.text.trim().length >= 3) {
                    _checkForDuplicates();
                  }
                },
              ),

              const SizedBox(height: 16),

              // CATEGORY DROPDOWN
              DropdownButtonFormField<MediaCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category),
                ),

                items: MediaCategory.values.map((cat) {
                  return DropdownMenuItem<MediaCategory>(
                    value: cat,
                    child: Text(cat.displayName),
                  );
                }).toList(),

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              //Status dropdown
              DropdownButtonFormField<MediaStatus>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: MediaStatus.values.map((status) {
                  return DropdownMenuItem<MediaStatus>(
                    value: status,
                    child: Text(status.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              //Author field
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author / Creator',
                  hintText: 'e.g., Chugong',
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

              //Progress field (current / total) - side by side
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _currentProgressController,
                      decoration: InputDecoration(
                        labelText: _selectedCategory.group == 'Reading'
                            ? 'Current Chapter'
                            : 'Current Episode',
                        prefixIcon: const Icon(Icons.bookmark),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _totalProgressController,
                      decoration: InputDecoration(
                        labelText: _selectedCategory.group == 'Reading'
                            ? 'Total Chapters'
                            : 'Total Episodes',
                        hintText: 'Unknown? Leave empty',
                        prefixIcon: const Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              //Cover Image URL
              TextFormField(
                controller: _coverUrlController,
                decoration: const InputDecoration(
                  labelText: 'Cover Image URL',
                  hintText: 'https://example.com/cover.jpg',
                  prefixIcon: Icon(Icons.image),
                ),
              ),
              //Show a small preview if URL entered
              if (_coverUrlController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _coverUrlController.text,
                      height: 100,
                      width: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          width: 70,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 24),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Genre
              Text(
                'Genres',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: Genre.values.map((genre) {
                  final isSelected = _selectedGenres.contains(genre);
                  return FilterChip(
                    label: Text(
                      genre.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGenres.add(genre);
                        } else {
                          _selectedGenres.remove(genre);
                        }
                      });
                    },
                    selectedColor: theme.colorScheme.primary,
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Rating Slider
              Text(
                'Rating: ${_rating == 0 ? "Not rated" : _rating.toStringAsFixed(1)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star_border, size: 18),
                  Expanded(
                    child: Slider(
                      value: _rating,
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: _rating == 0 ? 'Not rated' : _rating.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _rating = value;
                        });
                      },
                    ),
                  ),
                  const Icon(Icons.star, size: 18),
                ],
              ),

              const SizedBox(height: 16),

              //Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description / Synopsis',
                  hintText: 'What\'s it about?',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Personal Notes',
                  hintText: 'Your thoughts, observations...',
                  prefixIcon: Icon(Icons.note),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              // Favourite Quotes
              TextFormField(
                controller: _favQuotesController,
                decoration: const InputDecoration(
                  labelText: 'Favorite Quotes',
                  hintText: 'One quote per line',
                  prefixIcon: Icon(Icons.format_quote),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveItem,
                  icon: Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(
                    isEditing ? 'Save Changes' : 'Add to Library',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // Duplicate Warning
  Widget _buildDuplicateWarning(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Possible duplicate${_duplicates.length > 1 ? "s" : ""} found!',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // List each duplicate.
          ..._duplicates.map((dup) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• ${dup.title} (${dup.category.displayName} — ${dup.status.displayName})',
              style: theme.textTheme.bodySmall,
            ),
          )),
          const SizedBox(height: 4),
          Text(
            'You can still save if this is a different item.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // Check for duplicates  - called when title or alt titles change
  void _checkForDuplicates() {
    final provider = context.read<MediaProvider>();
    final altTitles = _altTitlesController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final dupes = provider.findDuplicates(
      _titleController.text,
      altTitles,
      excludeId: widget.existingItem?.id,
    );

    setState(() {
      _duplicates = dupes;
    });
  }

  // Confirm and Duplicate 
  Future<bool> _confirmAddDuplicate(List<MediaItem> similar) async {
    final names = similar
        .take(3)
        .map((d) => '• ${d.title} (${d.category.displayName})')
        .join('\n');
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Already in your library?'),
        content: Text('You already have something very similar:\n\n$names\n\nAdd it anyway?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add anyway'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  // Save Item
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final altTitles = _altTitlesController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final favQuotes = _favQuotesController.text
        .split('\n')
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();

    final currentProgress = int.tryParse(_currentProgressController.text) ?? 0;

    final totalProgress = int.tryParse(_totalProgressController.text);

    final provider = context.read<MediaProvider>();

    if (_isSaving) return;
    _isSaving = true;

    if (widget.existingItem == null) {
      final similar = provider
          .findDuplicates(_titleController.text.trim(), altTitles)
          .where((d) =>
              d.category.collectionGroup == _selectedCategory.collectionGroup)
          .toList();

      if (similar.isNotEmpty) {
        final addAnyway = await _confirmAddDuplicate(similar);
        if (!addAnyway || !mounted) {
          _isSaving = false; // let the user try again
          return;
        }
      }
    }

    if (widget.existingItem != null) {
      // Update existing data
      final updated = widget.existingItem!.copyWith(
        title: _titleController.text.trim(),
        altTitles: altTitles,
        category: _selectedCategory,
        genres: _selectedGenres,
        author: _authorController.text.trim().isEmpty
            ? null
            : _authorController.text.trim(),
        status: _selectedStatus,
        currentProgress: currentProgress,
        totalProgress: totalProgress,
        rating: _rating == 0 ? null : _rating,
        coverImageUrl: _coverUrlController.text.trim().isEmpty
            ? null
            : _coverUrlController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        favQuotes: favQuotes,
        dateCompleted: _selectedStatus == MediaStatus.completed
            ? (widget.existingItem!.dateCompleted ?? DateTime.now())
            : null,
      );
      provider.updateItem(updated);
    } else {
      // Create new item
      final newItem = MediaItem(
        title: _titleController.text.trim(),
        altTitles: altTitles,
        category: _selectedCategory,
        genres: _selectedGenres,
        author: _authorController.text.trim().isEmpty
            ? null
            : _authorController.text.trim(),
        status: _selectedStatus,
        currentProgress: currentProgress,
        totalProgress: totalProgress,
        rating: _rating == 0 ? null : _rating,
        coverImageUrl: _coverUrlController.text.trim().isEmpty
            ? null
            : _coverUrlController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        favQuotes: favQuotes,
        dateCompleted: _selectedStatus == MediaStatus.completed
            ? DateTime.now()
            : null,
      );
      provider.addItem(newItem);
    }

    Navigator.pop(context);
    // ↑ Pops this screen off the navigation stack, returning to where
    //   the user came from.

    // Step 7: Show a confirmation snackbar.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existingItem != null
            ? '✓ Changes saved!'
            : '✓ Added to library!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
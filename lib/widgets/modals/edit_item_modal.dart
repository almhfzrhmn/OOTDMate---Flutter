import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/wardrobe_item_model.dart';
import 'package:ootdmate_frontend/services/api-services/wardrobe_item_service.dart';

class EditItemModal extends StatefulWidget {
  final WardrobeItemModel item;

  const EditItemModal({super.key, required this.item});

  @override
  State<EditItemModal> createState() => _EditItemModalState();
}

class _EditItemModalState extends State<EditItemModal> {
  final _formKey = GlobalKey<FormState>();
  final WardrobeItemService _wardrobeItemService = WardrobeItemService();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _colorController;
  late TextEditingController _notesController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name ?? '');
    _brandController = TextEditingController(text: widget.item.brand ?? '');
    _colorController = TextEditingController(text: widget.item.color ?? '');
    _notesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _wardrobeItemService.updateWardrobeItem(
        itemId: widget.item.id,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        color: _colorController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      // Close modal and return "saved" so previous screen knows to refresh
      Navigator.of(context).pop('saved');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text("Delete Item?"),
        content: const Text("Are you sure you want to delete this item? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _wardrobeItemService.deleteWardrobeItem(widget.item.id);
      if (!mounted) return;
      // Close modal and return "deleted"
      Navigator.of(context).pop('deleted');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adding padding for the keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset > 0 ? bottomInset + 16 : 32,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withAlpha(50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Edit Metadata",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                ],
              ),
              const SizedBox(height: 24),
              
              Text("Item Name", style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: "e.g. Vintage Leather Jacket"),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Color", style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _colorController,
                          decoration: const InputDecoration(hintText: "e.g. Black"),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Brand", style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _brandController,
                          decoration: const InputDecoration(hintText: "e.g. Zara"),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Text("Personal Notes", style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Add any styling notes, where you bought it, or condition...",
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),
              
              Row(
                children: [
                  // Delete Button
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error.withAlpha(50)),
                      ),
                      onPressed: _isLoading ? null : _deleteItem,
                      child: const Icon(Icons.delete_outline),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Save Button
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      child: const Text("SAVE CHANGES"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

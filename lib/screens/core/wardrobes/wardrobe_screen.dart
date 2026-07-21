import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/user_model.dart';
import 'package:ootdmate_frontend/services/api-services/wardrobe_item_service.dart';
import 'package:ootdmate_frontend/models/wardrobe_item_model.dart';
import 'package:ootdmate_frontend/widgets/app_header.dart';
import 'package:ootdmate_frontend/widgets/glass_text_field.dart';

class WardrobeScreen extends StatefulWidget {
  final UserModel? userProfile;
  final String? avatarUrl;

  const WardrobeScreen({super.key, this.userProfile, this.avatarUrl});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final WardrobeItemService _wardrobeItemService = WardrobeItemService();

  late Future<List<WardrobeItemModel>> _futureWardrobe;

  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  bool _sortDescending = true; // newest first by reversing the list
  final Set<String> _categories = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData({String? nameQuery, String? category, bool? sortDesc}) {
    setState(() {
      _futureWardrobe = _wardrobeItemService
          .getWardrobeItems(name: nameQuery, category: category)
          .then((list) {
            // collect categories for filter dropdown
            for (final it in list) {
              if (it.category.isNotEmpty) _categories.add(it.category);
            }

            // apply sort client-side by reversing list when needed
            if ((sortDesc ?? _sortDescending) == true) {
              return list.reversed.toList();
            }
            return list;
          });
    });
  }

  void _openFilterModal() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        String? tempCategory = _selectedCategory;
        bool tempSortDesc = _sortDescending;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Category',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    initialValue: tempCategory,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ..._categories.map(
                        (c) =>
                            DropdownMenuItem<String?>(value: c, child: Text(c)),
                      ),
                    ],
                    onChanged: (v) => setModalState(() => tempCategory = v),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sort by upload',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          value: true,
                          groupValue: tempSortDesc,
                          onChanged: (v) =>
                              setModalState(() => tempSortDesc = v ?? true),
                          title: const Text('Newest first'),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          value: false,
                          groupValue: tempSortDesc,
                          onChanged: (v) =>
                              setModalState(() => tempSortDesc = v ?? false),
                          title: const Text('Oldest first'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop({
                          'category': tempCategory,
                          'sortDesc': tempSortDesc,
                        }),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      _selectedCategory = result['category'] as String?;
      _sortDescending = result['sortDesc'] as bool? ?? _sortDescending;
      _fetchData(
        nameQuery: _searchController.text.isEmpty
            ? null
            : _searchController.text,
        category: _selectedCategory,
        sortDesc: _sortDescending,
      );
    }
  }

  Widget _buildCategoryButton(String category, Color color) {
    final bool selected = _selectedCategory == category;
    return ElevatedButton(
      onPressed: () {
        setState(() { 
          _selectedCategory = category;
        });
        _fetchData(
          nameQuery: _searchController.text.isEmpty
              ? null
              : _searchController.text,
          category: _selectedCategory,
          sortDesc: _sortDescending,
        );
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(100, 17),
        padding: EdgeInsets.zero,
        backgroundColor: selected ? color : color.withAlpha(130),
        elevation: selected ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: selected ? AppTheme.primary : color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.userProfile?.fullName ?? 'Guest';
    final displayAvatar = widget.avatarUrl ?? widget.userProfile?.avatarUrl;

    return Scaffold(
      appBar: AppHeader(
        title: "Your Collection",
        subTitle: "Browse all your favorite outfits",
        avatarUrl: displayAvatar,
        username: displayName,
        currentUser: widget.userProfile,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: GlassTextField(
                        hintText: "Search ...",
                        controller: _searchController,
                        prefixIcon: Icons.search,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (query) {
                          _fetchData(nameQuery: _searchController.text);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.acidGreen.withAlpha(13),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _openFilterModal,
                      icon: Icon(Icons.filter_alt, color: AppTheme.acidGreen),
                      tooltip: 'Filter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryButton('Topwear', AppTheme.acidGreen),
                    const SizedBox(width: 12),
                    _buildCategoryButton('Bottomwear', AppTheme.success),
                    const SizedBox(width: 12),
                    _buildCategoryButton('Footwear', AppTheme.neonBlue),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<WardrobeItemModel>>(
                  future: _futureWardrobe,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppTheme.error,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Something went wrong",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text('${snapshot.error}'),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.checkroom,
                              size: 64,
                              color: AppTheme.glitchMagenta.withAlpha(130),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your wardrobe is empty',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add items to see them here',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }

                    final List<WardrobeItemModel> wardrobeList = snapshot.data!;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                      itemCount: wardrobeList.length,
                      itemBuilder: (context, index) {
                        final items = wardrobeList[index];

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          elevation: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: Image.network(
                                        items.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                    color: AppTheme.error,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black45,
                                            ],
                                          ),
                                        ),
                                        child: Text(
                                          items.name ?? items.category,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        items.name ?? items.category,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.more_vert,
                                      size: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

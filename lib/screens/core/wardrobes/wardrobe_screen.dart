import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/models/user_model.dart';
import 'package:ootdmate_frontend/services/api-services/wardrobe_item_service.dart';
import 'package:ootdmate_frontend/models/wardrobe_item_model.dart';
import 'package:ootdmate_frontend/widgets/ui/app_header.dart';
import 'package:ootdmate_frontend/widgets/ui/neumorphic_text_field.dart';
import 'package:ootdmate_frontend/widgets/ui/masonry_gridview_widget.dart';
import 'package:ootdmate_frontend/widgets/ui/wardrobe_empty_state.dart';
import 'package:ootdmate_frontend/widgets/ui/wardrobe_error_state.dart';

class WardrobeScreen extends StatefulWidget {
  final UserModel? userProfile;
  final String? avatarUrl;
  final ValueChanged<UserModel>? onProfileUpdated;

  const WardrobeScreen({super.key, this.userProfile, this.avatarUrl, this.onProfileUpdated});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final WardrobeItemService _wardrobeItemService = WardrobeItemService();

  List<WardrobeItemModel> _wardrobeItems = [];
  
  bool _isLoading = true;
  bool _isFetchingMore = false;
  String? _errorMessage;

  // Pagination
  int _currentPage = 1;
  final int _limit = 20;
  bool _hasMore = true;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  String? _selectedCategory;
  bool _sortDescending = true;
  final Set<String> _categories = {'Topwear', 'Bottomwear', 'Footwear', 'Outerwear', 'Accessories'}; // Provide some defaults to show

  @override
  void initState() {
    super.initState();
    _fetchData(); // Load first page
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScrollNotification(ScrollNotification scrollInfo) {
    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
      _fetchNextPage();
    }
  }

  Future<void> _fetchData({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    setState(() {
      if (refresh) {
        _isLoading = true;
      } else {
        _isFetchingMore = true;
      }
      _errorMessage = null;
    });

    try {
      final list = await _wardrobeItemService.getWardrobeItems(
        page: _currentPage,
        limit: _limit,
        name: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        category: _selectedCategory,
      );
      
      // Reverse if sorting by oldest first (assuming backend returns newest first by default)
      final processedList = _sortDescending ? list : list.reversed.toList();

      for (final it in list) {
        if (it.category.isNotEmpty) _categories.add(it.category);
      }
      
      setState(() {
        if (refresh) {
          _wardrobeItems = processedList;
        } else {
          _wardrobeItems.addAll(processedList);
        }
        
        // If the backend returns fewer items than the limit, we've reached the end
        if (list.length < _limit) {
          _hasMore = false;
        } else {
          _currentPage++;
        }
        
        _isLoading = false;
        _isFetchingMore = false;
      });
    } catch (e) {
      setState(() {
        if (refresh) {
          _errorMessage = e.toString();
          _isLoading = false;
        } else {
          _isFetchingMore = false;
          // Optionally show a toast for load more failure
        }
      });
    }
  }
  
  void _fetchNextPage() {
    if (_hasMore && !_isLoading && !_isFetchingMore) {
      _fetchData();
    }
  }
  
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchData(refresh: true);
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
                        (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
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
                          title: const Text('Newest first', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          value: false,
                          groupValue: tempSortDesc,
                          onChanged: (v) =>
                              setModalState(() => tempSortDesc = v ?? false),
                          title: const Text('Oldest first', style: TextStyle(fontSize: 14)),
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
      _fetchData(refresh: true);
    }
  }

  Widget _buildCategoryButton(String category, Color color) {
    final bool selected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() { 
            // Toggle off if already selected
            _selectedCategory = selected ? null : category;
          });
          _fetchData(refresh: true);
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.userProfile?.fullName ?? 'Guest';
    final displayAvatar = widget.avatarUrl ?? widget.userProfile?.avatarUrl;
    
    // Assign colors to dynamic categories for visual variety
    final colors = [AppTheme.acidGreen, AppTheme.success, AppTheme.neonBlue, AppTheme.glitchMagenta, AppTheme.cyberPurple];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          AppHeader(
            title: "Your Collection",
            subTitle: "Browse all your favorite outfits",
            avatarUrl: displayAvatar,
            username: displayName,
            currentUser: widget.userProfile,
            onProfileUpdated: widget.onProfileUpdated,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0, bottom: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: NeumorphicTextField(
                        hintText: "Search items...",
                        controller: _searchController,
                        prefixIcon: Icons.search,
                        textInputAction: TextInputAction.search,
                        onChanged: _onSearchChanged,
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
            ),
          ),
          if (_categories.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.toList().asMap().entries.map((entry) {
                      int idx = entry.key;
                      String cat = entry.value;
                      Color color = colors[idx % colors.length];
                      return _buildCategoryButton(cat, color);
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? WardrobeErrorState(
                        errorMessage: _errorMessage!,
                        onRetry: () => _fetchData(refresh: true),
                      )
                    : _wardrobeItems.isEmpty
                        ? const WardrobeEmptyState()
                        : NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              _onScrollNotification(scrollInfo);
                              return false;
                            },
                            child: MasonryGridViewWidget(
                              items: _wardrobeItems,
                              isFetchingMore: _isFetchingMore,
                              onRefreshNeeded: () => _fetchData(refresh: true),
                            ),
                          ),
          ),
        ),
      ),
    );
  }
}

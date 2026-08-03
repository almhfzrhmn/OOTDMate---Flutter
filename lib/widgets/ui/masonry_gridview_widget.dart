import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ootdmate_frontend/models/wardrobe_item_model.dart';
import 'package:ootdmate_frontend/core/theme/app_theme.dart';
import 'package:ootdmate_frontend/screens/core/wardrobes/item_details.dart';

class MasonryGridViewWidget extends StatelessWidget {
  final List<WardrobeItemModel> items;
  final VoidCallback onRefreshNeeded;

  final ScrollController? controller;
  final bool isFetchingMore;

  const MasonryGridViewWidget({
    super.key,
    required this.items,
    required this.onRefreshNeeded,
    this.controller,
    this.isFetchingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: MasonryGridView.builder(
            controller: controller,
            padding: const EdgeInsets.symmetric(vertical: 6),
            gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            itemCount: items.length,
            itemBuilder: (context, index) {
        final item = items[index];

        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemDetailsScreen(item: item),
              ),
            );
            if (result == true) {
              onRefreshNeeded();
            }
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            elevation: 4,
            shadowColor: Colors.black.withAlpha(100),
            child: Stack(
              children: [
                Hero(
                  tag: item.id,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: AppTheme.secondary,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: AppTheme.secondary,
                      child: Icon(
                        Icons.broken_image,
                        color: AppTheme.error,
                        size: 40,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name?.isNotEmpty == true ? item.name! : 'Unnamed Item',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.category,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.acidGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(
                              Icons.more_horiz,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  ),
  if (isFetchingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}
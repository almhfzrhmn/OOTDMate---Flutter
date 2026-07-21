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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData({String? nameQuery}) {
    setState(() {
      _futureWardrobe = _wardrobeItemService.getWardrobeItems(name : nameQuery);
    });
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
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
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
                IconButton(
                  onPressed: () {
                    //
                  },
                  icon: Icon(Icons.filter_alt, color: AppTheme.acidGreen,),
                )
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<WardrobeItemModel>>(
                future: _futureWardrobe,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Error occured : ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text("Your wardrobe is empty!"));
                  }
                  final List<WardrobeItemModel> wardrobeList = snapshot.data!;
              
                  return GridView.builder(
                    padding: EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: wardrobeList.length,
                    itemBuilder: (context, index) {
                      final items = wardrobeList[index];
              
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.network(
                                items.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: AppTheme.error,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                items.name ?? items.category,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
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
    );
  }
}

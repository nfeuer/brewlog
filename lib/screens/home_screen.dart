import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/coffee_bag.dart';
import '../providers/bags_provider.dart';
import '../providers/user_provider.dart';
import '../providers/shared_cups_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/bag_card.dart';
import 'bag_detail_screen.dart';
import 'profile_screen.dart';
import 'shared_tab.dart';
import 'cup_card_screen.dart';
import 'scan_qr_screen.dart';

/// Main home screen with tab-based navigation.
///
/// This is the primary UI screen shown after app launch. It provides:
///
/// **Tab Navigation:**
/// - **My Bags Tab**: Displays user's coffee bag collection
/// - **Shared Tab**: Shows cups received via QR code sharing (premium feature)
///
/// **App Bar Actions:**
/// - Search button - Opens search dialog to filter bags
/// - Profile button - Navigates to profile/settings screen
///
/// **View Modes:**
/// User can toggle between three view modes for displaying bags:
/// - Grid: Card grid layout (default)
/// - List: Detailed list view
/// - Rolodex: Animated carousel/swiper
///
/// **Sorting Options:**
/// - Latest: By last updated (default)
/// - Alphabetical: By bag title
/// - Score: By average rating
///
/// **Floating Action Button:**
/// - On "My Bags" tab: Add new bag
/// - On "Shared" tab: Scan QR code to import shared cup (premium only)
///
/// **State Management:**
/// Uses Riverpod providers to watch:
/// - [bagsProvider] for bag collection
/// - [userProfileProvider] for user preferences and premium status
/// - [sharedCupsProvider] for shared cups count badge
///
/// **Example Navigation:**
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const HomeScreen()),
/// );
/// ```
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final viewPref = ref.watch(viewPreferenceProvider);
    final sortOption = ref.watch(bagSortOptionProvider);
    final searchQuery = ref.watch(bagSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BrewLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearch,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(text: 'My Bags'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Shared'),
                  if (user?.isPaid == true) ...[
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final count = ref.watch(sharedCupsCountProvider);
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyBagsTab(viewPref, sortOption, searchQuery),
          const SharedTab(),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // QR Scanner button - bottom left
            FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanQRScreen(),
                  ),
                );
              },
              heroTag: 'qr_scanner',
              child: const Icon(Icons.qr_code_scanner),
            ),
            // New Bag button - bottom right
            FloatingActionButton.extended(
              onPressed: _createNewBag,
              label: const Text('New Bag'),
              icon: const Icon(Icons.add),
              heroTag: 'new_bag',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyBagsTab(
    ViewPreference viewPref,
    BagSortOption sortOption,
    String searchQuery,
  ) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          color: AppTheme.backgroundOffWhite,
          child: Row(
            children: [
              // View mode toggle
              SegmentedButton<ViewPreference>(
                segments: const [
                  ButtonSegment(
                    value: ViewPreference.grid,
                    icon: Icon(Icons.grid_view, size: 18),
                  ),
                  ButtonSegment(
                    value: ViewPreference.list,
                    icon: Icon(Icons.list, size: 18),
                  ),
                  ButtonSegment(
                    value: ViewPreference.rolodex,
                    icon: Icon(Icons.view_carousel, size: 18),
                  ),
                ],
                selected: {viewPref},
                onSelectionChanged: (Set<ViewPreference> selection) {
                  ref
                      .read(userProfileProvider.notifier)
                      .updateViewPreference(selection.first);
                },
              ),
              const SizedBox(width: 12),
              // Sort dropdown
              Expanded(
                child: DropdownButtonFormField<BagSortOption>(
                  value: sortOption,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: BagSortOption.latest,
                      child: Text('Latest'),
                    ),
                    DropdownMenuItem(
                      value: BagSortOption.alphabetical,
                      child: Text('Alphabetical'),
                    ),
                    DropdownMenuItem(
                      value: BagSortOption.score,
                      child: Text('Highest Score'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(bagSortOptionProvider.notifier).state = value;
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Bags list/grid
        Expanded(
          child: _buildBagsView(viewPref, searchQuery),
        ),
      ],
    );
  }

  Widget _buildBagsView(ViewPreference viewPref, String searchQuery) {
    return Consumer(
      builder: (context, ref, child) {
        final bags = ref.watch(searchedBagsProvider);

        if (bags.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.coffee_outlined,
                  size: 64,
                  color: AppTheme.textGray.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isNotEmpty
                      ? 'No bags found'
                      : 'No coffee bags yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textGray,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  searchQuery.isNotEmpty
                      ? 'Try a different search'
                      : 'Tap the button below to add your first bag!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGray,
                      ),
                ),
              ],
            ),
          );
        }

        switch (viewPref) {
          case ViewPreference.grid:
            return _buildGridView(bags);
          case ViewPreference.list:
            return _buildListView(bags);
          case ViewPreference.rolodex:
            return _buildRolodexView(bags);
        }
      },
    );
  }

  Widget _buildGridView(List<CoffeeBag> bags) {
    return GridView.builder(
      padding: AppStyles.screenPadding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: bags.length,
      itemBuilder: (context, index) {
        final bag = bags[index];
        return BagCard(
          bag: bag,
          onTap: () => _openBagDetail(bag.id),
          isGridView: true,
        );
      },
    );
  }

  Widget _buildListView(List<CoffeeBag> bags) {
    return ListView.builder(
      padding: AppStyles.screenPadding,
      itemCount: bags.length,
      itemBuilder: (context, index) {
        final bag = bags[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BagCard(
            bag: bag,
            onTap: () => _openBagDetail(bag.id),
            isGridView: false,
          ),
        );
      },
    );
  }

  Widget _buildRolodexView(List<CoffeeBag> bags) {
    return PageView.builder(
      itemCount: bags.length,
      controller: PageController(viewportFraction: 0.85),
      itemBuilder: (context, index) {
        final bag = bags[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 8),
          child: BagCard(
            bag: bag,
            onTap: () => _openBagDetail(bag.id),
            isGridView: true,
          ),
        );
      },
    );
  }

  void _openBagDetail(String bagId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BagDetailScreen(bagId: bagId),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: BagSearchDelegate(ref),
    );
  }

  void _createNewBag() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CupCardScreen(isNewBag: true),
      ),
    );
  }
}

// Search delegate for bags
class BagSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;

  BagSearchDelegate(this.ref);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    ref.read(bagSearchQueryProvider.notifier).state = query;
    final bags = ref.watch(searchedBagsProvider);

    return ListView.builder(
      itemCount: bags.length,
      itemBuilder: (context, index) {
        final bag = bags[index];
        return ListTile(
          leading: const Icon(Icons.coffee),
          title: Text(bag.displayTitle),
          subtitle: Text(bag.roaster),
          onTap: () {
            close(context, bag.id);
            // Navigate to bag detail
          },
        );
      },
    );
  }
}

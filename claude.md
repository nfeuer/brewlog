# BrewLog Development Roadmap

This document outlines planned features and future development for the BrewLog coffee tracking application.

## Important: Code Generation Required

After pulling these changes, you MUST run code generation to update Hive adapters:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This is required because new `@HiveField` annotations were added to the Cup and CoffeeBag models.

---

## Recently Implemented Features ✅

### Advanced Brewing Parameters
- **Espresso-specific fields**: Pre-infusion time, pressure (bars), yield weight
- **Pour over-specific fields**: Bloom water amount, pour schedule
- **Universal advanced fields**: TDS (Total Dissolved Solids), extraction yield percentage
- **Conditional display**: Fields only appear when relevant brew type is selected

### Environmental Conditions Tracking
- Room temperature during brewing
- Humidity percentage
- Altitude (meters)
- Time of day (Morning, Afternoon, Evening, Night)

### SCA Cupping Protocol
- Complete SCA cupping form implementation
- 11 scoring attributes (0-10 scale each):
  * Fragrance/Aroma (Dry)
  * Aroma (Wet)
  * Flavor
  * Aftertaste
  * Acidity
  * Body
  * Balance
  * Sweetness
  * Clean Cup
  * Uniformity
  * Overall
- Automatic total score calculation
- Defects notes field

### Enhanced Bean/Bag Details
- Processing method (Washed, Natural, Honey, Anaerobic, etc.)
- Region/origin (country, farm location)
- Harvest date
- Roast level (Light, Medium, Dark, etc.)
- Roast profile notes
- Bean screen size (e.g., 17/18)
- Certifications (Organic, Fair Trade, Bird Friendly, etc.)

### Drink Recipe System
- **Comprehensive drink recipe creation** for coffee-based beverages
- **Recipe components**:
  * Base type (Espresso, Drip, Pour Over, etc.)
  * Milk type and amount (Whole, Oat, Almond, etc.)
  * Syrups (Vanilla, Caramel, Hazelnut, etc.)
  * Sweeteners (Sugar, Honey, Stevia, etc.)
  * Ice option for iced drinks
  * Additional ingredients (Whipped Cream, Alcohol, Tonic Water, etc.)
  * Preparation notes
- **Recipe book management**:
  * Save and name drink recipes
  * Search recipes by name
  * View recipe details in expandable cards
  * Edit and delete recipes
  * Usage counter tracks how many times each recipe is used
- **Integration with cups**:
  * Select saved recipes when creating cups
  * Cup cards show "Recipe" badge when drink recipe was used
  * Auto-increment usage count when recipe is used
  * Recipes linked to cups via drinkRecipeId field
- **Recipe book screen** accessible from profile
  * Displays usage count for popular recipes (e.g., "3×")
  * Real-time search filtering
  * Purple-themed UI to distinguish from coffee ratings

### Per-Cup Field Visibility
- **Independent visibility settings** for each cup
- Each cup saves its own field visibility preferences
- New cups start with current default visibility settings
- Edit visibility settings without affecting global defaults or other cups
- Provides flexibility for different brewing scenarios

### Equipment Details Display
- **Expandable equipment details** in cup view
- Shows full equipment setup information when expanded
- Displays only fields with actual values
- Includes grinder, brewer, kettle, scale, water, and filter details
- Clean, icon-based formatting for easy reading

All new fields are:
- Optional (won't break existing data)
- Hideable via field visibility settings
- Properly integrated with JSON serialization for Firebase sync

---

## Planned Features

### 1. Sharing & Social Features 🌐

#### Share Cup/Recipe
**Goal**: Allow users to share their coffee recipes and tasting notes with others.

**Implementation Plan**:
1. **Export Formats**:
   - Pretty-printed recipe card (image)
   - JSON format for importing into other BrewLog instances
   - Plain text format for messaging apps
   - PDF format with full details

2. **Social Sharing**:
   - Generate shareable links (using Firebase Dynamic Links)
   - Share directly to social media platforms
   - QR code generation for in-person sharing
   - Track share count per cup

3. **Recipe Import**:
   - Import shared recipes from other users
   - Preview before importing
   - Option to import as template (without notes)
   - Merge imported recipe with existing bag if match found

4. **Community Features** (Future Phase):
   - Optional public recipe gallery
   - Follow other users
   - Like/bookmark recipes
   - Comments on shared recipes
   - Trending recipes feed

**Technical Considerations**:
- Use Firebase Firestore for storing shared recipes
- Implement Firebase Storage for recipe card images
- Add privacy controls (public/friends-only/private)
- Rate limiting to prevent spam
- Moderation system for public content

**Data Structure for Shared Cup**:
```dart
class SharedCup {
  String id;
  String originalCupId;
  String userId;
  String userName;
  DateTime sharedAt;

  // Coffee info
  String coffeeName;
  String roaster;
  Map<String, dynamic> brewParameters;
  double? rating;
  List<String> flavorTags;
  String? tastingNotes;

  // Engagement
  int viewCount;
  int likeCount;
  int importCount;

  // Privacy
  SharePrivacy privacy; // public, friends, unlisted
}
```

---

### 2. Smart Device Integration 📱⚖️

#### Bluetooth Scale Integration
**Goal**: Automatically log weight measurements from smart coffee scales.

**Supported Devices**:
- Acaia scales (Pearl, Lunar, Pyxis)
- Felicita scales (Arc, Parallel, Incline)
- Timemore scales
- Generic Bluetooth scales with weight broadcast

**Features**:
1. **Real-time Weight Tracking**:
   - Auto-detect connected scale
   - Display live weight during brewing
   - Record dose weight automatically
   - Record final output weight
   - Calculate ratio in real-time

2. **Pour-Over Timer Integration**:
   - Combined timer + scale view
   - Visual pour schedule overlay
   - Haptic feedback at target weights
   - Export brew curve graph

3. **Espresso Shot Timer**:
   - Auto-start on first drop detection
   - Record pre-infusion duration
   - Record total shot time
   - Pressure profiling (for supported devices)

**Implementation**:
```dart
abstract class SmartScale {
  Stream<double> get weightStream;
  Future<void> connect();
  Future<void> disconnect();
  Future<void> tare();
  bool get isConnected;
}

class AcaiaScale implements SmartScale {
  // Acaia-specific protocol implementation
}
```

#### Espresso Machine Integration
**Goal**: Log shot parameters from smart espresso machines.

**Supported Machines**:
- Decent Espresso machines (via Bluetooth API)
- Breville Oracle Touch/Barista Touch (via app)
- La Marzocco Linea Mini/GS3 (via WiFi)
- Gaggia Classic Pro with PID mod

**Auto-logged Data**:
- Brew pressure profile
- Brew temperature profile
- Pre-infusion time
- Shot volume
- Shot time
- Group head temperature

#### Coffee Grinder Integration
**Goal**: Log grind settings from smart grinders.

**Supported Grinders**:
- Eureka Mignon Smart
- Fellow Ode Gen 2
- Baratza Forte BG (with Bluetooth)
- Weber Workshops EG-1 (via app)

**Auto-logged Data**:
- Grind setting (numeric)
- Dose weight
- Grind time
- Grinder RPM

**Technical Considerations**:
- Flutter `flutter_blue_plus` package for Bluetooth
- Device-specific protocol implementations
- Handle connection reliability issues
- Battery optimization
- Background weight monitoring
- Secure pairing/authentication

---

### 3. Analytics & Insights 📊

**Goal**: Provide actionable insights from brewing data.

#### Planned Analytics Features:

1. **Cost Tracking**:
   - Cost per cup calculation
   - Monthly/yearly coffee spending
   - Cost per gram analysis
   - Waste tracking (unused beans)

2. **Brew Success Rate**:
   - Percentage of brews rated above threshold
   - Success rate by brew method
   - Success rate by time of day
   - Environmental condition correlation

3. **Trends Over Time**:
   - Rating trends per bag
   - Average rating by roaster
   - Grind setting drift over bag life
   - Water temperature preferences

4. **Comparison Mode**:
   - Side-by-side recipe comparison
   - Before/after adjustment comparison
   - Multiple bags of same origin comparison
   - Roaster comparison

5. **Optimization Suggestions**:
   - "Your best espresso shots used 18g dose and 9 bar pressure"
   - "You rate pour overs higher in the morning"
   - "Your V60 brews score 0.5 points higher than Kalita"
   - "This bag peaked at day 12 after roasting"

6. **Equipment Performance**:
   - Rating by equipment setup
   - Most-used equipment
   - Equipment maintenance scheduling
   - Grinder drift alerts

**Implementation**:
```dart
class BrewAnalytics {
  // Cost calculations
  double calculateCostPerCup(Cup cup, CoffeeBag bag);
  double getTotalSpending(DateTime start, DateTime end);

  // Success metrics
  double getSuccessRate({String? brewType, TimeOfDay? timeOfDay});
  Map<String, double> getSuccessRateByMethod();

  // Trends
  List<DataPoint> getRatingTrend(String bagId);
  Map<String, double> getAverageRatingByRoaster();

  // Comparisons
  ComparisonResult compareCups(String cupId1, String cupId2);

  // Recommendations
  List<BrewRecommendation> getOptimizationSuggestions();
}
```

**Visualization**:
- Charts using `fl_chart` package
- Rating distribution histograms
- Time series graphs
- Scatter plots for parameter correlation
- Heatmaps for time-of-day performance

---

### 4. Workflow Features ⚡

#### Quick Repeat Previous Recipe
**Status**: User requested more details

**Concept**: One-tap button to start a new cup with the same parameters as a previous cup.

**Proposed Implementation**:
1. **"Repeat" Button** on cup detail screen
   - Copies all brewing parameters
   - Does NOT copy rating/notes/photos
   - Opens new cup form pre-filled
   - User can adjust before saving

2. **"Brew Again" Widget** on home screen
   - Shows last cup from each active bag
   - Quick-access "Repeat" button
   - Shows bag days-since-roast

3. **Recipe Templates**:
   - Save favorite recipes as templates
   - Template library view
   - Apply template when starting new cup
   - Templates work across different bags

**User Questions to Address**:
- Should it auto-save or open for editing?
- Include equipment setup in template?
- How to handle bag-specific fields?
- Template naming/organization system?

#### Batch Cupping Session
**Concept**: Cup multiple coffees in one session for comparison.

**Features**:
- Create cupping session (date, participants)
- Add multiple bags to session
- Parallel tasting note entry
- Side-by-side comparison view
- Export session results
- Calculate consensus scores

#### Brew History Calendar
**Concept**: Calendar view of all brews.

**Features**:
- Monthly calendar with brew indicators
- Color-coded by rating
- Tap date to see brews
- Streak tracking (consecutive days)
- Goal setting (brews per week)

---

### 5. Data Management 💾

#### Backup & Restore
- Export all data to JSON
- Import from JSON backup
- Firebase continuous backup
- Scheduled auto-backups

#### Data Migration
- Import from other coffee apps
- CSV import/export
- Compatible with common formats

#### Multi-Device Sync
- Real-time sync via Firebase
- Conflict resolution
- Offline mode with sync queue
- Sync status indicator

---

### 6. Organization Features 📋

**Status**: Skipped for now (per user request)

**Future Consideration**:
- Tag system for bags
- Custom categories
- Advanced search/filter
- Saved filter presets
- Bag collections

---

## Technical Debt & Maintenance

### Code Quality
- [ ] Add unit tests for new field calculations
- [ ] Add widget tests for new form sections
- [ ] Add integration tests for data flow
- [ ] Document all new fields in code comments

### Performance
- [ ] Optimize field visibility lookups
- [ ] Lazy load conditional sections
- [ ] Profile form rendering performance
- [ ] Add loading states for heavy operations

### Accessibility
- [ ] Screen reader support for all new fields
- [ ] Keyboard navigation improvements
- [ ] Haptic feedback for important actions
- [ ] High contrast mode support

### Localization
- [ ] Add translations for all new fields
- [ ] Support metric/imperial unit preferences
- [ ] Date format localization
- [ ] Number format localization

---

## Contributing

When implementing features from this roadmap:

1. **Create feature branch**: `feature/feature-name`
2. **Update this document**: Mark progress, add notes
3. **Write tests**: Unit + integration tests required
4. **Update documentation**: User-facing docs in app
5. **Consider privacy**: Follow GDPR guidelines
6. **Performance**: Profile before/after

---

## Questions for Discussion

1. **Sharing Features**: Should we build our own social platform or integrate with existing ones?
2. **Smart Devices**: Which device integrations are highest priority?
3. **Analytics**: What insights are most valuable to users?
4. **Workflow**: Are there other common workflows to optimize?
5. **Monetization**: Should advanced features be premium? Which ones?

---

## Version History

- **v1.0** - Initial release (basic bag & cup tracking)
- **v1.1** - Photo support, field visibility
- **v1.2** - Equipment tracking, copy recipe
- **v1.3** - Field customization per bag
- **v2.0** - Advanced parameters, SCA cupping, environmental tracking
- **v2.1** - *Current*: Drink recipe system, per-cup field visibility, equipment details display
- **v2.2** - *Planned*: Analytics dashboard
- **v2.3** - *Planned*: Sharing features
- **v3.0** - *Future*: Smart device integration

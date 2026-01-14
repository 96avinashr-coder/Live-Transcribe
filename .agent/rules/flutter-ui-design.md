---
trigger: always_on
---

---

# Flutter UI Design

## Core Philosophy

Flutter UI design is not about widgets — it is about **constraints, composition, and intent**.

Every pixel must justify its existence. Every rebuild must earn its CPU time. Flutter is a declarative framework that rewards precision and punishes ambiguity. Your UI is a function of state, and every rendering decision must be defensible under scrutiny.

Understanding Flutter requires a paradigm shift: you are not building screens, you are **composing mathematical transformations of rectangular constraints**. The framework is unforgiving to those who treat it like imperative DOM manipulation or native view hierarchies.

---

## Mental Model (Non-Negotiable)

**Constraints go down. Sizes go up. Parents set limits, children choose size, parents place children.**

This is not a suggestion — this is the rendering contract. If you do not internalize this three-phase protocol, Flutter will feel random forever.

1. **Constraints flow downward**: Parent widgets pass BoxConstraints to children
2. **Sizes propagate upward**: Children return their chosen dimensions within constraints
3. **Positioning is parental**: Only parents control where children appear

Breaking this mental model leads to unbounded constraint errors, layout overflow, and rendering chaos. When debugging layout, always trace the constraint chain from root to leaf.

### The Constraint Trap

Beginners assume `Container(width: 100)` creates a 100dp widget. Wrong. If the parent passes tight constraints (min == max), your width is ignored. Flutter is deterministic, not magical.

---

## Layout Mastery

### Flex System (Row / Column)

Row and Column are **Flex engines**, not containers. They solve the one-dimensional bin-packing problem using flex factors, not arbitrary positioning.

- **MainAxisAlignment**: distributes space along the primary axis
- **CrossAxisAlignment**: positions children perpendicular to main axis
- **MainAxisSize**: min (shrink-wrap) vs. max (consume available space)

#### Expanded vs. Flexible

This distinction separates intermediate from advanced engineers:

- **Expanded**: `Flexible(fit: FlexFit.tight)` — aggressively consumes remaining space
- **Flexible**: `Flexible(fit: FlexFit.loose)` — respects child's intrinsic size within flex allocation

Expanded forces children to fill allocated space. Flexible allows children to be smaller. Choose based on whether content should stretch or breathe.

#### Spacer Semantics

`Spacer(flex: n)` is not a hack — it's semantic empty space. It makes intent explicit: "I want proportional spacing here." Better than invisible Expanded containers.

### Stack: Overlapping Intent

Stack is for **z-axis composition**, not lazy layout escapism. If you're using Stack to avoid flex math, you're accumulating technical debt.

- Always set `alignment` explicitly
- Use `Positioned` for absolute control
- Consider `IndexedStack` for tab-like content switching
- Remember: Stack's size is determined by positioned vs. non-positioned children

### LayoutBuilder Rule

Use LayoutBuilder for **adaptive logic**, not MediaQuery everywhere.

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) return MobileLayout();
    return DesktopLayout();
  },
)
```

MediaQuery is global state — it triggers rebuilds across your entire widget tree when device orientation changes. LayoutBuilder is scoped, surgical, and semantically correct for layout-driven decisions.

---

## Responsive Strategy

Breakpoints are not arbitrary numbers — they represent **interaction paradigm shifts**:

- **<600dp → Mobile**: Single-column, bottom navigation, thumb-zone optimization
- **600–1024dp → Tablet**: Dual-pane possible, side navigation consideration, landscape-first
- **>1024dp → Desktop**: Multi-column grids, persistent navigation, mouse/keyboard primacy

**Do not just scale font sizes.** Switch navigation patterns, adjust information density, change interaction models. Responsive design is behavioral, not cosmetic.

### Adaptive Patterns

- **Navigation**: BottomNavigationBar → NavigationRail → NavigationDrawer
- **Dialogs**: Fullscreen modal → Centered dialog → Inline panels
- **Lists**: Single column → Grid → Table with sortable columns

---

## Design Systems

A design system is not a Figma file — it's an **enforceable constraint system**.

### Theme Architecture

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: brandColor),
  textTheme: GoogleFonts.interTextTheme(),
  extensions: [CustomColors(), CustomSpacing()],
)
```

- **One ThemeData per brightness**: Light and dark themes are not variants, they're distinct systems
- **Never hardcode colors**: `Color(0xFF...)` is a smell. Every color must come from theme
- **Semantic tokens over visual names**: `onSurface` beats `grey800`

### ThemeExtension Pattern

For domain-specific tokens beyond material defaults:

```dart
class CustomColors extends ThemeExtension<CustomColors> {
  final Color success;
  final Color warning;
  // lerp, copyWith implementations
}
```

This enables theme-aware custom properties that survive theme switching.

---

## Typography Discipline

Text rendering is where amateur UIs reveal themselves.

### TextTheme Roles

Use TextTheme roles, never raw TextStyle instantiation:

- `displayLarge/Medium/Small`: Hero text, landing pages
- `headlineLarge/Medium/Small`: Section headers
- `titleLarge/Medium/Small`: Card titles, list headers
- `bodyLarge/Medium/Small`: Paragraph text
- `labelLarge/Medium/Small`: Buttons, tabs, chips

### Typographic Truth

**Line height > font size importance.**

A 14sp font with 1.5 line height is more readable than 16sp with 1.2 line height. Optical balance beats mathematical symmetry — adjust letter spacing, not just size.

### Text Scaling

Test at 200% text scale. If your UI breaks, you've failed accessibility. Use `MediaQuery.textScaleFactorOf(context)` for math that needs scale awareness.

---

## Widget Composition

### Stateless-First Philosophy

Prefer StatelessWidget + immutable data. State is complexity — minimize its surface area.

```dart
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const ProductCard({required this.product, required this.onTap});
  // ...
}
```

Immutability enables const constructors, which enable build skipping, which enables 60fps.

### Decomposition Discipline

**If a widget exceeds 150 lines, it is lying to you.**

Large widgets hide multiple responsibilities. Ruthlessly extract:

- Separate presentation from behavior
- Extract complex subtrees into named widgets
- Break at natural semantic boundaries (header, body, footer)

### Build Method Purity

The build method is a **pure function**. Given the same props, it must return the same widget tree. No side effects. No network calls. No timers.

---

## Animation Doctrine

Animation is communication — it guides attention, provides feedback, and creates coherence.

### Implicit Animations

Use when state changes are discrete:

```dart
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  color: isSelected ? Colors.blue : Colors.grey,
)
```

Available implicit animations: `AnimatedOpacity`, `AnimatedPositioned`, `AnimatedAlign`, `AnimatedPadding`, etc.

### Explicit Animations

Use when you need:

- **Gesture-driven motion**: User drags, animation follows
- **Physics-based behavior**: SpringSimulation, GravitySimulation
- **Sequenced choreography**: Staggered entrances, complex timing

```dart
class AnimatedWidget extends StatefulWidget {
  @override
  State<AnimatedWidget> createState() => _AnimatedWidgetState();
}

class _AnimatedWidgetState extends State<AnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose(); // Non-negotiable
    super.dispose();
  }
}
```

**AnimationControllers are resources — dispose them like weapons.** Leaked controllers cause memory leaks and phantom animations.

### Animation Curves

Curves are not decoration — they communicate physics:

- `Curves.easeInOut`: Natural, symmetric motion
- `Curves.easeOut`: Decelerating arrival (most common)
- `Curves.elasticOut`: Playful overshoot
- `Curves.fastOutSlowIn`: Material Design standard

---

## Performance Law

Performance is not optimization — it's **default behavior done correctly**.

### The const Manifesto

`const` is free performance. Const widgets are canonicalized — Flutter reuses the same instance across rebuilds.

```dart
const SizedBox(height: 16), // Reused forever
SizedBox(height: spacing), // New allocation every build
```

Mark every widget const that can be const. This is not premature optimization — it's correctness.

### setState Placement

**setState high in tree is sabotage.** It invalidates the entire subtree for rebuilding.

Bad:
```dart
class HomeScreen extends StatefulWidget { // setState rebuilds everything
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
```

Good:
```dart
class HomeScreen extends StatelessWidget { // Pushes state down
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      StaticHeader(),
      StatefulContentArea(), // Only this rebuilds
    ]);
  }
}
```

### RepaintBoundary

RepaintBoundary isolates repainting to subtrees. Use when:

- Child animates independently of siblings
- Complex static content sits beside dynamic content
- Profiling shows unnecessary repaints

Do not cargo-cult — measure first. Excessive RepaintBoundaries fragment rendering and increase memory.

### Build Method Efficiency

**Never compute inside build.** Build is called frequently — on every ancestor setState, on theme changes, on rebuilds.

Bad:
```dart
Widget build(BuildContext context) {
  final sortedItems = items.sort((a, b) => ...); // Repeated every build
  return ListView(children: sortedItems);
}
```

Good:
```dart
Widget build(BuildContext context) {
  return ListView(children: _sortedItems); // Computed once in state
}
```

---

## Lists & Scrolling

### Builder Constructors Always

`ListView.builder`, `GridView.builder` — never construct entire lists upfront. Builders create widgets on-demand as they scroll into view.

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

For 10,000 items, this renders ~20 widgets. Non-builder constructs 10,000 widgets immediately.

### Key Identity

Keys are identity, not decoration. Use keys when:

- Reordering lists
- Inserting/removing items
- Preserving state across rebuilds

```dart
ListView.builder(
  itemBuilder: (context, index) {
    final item = items[index];
    return ItemWidget(key: ValueKey(item.id), item: item);
  },
)
```

Without keys, Flutter matches by position. With keys, Flutter matches by identity, preserving state correctly during reorders.

### Sliver Protocol

Use slivers when you care about scroll physics and composition:

- `SliverAppBar`: Collapsing headers
- `SliverGrid`/`SliverList`: Mixed scrollable content
- `SliverPersistentHeader`: Sticky headers

CustomScrollView coordinates multiple slivers in a single scroll view. This enables effects impossible with basic ListView.

---

## Platform Adaptation

### Platform Respect

iOS ≠ Android ≠ Desktop. Users have platform expectations:

- **iOS**: Back swipe, Cupertino widgets, SF Pro font
- **Android**: Back button, Material widgets, Roboto font  
- **Desktop**: Mouse hover states, keyboard navigation, dense layouts

Use `Platform.isIOS` or `Theme.of(context).platform` to conditionally render platform-appropriate widgets.

### Cupertino Is Not Optional

If UX matters, Cupertino is mandatory for iOS. `CupertinoNaviga
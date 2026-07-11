# Responsive Design Guide

## Overview
This guide explains how to make your Flutter app responsive across different screen sizes while keeping the laptop/desktop view unchanged.

## Responsive Utility

The `Responsive` class automatically scales UI elements based on screen size:

- **Desktop (≥ 900px)**: 100% size (no scaling)
- **Tablet (600-899px)**: 90% size
- **Mobile (< 600px)**: 75% size

## Usage

### 1. Basic Usage with Extension

```dart
import 'package:naiyo24_business_tool/theme/theme.dart';

Widget build(BuildContext context) {
  final responsive = context.responsive;
  
  return Container(
    padding: responsive.padding(all: 16),
    child: Text(
      'Hello',
      style: TextStyle(fontSize: responsive.fontSize(24)),
    ),
  );
}
```

### 2. Responsive Spacing

```dart
// Instead of:
const EdgeInsets.all(32)

// Use:
responsive.padding(all: 32)  // Will be 24px on mobile, 32px on desktop

// Or:
responsive.padding(
  horizontal: 16,
  vertical: 24,
)
```

### 3. Responsive Font Sizes

```dart
// Instead of:
TextStyle(fontSize: 24)

// Use:
TextStyle(fontSize: responsive.fontSize(24))  // Will be 18px on mobile
```

### 4. Responsive Icon Sizes

```dart
// Instead of:
Icon(Icons.home, size: 32)

// Use:
Icon(Icons.home, size: responsive.iconSize(32))  // Will be 24px on mobile
```

### 5. Responsive Border Radius

```dart
// Instead of:
BorderRadius.circular(16)

// Use:
BorderRadius.circular(responsive.borderRadius(16))  // Will be 12px on mobile
```

### 6. Screen-Specific Values

```dart
// Get different values for different screen sizes
final columns = responsive.value<int>(
  mobile: 1,
  tablet: 2,
  desktop: 3,
);
```

### 7. Using Builder Widget for Context

When you need responsive values in a subtree, use `Builder`:

```dart
Builder(
  builder: (context) {
    final responsive = context.responsive;
    return Container(
      padding: responsive.padding(all: 16),
      // ... rest of your widget
    );
  }
)
```

## Example: Updating a Complete Widget

### Before (Fixed Sizes):
```dart
Container(
  padding: const EdgeInsets.all(32),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: Row(
    children: [
      Icon(Icons.wallet, size: 32),
      const SizedBox(width: 24),
      Text(
        'Total Balance',
        style: TextStyle(fontSize: 32),
      ),
    ],
  ),
)
```

### After (Responsive):
```dart
Builder(
  builder: (context) {
    final responsive = context.responsive;
    return Container(
      padding: responsive.padding(all: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(responsive.borderRadius(20)),
        boxShadow: [
          BoxShadow(
            blurRadius: responsive.spacing(12),
            offset: Offset(0, responsive.spacing(4)),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.wallet, size: responsive.iconSize(32)),
          SizedBox(width: responsive.spacing(24)),
          Text(
            'Total Balance',
            style: TextStyle(fontSize: responsive.fontSize(32)),
          ),
        ],
      ),
    );
  }
)
```

## Common Patterns

### 1. Cards with Responsive Padding
```dart
Card(
  child: Padding(
    padding: context.responsive.padding(all: 16),
    child: YourContent(),
  ),
)
```

### 2. Buttons with Responsive Sizing
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: context.responsive.padding(
      horizontal: 20,
      vertical: 12,
    ),
  ),
  child: Text(
    'Click Me',
    style: TextStyle(
      fontSize: context.responsive.fontSize(14),
    ),
  ),
)
```

### 3. Responsive Data Tables
```dart
DataTable(
  dataRowMaxHeight: context.responsive.spacing(64),
  dataRowMinHeight: context.responsive.spacing(48),
  // ... columns and rows
)
```

## Benefits

✅ **Desktop unchanged** - Laptop/desktop view remains exactly the same  
✅ **Mobile optimized** - Everything is 25% smaller on mobile, fitting better  
✅ **Tablet balanced** - Tablets get a 10% reduction for optimal viewing  
✅ **Consistent scaling** - All UI elements scale proportionally  
✅ **Easy to use** - Simple API with context extension  
✅ **No manual calculations** - Automatic scaling based on screen width  

## When to Use

Use responsive sizing for:
- ✅ Padding and margins
- ✅ Font sizes
- ✅ Icon sizes
- ✅ Border radius
- ✅ Shadow blur radius
- ✅ Container dimensions
- ✅ Button heights
- ✅ Card spacing

Don't use for:
- ❌ Layout structure (use responsive widgets like Row/Column)
- ❌ Grid column counts (use `value()` method instead)
- ❌ Breaking changes to functionality

## Testing

Test your responsive UI by:
1. Running on mobile device or emulator
2. Resizing browser window (for web)
3. Using Flutter DevTools device preview
4. Checking all screen orientations

## Scale Factors

You can adjust the scale factors in `responsive.dart`:

```dart
double get scaleFactor {
  if (_isDesktop) return 1.0;    // Desktop: no change
  if (_isTablet) return 0.9;     // Tablet: 10% smaller
  return 0.75;                    // Mobile: 25% smaller
}
```

Adjust these values if needed for your design requirements.

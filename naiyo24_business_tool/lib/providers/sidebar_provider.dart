import 'package:flutter_riverpod/flutter_riverpod.dart';

class SidebarExpanded extends AutoDisposeNotifier<bool> {
  @override
  bool build() {
    return true;
  }

  void toggle() {
    state = !state;
  }

  void setExpanded(bool value) {
    state = value;
  }
}

// Manual provider
final sidebarExpandedProvider = AutoDisposeNotifierProvider<SidebarExpanded, bool>(
  () => SidebarExpanded(),
);

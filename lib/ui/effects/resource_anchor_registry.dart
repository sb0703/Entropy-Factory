import 'package:flutter/widgets.dart';

import '../../game/game_state.dart';

class ResourceAnchorRegistry {
  final Map<ResourceType, GlobalKey> _keys = {};

  GlobalKey keyFor(ResourceType type) {
    return _keys.putIfAbsent(type, GlobalKey.new);
  }

  GlobalKey? keyForType(ResourceType type) {
    return _keys[type];
  }
}

import 'package:flutter/material.dart';

OverlayEntry? activeReactionOverlayEntry;

void removeReactionOverlay() {
  activeReactionOverlayEntry?.remove();
  activeReactionOverlayEntry = null;
}

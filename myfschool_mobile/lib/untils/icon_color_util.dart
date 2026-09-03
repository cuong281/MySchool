import 'package:flutter/material.dart';

class IconColorUtil {
  static Color parseColor(String colorStr) {
    if (colorStr.isEmpty) return Colors.blue;
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      } else if (colorStr.startsWith('0x')) {
        return Color(int.parse(colorStr));
      }
      return Colors.blue;
    } catch (e) {
      return Colors.blue;
    }
  }

  static IconData parseIcon(String iconName) {
    switch (iconName) {
      case 'school': return Icons.school_rounded;
      case 'robotics': return Icons.precision_manufacturing_rounded;
      case 'sports': return Icons.sports_soccer_rounded;
      case 'celebration': return Icons.celebration_rounded;
      case 'mic': return Icons.mic_rounded;
      case 'business': return Icons.business_rounded;
      case 'events': return Icons.emoji_events_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'school_rounded': return Icons.school_rounded;
      case 'precision_manufacturing_rounded': return Icons.precision_manufacturing_rounded;
      case 'sports_soccer_rounded': return Icons.sports_soccer_rounded;
      case 'celebration_rounded': return Icons.celebration_rounded;
      case 'mic_rounded': return Icons.mic_rounded;
      case 'business_rounded': return Icons.business_rounded;
      case 'emoji_events_rounded': return Icons.emoji_events_rounded;
      case 'music_note_rounded': return Icons.music_note_rounded;
      default: return Icons.event;
    }
  }
}

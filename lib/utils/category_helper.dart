import 'package:flutter/material.dart';

class CategoryHelper {
  static const List<String> categories = [
    'Sosmed',
    'Email',
    'Finansial',
    'E-commerce',
    'Game',
    'Streaming',
    'Produktivitas',
    'Lainnya',
  ];

  static IconData getIcon(String category) {
    switch (category) {
      case 'Sosmed':
        return Icons.people_outline_rounded;
      case 'Email':
        return Icons.email_outlined;
      case 'Finansial':
        return Icons.account_balance_wallet_outlined;
      case 'E-commerce':
        return Icons.shopping_bag_outlined;
      case 'Game':
        return Icons.games_outlined;
      case 'Streaming':
        return Icons.movie_outlined;
      case 'Produktivitas':
        return Icons.work_outline_rounded;
      case 'Lainnya':
      default:
        return Icons.more_horiz_rounded;
    }
  }

  static Color getColor(String category) {
    switch (category) {
      case 'Sosmed':
        return Colors.blue;
      case 'Email':
        return Colors.red;
      case 'Finansial':
        return Colors.green;
      case 'E-commerce':
        return Colors.orange;
      case 'Game':
        return Colors.purple;
      case 'Streaming':
        return Colors.redAccent;
      case 'Produktivitas':
        return Colors.teal;
      case 'Lainnya':
      default:
        return Colors.grey;
    }
  }
}

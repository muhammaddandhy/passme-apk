import 'package:flutter/material.dart';

class IconHelper {
  /// Get icon type based on title/username
  static String getIconType(String title, String username) {
    final lowerTitle = title.toLowerCase();
    final lowerUsername = username.toLowerCase();

    // Check for Gmail
    if (lowerTitle.contains('gmail') || 
        lowerTitle.contains('google') ||
        lowerUsername.contains('@gmail.com')) {
      return 'gmail';
    }

    // Check for Facebook
    if (lowerTitle.contains('facebook') || 
        lowerTitle.contains('fb') ||
        lowerUsername.contains('facebook')) {
      return 'facebook';
    }

    // Check for Instagram
    if (lowerTitle.contains('instagram') || 
        lowerTitle.contains('ig') ||
        lowerUsername.contains('instagram')) {
      return 'instagram';
    }

    // Check for Twitter/X
    if (lowerTitle.contains('twitter') || 
        lowerTitle.contains('x.com') ||
        lowerTitle.contains('x ')) {
      return 'twitter';
    }

    // Check for WhatsApp
    if (lowerTitle.contains('whatsapp') || 
        lowerTitle.contains('wa ') ||
        lowerTitle.contains('whats app')) {
      return 'whatsapp';
    }

    // Check for LinkedIn
    if (lowerTitle.contains('linkedin') || 
        lowerTitle.contains('linked in')) {
      return 'linkedin';
    }

    // Check for YouTube
    if (lowerTitle.contains('youtube') || 
        lowerTitle.contains('yt ')) {
      return 'youtube';
    }

    // Check for TikTok
    if (lowerTitle.contains('tiktok') || 
        lowerTitle.contains('tik tok')) {
      return 'tiktok';
    }

    // Check for Telegram
    if (lowerTitle.contains('telegram') || 
        lowerTitle.contains('tg ')) {
      return 'telegram';
    }

    // Check for Discord
    if (lowerTitle.contains('discord')) {
      return 'discord';
    }

    // Check for GitHub
    if (lowerTitle.contains('github') || 
        lowerTitle.contains('git hub')) {
      return 'github';
    }

    // Check for Amazon
    if (lowerTitle.contains('amazon')) {
      return 'amazon';
    }

    // Check for Netflix
    if (lowerTitle.contains('netflix')) {
      return 'netflix';
    }

    // Check for Spotify
    if (lowerTitle.contains('spotify')) {
      return 'spotify';
    }

    // Check for PayPal
    if (lowerTitle.contains('paypal') || 
        lowerTitle.contains('pay pal')) {
      return 'paypal';
    }

    // Default
    return 'default';
  }

  /// Get icon data based on icon type
  static IconData getIconData(String iconType) {
    switch (iconType) {
      case 'gmail':
        return Icons.mail;
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'twitter':
        return Icons.chat_bubble_outline;
      case 'whatsapp':
        return Icons.chat;
      case 'linkedin':
        return Icons.business;
      case 'youtube':
        return Icons.play_circle_outline;
      case 'tiktok':
        return Icons.music_note;
      case 'telegram':
        return Icons.send;
      case 'discord':
        return Icons.forum;
      case 'github':
        return Icons.code;
      case 'amazon':
        return Icons.shopping_cart;
      case 'netflix':
        return Icons.movie;
      case 'spotify':
        return Icons.music_video;
      case 'paypal':
        return Icons.payment;
      default:
        return Icons.lock_outline;
    }
  }

  /// Get icon color based on icon type
  static Color getIconColor(String iconType) {
    switch (iconType) {
      case 'gmail':
        return const Color(0xFFEA4335); // Gmail red
      case 'facebook':
        return const Color(0xFF1877F2); // Facebook blue
      case 'instagram':
        return const Color(0xFFE4405F); // Instagram pink
      case 'twitter':
        return const Color(0xFF1DA1F2); // Twitter blue
      case 'whatsapp':
        return const Color(0xFF25D366); // WhatsApp green
      case 'linkedin':
        return const Color(0xFF0077B5); // LinkedIn blue
      case 'youtube':
        return const Color(0xFFFF0000); // YouTube red
      case 'tiktok':
        return const Color(0xFF000000); // TikTok black
      case 'telegram':
        return const Color(0xFF0088CC); // Telegram blue
      case 'discord':
        return const Color(0xFF5865F2); // Discord blurple
      case 'github':
        return const Color(0xFF181717); // GitHub black
      case 'amazon':
        return const Color(0xFFFF9900); // Amazon orange
      case 'netflix':
        return const Color(0xFFE50914); // Netflix red
      case 'spotify':
        return const Color(0xFF1DB954); // Spotify green
      case 'paypal':
        return const Color(0xFF003087); // PayPal blue
      default:
        return const Color(0xFF0057D9); // Default app color
    }
  }
}


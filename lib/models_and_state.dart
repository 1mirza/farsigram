import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameState {
  static ValueNotifier<int> coins = ValueNotifier<int>(150);
  static ValueNotifier<String> userName = ValueNotifier<String>("پهلوان ششم");
  static ValueNotifier<int> activeLessonLimit = ValueNotifier<int>(17);
  static ValueNotifier<Set<int>> likedPosts = ValueNotifier<Set<int>>({});
  static ValueNotifier<Set<int>> savedPosts = ValueNotifier<Set<int>>({});

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    coins.value = prefs.getInt('coins') ?? 150;
    userName.value = prefs.getString('userName') ?? "پهلوان ششم";
    activeLessonLimit.value = prefs.getInt('activeLessonLimit') ?? 17;

    final liked = prefs.getStringList('liked_posts') ?? [];
    likedPosts.value = liked.map((e) => int.parse(e)).toSet();

    final saved = prefs.getStringList('saved_posts') ?? [];
    savedPosts.value = saved.map((e) => int.parse(e)).toSet();
  }

  static Future<void> addCoins(int amount) async {
    coins.value += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coins', coins.value);
  }

  static Future<void> setUserName(String name) async {
    userName.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  static Future<void> setActiveLessonLimit(int limit) async {
    activeLessonLimit.value = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('activeLessonLimit', limit);
  }

  static Future<void> toggleLike(int postId) async {
    final updated = Set<int>.from(likedPosts.value);
    if (updated.contains(postId)) {
      updated.remove(postId);
    } else {
      updated.add(postId);
      await addCoins(10);
    }
    likedPosts.value = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'liked_posts', updated.map((e) => e.toString()).toList());
  }

  static Future<void> toggleSave(int postId) async {
    final updated = Set<int>.from(savedPosts.value);
    if (updated.contains(postId)) {
      updated.remove(postId);
    } else {
      updated.add(postId);
    }
    savedPosts.value = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'saved_posts', updated.map((e) => e.toString()).toList());
  }
}

class LeitnerEngine {
  static Future<void> recordAnswer(String questionId, bool isCorrect) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> mistakes = prefs.getStringList('leitner_mistakes') ?? [];
    if (!isCorrect) {
      if (!mistakes.contains(questionId)) mistakes.add(questionId);
    } else {
      mistakes.remove(questionId);
    }
    await prefs.setStringList('leitner_mistakes', mistakes);
  }

  static Future<List<String>> getMistakes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('leitner_mistakes') ?? [];
  }
}

class AssetDataLoader {
  static Future<List<dynamic>> loadJsonList(String path) async {
    try {
      final String data = await rootBundle.loadString(path);
      final decoded = json.decode(data);
      return (decoded is List) ? decoded : [];
    } catch (e) {
      debugPrint("خطا در بارگذاری $path: $e");
      return [];
    }
  }
}

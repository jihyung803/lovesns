import 'package:flutter/material.dart';
import 'package:new_couple_app/screens/main_screen.dart';  // MainScreen import 추가
import 'package:new_couple_app/screens/auth/login_screen.dart';
import 'package:new_couple_app/screens/auth/register_screen.dart';
import 'package:new_couple_app/screens/auth/couple_connect_screen.dart';
import 'package:new_couple_app/screens/feed/feed_screen.dart';
import 'package:new_couple_app/screens/feed/post_detail_screen.dart';
import 'package:new_couple_app/screens/feed/create_post_screen.dart';
import 'package:new_couple_app/screens/feed/story_view_screen.dart';
import 'package:new_couple_app/screens/feed/create_story_screen.dart';
import 'package:new_couple_app/screens/calendar/calendar_screen.dart';
import 'package:new_couple_app/screens/calendar/event_editor_screen.dart';
import 'package:new_couple_app/screens/couple_room/room_screen.dart';
import 'package:new_couple_app/screens/couple_room/decoration_shop_screen.dart';
import 'package:new_couple_app/screens/profile/profile_screen.dart';
import 'package:new_couple_app/screens/profile/settings_screen.dart';

class AppRoutes {
  // Route names
  static const String login = '/login';
  static const String register = '/register';
  static const String coupleConnect = '/couple-connect';
  static const String feed = '/feed';
  static const String postDetail = '/post-detail';
  static const String createPost = '/create-post';
  static const String storyView = '/story-view';
  static const String createStory = '/create-story';
  static const String calendar = '/calendar';
  static const String eventEditor = '/event-editor';
  static const String coupleRoom = '/couple-room';
  static const String decorationShop = '/decoration-shop';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String main = '/main';  // '/main' 경로 추가


  // Route map
  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    coupleConnect: (context) => const CoupleConnectScreen(),
    feed: (context) => const FeedScreen(),
    postDetail: (context) => const PostDetailScreen(),
    createPost: (context) => const CreatePostScreen(),
    storyView: (context) => const StoryViewScreen(),
    createStory: (context) => const CreateStoryScreen(),
    calendar: (context) => const CalendarScreen(),
    eventEditor: (context) => const EventEditorScreen(),
    coupleRoom: (context) => const RoomScreen(),
    decorationShop: (context) => const DecorationShopScreen(),
    profile: (context) => const ProfileScreen(),
    settings: (context) => const SettingsScreen(),
    main: (context) => const MainScreen(),
  };
}
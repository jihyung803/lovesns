import 'package:flutter/material.dart';
import 'package:new_couple_app/screens/main_screen.dart';
import 'package:new_couple_app/screens/auth/login_screen.dart';
import 'package:new_couple_app/screens/auth/register_screen.dart';
import 'package:new_couple_app/screens/auth/couple_connect_screen.dart';
import 'package:new_couple_app/screens/auth/magical_login_screen.dart';
import 'package:new_couple_app/screens/auth/magical_couple_connect_screen.dart';
import 'package:new_couple_app/screens/feed/feed_screen.dart';
import 'package:new_couple_app/screens/feed/magical_feed_screen.dart';
import 'package:new_couple_app/screens/feed/post_detail_screen.dart';
import 'package:new_couple_app/screens/feed/create_post_screen.dart';
import 'package:new_couple_app/screens/feed/story_view_screen.dart';
import 'package:new_couple_app/screens/feed/create_story_screen.dart';
import 'package:new_couple_app/screens/calendar/calendar_screen.dart';
import 'package:new_couple_app/screens/calendar/event_editor_screen.dart';
import 'package:new_couple_app/screens/couple_room/room_screen.dart';
import 'package:new_couple_app/screens/couple_room/mystical_room_screen.dart';
import 'package:new_couple_app/screens/couple_room/decoration_shop_screen.dart';
import 'package:new_couple_app/screens/profile/profile_screen.dart';
import 'package:new_couple_app/screens/profile/settings_screen.dart';

class AppRoutes {
  // Route names
  static const String login = '/login';
  static const String magicalLogin = '/magical-login';
  static const String register = '/register';
  static const String coupleConnect = '/couple-connect';
  static const String magicalCoupleConnect = '/magical-couple-connect';
  static const String feed = '/feed';
  static const String magicalFeed = '/magical-feed';
  static const String postDetail = '/post-detail';
  static const String createPost = '/create-post';
  static const String storyView = '/story-view';
  static const String createStory = '/create-story';
  static const String calendar = '/calendar';
  static const String eventEditor = '/event-editor';
  static const String coupleRoom = '/couple-room';
  static const String mysticalRoom = '/mystical-room';
  static const String decorationShop = '/decoration-shop';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String main = '/main';

  // Route map
  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    magicalLogin: (context) => const MagicalLoginScreen(),
    register: (context) => const RegisterScreen(),
    coupleConnect: (context) => const CoupleConnectScreen(),
    magicalCoupleConnect: (context) => const MagicalCoupleConnectScreen(),
    feed: (context) => const FeedScreen(),
    magicalFeed: (context) => const MagicalFeedScreen(),
    postDetail: (context) => const PostDetailScreen(),
    createPost: (context) => const CreatePostScreen(),
    storyView: (context) => const StoryViewScreen(),
    createStory: (context) => const CreateStoryScreen(),
    calendar: (context) => const CalendarScreen(),
    eventEditor: (context) => const EventEditorScreen(),
    coupleRoom: (context) => const RoomScreen(),
    mysticalRoom: (context) => const MysticalRoomScreen(),
    decorationShop: (context) => const DecorationShopScreen(),
    profile: (context) => const ProfileScreen(),
    settings: (context) => const SettingsScreen(),
    main: (context) => const MainScreen(),
  };
}
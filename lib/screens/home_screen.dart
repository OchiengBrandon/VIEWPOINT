import 'package:flutter/material.dart';
import 'package:short_video_app/screens/login_screen.dart';
import 'package:short_video_app/screens/search_screen.dart';
import 'package:short_video_app/utils/styles/app_styles.dart';
import '../services/auth_service.dart';
import 'video_feed_screen.dart';
import 'upload_video_screen.dart';
import 'profile_screen.dart';
import 'category_screen.dart'; // New screen for trending videos

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const VideoFeedScreen(),
    const CategoryScreen(), // Trending videos screen
    const SearchScreen(), // Placeholder for search screen
    const ProfileScreen(),
  ];

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return const LoginScreen();
    })); // Go to login screen after logout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: _currentIndex == 0
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20))),
                  child: const Image(
                    fit: BoxFit.fill,
                    image: AssetImage("assets/images/App icon.png"),
                  ),
                ),
              )
            : null,
        title: Text(
          _currentIndex == 0
              ? "Feed"
              : _currentIndex == 1
                  ? "Categories"
                  : _currentIndex == 2
                      ? "Search"
                      : "Profile",
          style: AppStyles.appBarTitle,
        ),
        actions: _currentIndex == 3
            ? [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
              ]
            : null,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Category',
          ),
          BottomNavigationBarItem(
            icon: SizedBox.shrink(), // Empty space for the FAB
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search), // Search icon
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Profile icon
            label: 'Profile',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) return; // Do nothing for the empty center item
          setState(() {
            _currentIndex = index > 2
                ? index - 1
                : index; // Adjust index for the empty item
          });
        },
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: ClipOval(
        // Make the button circular
        child: Material(
          color: AppStyles.primaryColor, // Button color
          child: InkWell(
            splashColor: Colors.white, // Splash color
            child: const SizedBox(
              width: 56, // Width of the button
              height: 56, // Height of the button
              child: Icon(Icons.add, color: Colors.white), // Icon color
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UploadVideoScreen()),
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../features/player/presentation/widgets/mini_player.dart';
import '../../../../features/search/presentation/pages/search_page.dart';
import '../../../library/presentation/pages/library_page.dart';
import 'home_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [HomeTab(), SearchPage(), LibraryPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Main Page Content (with bottom padding for MiniPlayer)
          IndexedStack(index: _selectedIndex, children: _pages),

          // Mini Player
          const Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music),
            label: "Library",
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final VoidCallback onBluetoothTap;
  final VoidCallback onHomeTap;
  final VoidCallback onSettingsTap;
  final bool isDarkMode;
  
  const CustomBottomNavigationBar({
    super.key,
    required this.onBluetoothTap,
    required this.onHomeTap,
    required this.onSettingsTap,
    this.isDarkMode = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.bottomBarHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppConstants.primaryGreen,
            AppConstants.darkGreen,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavButton(
            icon: Icons.bluetooth,
            onTap: onBluetoothTap,
          ),
          _buildNavButton(
            icon: Icons.home,
            onTap: onHomeTap,
          ),
          _buildNavButton(
            icon: Icons.settings,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Icon(
          icon,
          color: Colors.black,
          size: 32,
        ),
      ),
    );
  }
}
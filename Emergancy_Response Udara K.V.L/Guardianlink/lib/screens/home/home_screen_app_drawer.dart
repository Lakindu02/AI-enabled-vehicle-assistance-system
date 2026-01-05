import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:guardian_link/screens/management/user_management_screen.dart';
import 'package:guardian_link/screens/user/guardian_registration_screen.dart';
import 'package:guardian_link/screens/user/vehicle_registration_screen.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';
import '../management/hospital_management_screen.dart';
import '../management/police_management_screen.dart';

class HomeScreenAppDrawer extends StatelessWidget {
  final UserModel userModel;
  final VoidCallback onLogout;

  const HomeScreenAppDrawer({
    super.key,
    required this.userModel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  child: userModel.photoBase64 != null
                      ? Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.memory(
                            base64Decode(userModel.photoBase64!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 32,
                          color: AppColors.white,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  userModel.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userModel.email,
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (userModel.userType == UserType.admin)
            _DrawerItem(
              icon: Icons.local_hospital,
              title: 'Hospital Management',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HospitalManagementScreen(userModel: userModel),
                  ),
                );
              },
            ),
          if (userModel.userType == UserType.admin)
            _DrawerItem(
              icon: Icons.local_police,
              title: 'Police Management',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PoliceManagementScreen(userModel: userModel),
                  ),
                );
              },
            ),
          if (userModel.userType == UserType.admin)
            _DrawerItem(
              icon: Icons.local_police,
              title: 'User Management',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UserManagementScreen(userModel: userModel),
                  ),
                );
              },
            ),
          if (userModel.userType == UserType.user)
            _DrawerItem(
              icon: Icons.people,
              title: 'Link with Guardian',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GuardianRegistrationScreen(userModel: userModel),
                  ),
                );
              },
            ),
          if (userModel.userType == UserType.user)
            _DrawerItem(
              icon: Icons.car_rental_outlined,
              title: 'Link with Vehicle',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VehicleRegistrationScreen(userModel: userModel),
                  ),
                );
              },
            ),
          _DrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: onLogout,
            isDestructive: true,
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}

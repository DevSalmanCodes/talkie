import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:talkie/constants/color_constants.dart';
import 'package:talkie/utils/routes/route_names.dart';
import 'package:talkie/view_models.dart/auth_view_model.dart';
import 'package:talkie/view_models.dart/user_view_model.dart';
import 'package:talkie/widgets/loader.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Platform.isIOS
            ? CupertinoAlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop(false),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    child: const Text('Logout'),
                    onPressed: () => Navigator.of(ctx).pop(true),
                  ),
                ],
              )
            : AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
      },
    );

    if (shouldLogout == true) {
      if (context.mounted) {
        ref.read(authViewModelProvider.notifier).signOut(context);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(getCurrentUserDataProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: userAsync.when(
        loading: () => const Loader(),
        error: (e, _) => Center(
          child: Text(
            'Error: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (user) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  RouteNames.photoView,
                  arguments: user.profilePic,
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: user.profilePic?.isNotEmpty == true
                      ? CachedNetworkImageProvider(user.profilePic!)
                      : const AssetImage('assets/profile.png'),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: const Color(0xFF1F2937),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        LucideIcons.user,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Username',
                        style: TextStyle(color: Colors.grey),
                      ),
                      subtitle: Text(
                        user.username,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        LucideIcons.mail,
                        color: Colors.white,
                      ),
                      title: const Text(
                        'Email',
                        style: TextStyle(color: Colors.grey),
                      ),
                      subtitle: Text(
                        user.email,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, 'editProfileView');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(LucideIcons.edit, color: Colors.black),
                  label: const Text(
                    'Edit Profile',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF1F2937),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(
                    LucideIcons.logOut,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _showLogoutDialog(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

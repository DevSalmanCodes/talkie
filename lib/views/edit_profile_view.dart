import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:talkie/constants/color_constants.dart';
import 'package:talkie/constants/size_constants.dart';
import 'package:talkie/models/user_model.dart';
import 'package:talkie/view_models.dart/user_view_model.dart';
import 'package:talkie/widgets/custom_text_field.dart';
import 'package:talkie/widgets/loader.dart';

class EditProfileView extends ConsumerStatefulWidget {
  const EditProfileView({super.key});

  @override
  ConsumerState<EditProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<EditProfileView> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _updateProfile(UserModel user) async {
    await ref
        .read(userViewModelProvider.notifier)
        .updateUserProfile(
          _usernameController.text.trim(),
          _pickedImage?.path ?? '',
          context,
          _passwordController.text.isNotEmpty
              ? _passwordController.text.trim()
              : null,
        );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userFuture = ref.watch(getCurrentUserDataProvider);
    final isLoading = ref.watch(userViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: userFuture.when(
        data: (user) {
          _usernameController.text = user.username;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _pickedImage != null
                            ? FileImage(_pickedImage!)
                            : (user.profilePic?.isNotEmpty == true
                                      ? CachedNetworkImageProvider(
                                          user.profilePic!,
                                        )
                                      : const AssetImage('assets/profile.png'))
                                  as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: ColorConstants.whiteColor,
                            child: Icon(
                              LucideIcons.edit,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: const Color(0xFF1F2937),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Column(
                        children: [
                          CustomTextField(
                            labelText: 'Username',
                            controller: _usernameController,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            labelText: 'New Password',
                            controller: _passwordController,
                          ),
                          const SizedBox(height: 24),
                          isLoading
                              ? const Loader(color: Colors.white)
                              : SizedBox(
                                  width: SizeConstants.width(context) * 0.6,
                                  child: ElevatedButton(
                                    onPressed: () => _updateProfile(user),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          ColorConstants.whiteColor,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Update',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Loader(),
        error: (e, _) => Center(
          child: Text(
            'Error: ${e.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

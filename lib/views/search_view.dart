import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkie/constants/text_style_constants.dart';
import 'package:talkie/models/user_model.dart';
import 'package:talkie/providers/general_providers.dart';
import 'package:talkie/utils/routes/route_names.dart';
import 'package:talkie/view_models.dart/chat_view_model.dart';
import 'package:talkie/view_models.dart/user_view_model.dart';
import 'package:talkie/widgets/custom_text_field.dart';
import 'package:talkie/widgets/loader.dart';

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  late TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  void _onChanged(String newQuery) {
    setState(() {
      _query = newQuery.trim();
    });
  }

  void _onGetOrCreateChat(
    String userUid,
    String currentUserUid,
    UserModel userModel,
    context,
  ) async {
    if (userUid != currentUserUid) {
      final chatId = await ref
          .read(chatViewModelProvider.notifier)
          .getOrCreateChat(userUid, currentUserUid, context);

      if (context.mounted) {
        Navigator.pushNamed(
          context,
          RouteNames.chatView,
          arguments: {'userModel': userModel, 'chatId': chatId},
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchUsersAsyncValue = ref.watch(getSearchUsersProvider(_query));
    final currentUserUid = ref.watch(firebaseAuthProvider).currentUser!.uid;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: CustomTextField(
                onChanged: _onChanged,
                labelText: 'Search',
                controller: _controller,
              ),
            ),

            Expanded(
              child: searchUsersAsyncValue.when(
                loading: () => const Loader(),
                error: (e, st) => Center(
                  child: Text(
                    e.toString(),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                data: (data) {
                  if (data.isEmpty && _query.isNotEmpty) {
                    return const Center(
                      child: Text(
                        "No users found.",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final user = data[index];
                      return InkWell(
                        onTap: () => _onGetOrCreateChat(
                          user.uid,
                          currentUserUid,
                          user,
                          context,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: Colors.grey[900],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage:
                                      user.profilePic?.isNotEmpty == true
                                      ? NetworkImage(user.profilePic!)
                                      : AssetImage('assets/profile.png'),
                                ),
                                if (user.isOnline)
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              user.username,
                              style: TextStyleConstants.semiBoldTextStyle,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

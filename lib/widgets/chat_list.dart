import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkie/models/user_model.dart';
import 'package:talkie/providers/general_providers.dart';
import 'package:talkie/utils/routes/route_names.dart';
import 'package:talkie/view_models.dart/chat_view_model.dart';
import 'package:talkie/widgets/loader.dart';

import '../../widgets/chat_list_tile.dart';
import '../view_models.dart/user_view_model.dart';

class ChatList extends ConsumerWidget {
  const ChatList({super.key});

  void _onNavigateToChatView(
    String chatId,
    UserModel userModel,
    BuildContext context,
  ) async {
    if (context.mounted) {
      Navigator.pushNamed(
        context,
        RouteNames.chatView,
        arguments: {'chatId': chatId, 'userModel': userModel},
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserUid = ref.watch(firebaseAuthProvider).currentUser!.uid;
    final chatsAsyncValue = ref.watch(getAllChatsProvider(currentUserUid));
    return chatsAsyncValue.when(
      error: (error, stackTrace) => Center(
        child: Text(
          "Error: ${error.toString()}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
        ),
      ),
      loading: () => const Loader(),
      data: (chatList) {
        if (chatList.isEmpty) {
          return const Center(
            child: Text(
              "No chats found.",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
          );
        }

        chatList.sort(
                (a, b) => b.lastMessageTimestamp!.toDate().compareTo(
            a.lastMessageTimestamp!.toDate(),
          ),
        );

        return SizedBox(
          height: MediaQuery.sizeOf(context).height,
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: chatList.length,
            itemBuilder: (context, index) {
              final chat = chatList[index];
              final otherUser = chat.participantIds.firstWhere(
                (id) => id != currentUserUid,
                orElse: () => 'Something went wrong',
              );

              return ref
                  .watch(userDetailsProvider(otherUser))
                  .when(
                    data: (userData) => ChatListTile(
                      title: userData.username,
                      subtitleText: Text(
                        chat.lastMessage,
                        style: const TextStyle(color: Colors.white),
                      ),
                      lastMessageTimestamp: chat.lastMessageTimestamp!,
                      backgroundImage: userData.profilePic?.isNotEmpty == true
                          ? CachedNetworkImageProvider(userData.profilePic!)
                          : AssetImage('assets/profile.png'),
                      isOnline: userData.isOnline,
                      onTap: () =>
                          _onNavigateToChatView(chat.id, userData, context),
                    ),
                    error: (e, st) =>
                        Center(child: Text("Error: ${e.toString()}")),
                    loading: () => const Loader(),
                  );
            },
          ),
        );
      },
    );
  }
}

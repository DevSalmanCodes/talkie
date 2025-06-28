import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:talkie/utils/routes/route_names.dart';
import 'package:talkie/view_models.dart/user_view_model.dart';
import 'package:talkie/widgets/chat_list.dart';
import 'package:talkie/widgets/custom_app_bar.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _changeUserStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      _changeUserStatus(true);
    }
  }

  void _changeUserStatus(bool status) {
    ref.read(userViewModelProvider.notifier).changeUserStatus(status);
  }

  void _onNavigateToSearch() {
    Navigator.pushNamed(context, RouteNames.searchView);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Chats",
        actionItemsList: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              onPressed: _onNavigateToSearch,
              icon: const Icon(LucideIcons.search, size: 30.0),
            ),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: ChatList(),
      ),
    );
  }
}

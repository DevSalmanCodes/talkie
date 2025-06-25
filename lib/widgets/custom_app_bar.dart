import 'package:flutter/material.dart';
import 'package:talkie/constants/text_style_constants.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget? leading;
  final String title;
  final double? fontSize;
  final List<Widget>? actionItemsList;
  final String? lastSeen;

  const CustomAppBar({
    super.key,
    this.leading,
    required this.title,
    this.fontSize,
    this.actionItemsList,
    this.lastSeen,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}

class _CustomAppBarState extends State<CustomAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      elevation: 0,
      leading: widget.leading != null
          ? CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              child: widget.leading,
            )
          : null,
      titleSpacing: 0,
      title: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyleConstants.semiBoldTextStyle.copyWith(
                    fontSize: widget.fontSize ?? 25.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (widget.lastSeen != null)
                  Text(
                    widget.lastSeen!,
                    style: TextStyleConstants.regularTextStyle.copyWith(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: widget.actionItemsList ?? const [],
    );
  }
}

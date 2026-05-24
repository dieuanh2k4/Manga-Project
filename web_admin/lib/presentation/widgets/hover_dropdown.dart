import 'package:flutter/material.dart';

class ProfileDropdown extends StatefulWidget {
  final Widget child; // The trigger widget (e.g. Pill-shaped Profile Button)
  final Widget dropdownContent; // The Google-style account card dropdown content
  final double yOffset; // Vertical spacing between trigger and card
  final double dropdownWidth; // Configurable width
  final Alignment targetAnchor;
  final Alignment followerAnchor;

  const ProfileDropdown({
    super.key,
    required this.child,
    required this.dropdownContent,
    this.yOffset = 8.0,
    this.dropdownWidth = 320.0,
    this.targetAnchor = Alignment.bottomRight,
    this.followerAnchor = Alignment.topRight,
  });

  @override
  State<ProfileDropdown> createState() => _ProfileDropdownState();
}

class _ProfileDropdownState extends State<ProfileDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Full-screen translucent detector to catch outside taps and close dropdown
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              width: widget.dropdownWidth, // Dynamic width
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: widget.targetAnchor,
                followerAnchor: widget.followerAnchor,
                offset: Offset(0, widget.yOffset),
                child: Material(
                  color: Colors.transparent,
                  child: widget.dropdownContent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Safely remove overlay on widget disposal
    final entry = _overlayEntry;
    if (entry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          entry.remove();
        } catch (_) {}
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: widget.child,
        ),
      ),
    );
  }
}

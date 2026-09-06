import 'package:flutter/material.dart';

class CustomAppbar extends StatefulWidget {
  final String text;

  const CustomAppbar({
    super.key,
    required this.text,
  });

  @override
  State<CustomAppbar> createState() => _AppbarState();
}

class _AppbarState extends State<CustomAppbar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            // Light: white
            // Dark: theme surface
            color: theme.colorScheme.surface,

            borderRadius: BorderRadius.circular(100),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.20 : 0.06,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),

            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,

              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => Navigator.pop(context),
              ),

              title: Text(
                widget.text,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),

              centerTitle: true,
            ),
          ),
        ),
      ),
    );
  }
}
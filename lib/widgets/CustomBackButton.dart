import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final Color? iconColor;
  final double? size;
  final VoidCallback? onPressed;

  const CustomBackButton({
    super.key,
    this.iconColor = Colors.black,
    this.size = 24,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: onPressed ?? () => Navigator.maybePop(context),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(Icons.arrow_back, color: iconColor, size: size),
        ),
      ),
    );
  }
}

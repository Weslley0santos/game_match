import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onFavorite;

  const ActionButtons({
    super.key,
    required this.onLike,
    required this.onDislike,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButton(icon: Icons.close, color: Colors.red, onTap: onDislike),

          _buildButton(
            icon: Icons.star,
            color: Colors.amber,
            onTap: onFavorite,
            size: 60,
          ),

          _buildButton(
            icon: Icons.favorite,
            color: Colors.green,
            onTap: onLike,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 55,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}

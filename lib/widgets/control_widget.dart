import 'package:flutter/material.dart';

class ControlWidget extends StatelessWidget {
  final String title;
  final bool isOn;
  final IconData icon;
  final Function(bool) onToggle;

  const ControlWidget({
    Key? key,
    required this.title,
    required this.isOn,
    required this.icon,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isOn
                ? Colors.green.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isOn ? Colors.green : Colors.grey,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Switch(
          value: isOn,
          onChanged: onToggle,
          activeColor: Colors.green,
        ),
      ],
    );
  }
}

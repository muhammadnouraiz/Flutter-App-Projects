import 'package:flutter/material.dart';
import '../models/skill_model.dart';

class SkillCard extends StatelessWidget {
  final SkillModel skill;
  final VoidCallback onTap;
  const SkillCard({super.key, required this.skill, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(skill.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(skill.category, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: skill.progress / 100, color: const Color(0xFFFF6B4A), backgroundColor: Colors.grey[200]),
            const SizedBox(height: 4),
            Text('${skill.progress}%', style: const TextStyle(fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

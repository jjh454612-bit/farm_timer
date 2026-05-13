import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class MissionPopup extends StatelessWidget {
  const MissionPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final missions = provider.dailyMissions;
    final studied  = provider.todayStudyMinutes;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 타이틀
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "📋 일일 미션",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            Text(
              "오늘 공부: $studied분",
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            // 미션 목록
            ...List.generate(missions.length, (i) {
              final target    = missions[i];
              final reward    = provider.missionReward(target);
              final complete  = provider.isMissionComplete(i);
              final claimed   = provider.claimedMissions.contains(i);
              final progress  = (studied / target).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: claimed
                        ? Colors.grey[100]
                        : complete
                            ? const Color(0xFFD6E8C0)
                            : const Color(0xFFFFF0C8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: claimed
                          ? Colors.grey[300]!
                          : complete
                              ? const Color(0xFF4A9E4A)
                              : const Color(0xFF8B6914),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "오늘 $target분 공부하기",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: claimed
                                  ? Colors.grey[400]
                                  : const Color(0xFF3D5C28),
                              decoration: claimed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            "+$reward원",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: claimed
                                  ? Colors.grey[400]
                                  : const Color(0xFF8B6914),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 진행 바
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          color: claimed
                              ? Colors.grey[400]
                              : complete
                                  ? const Color(0xFF4A9E4A)
                                  : const Color(0xFF4A7FBD),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${studied.clamp(0, target)}분 / $target분",
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                          if (claimed)
                            Text("수령 완료",
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[400]))
                          else if (complete)
                            GestureDetector(
                              onTap: () =>
                                  context.read<GameProvider>().claimMission(i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A9E4A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "보상 받기",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
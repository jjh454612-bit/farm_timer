import 'package:flutter/material.dart';

class AttendancePopup extends StatelessWidget {
  final int attendanceDays;

  const AttendancePopup({super.key, required this.attendanceDays});

  Widget _buildDayCard(int day, bool isUnlocked, bool isBig) {
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.amber[100] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? Colors.amber[400]! : Colors.grey[300]!,
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isUnlocked ? "🎁" : "🔒",
            style: TextStyle(fontSize: isBig ? 32 : 20),
          ),
          const SizedBox(height: 4),
          Text(
            "Day $day",
            style: TextStyle(
              fontSize: isBig ? 16 : 12,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.amber[700] : Colors.grey[400],
            ),
          ),
          if (isBig) ...[
            const SizedBox(height: 4),
            Text(
              "특별 보상",
              style: TextStyle(fontSize: 11, color: Colors.amber[600]),
            ),
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 타이틀 + X버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "🎁 출석 보상",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "매일 접속하면 보상을 받아요!",
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽 6칸
                Expanded(
                  flex: 2,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.1,
                    children: List.generate(6, (index) {
                      final day = index + 1;
                      final isUnlocked = attendanceDays >= day;
                      return _buildDayCard(day, isUnlocked, false);
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                // 오른쪽 day7 큰 칸
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: AspectRatio(
                      aspectRatio: 0.55,
                      child: _buildDayCard(7, attendanceDays >= 7, true),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "현재 $attendanceDays일 출석 중!",
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
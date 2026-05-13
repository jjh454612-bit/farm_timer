import 'package:flutter/material.dart';

class AttendancePopup extends StatefulWidget {
  final int attendanceDays;
  final bool hasClaimedToday;
  final void Function(int reward) onClaim;

  const AttendancePopup({
    super.key,
    required this.attendanceDays,
    required this.hasClaimedToday,
    required this.onClaim,
  });

  @override
  State<AttendancePopup> createState() => _AttendancePopupState();
}

class _AttendancePopupState extends State<AttendancePopup> {
  late bool _claimed;

  @override
  void initState() {
    super.initState();
    _claimed = widget.hasClaimedToday;
  }

  int _rewardFor(int day) {
    if (day == 7) return 2000;
    return day * 100;
  }

  void _handleTap(int day) {
    if (day != widget.attendanceDays) return;
    if (_claimed) return;

    final reward = _rewardFor(day);
    widget.onClaim(reward);
    setState(() => _claimed = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide.none,
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF3D5C28),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🎁", style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  "+$reward원 획득!",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFF0A0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final nav = Navigator.of(context, rootNavigator: true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (context.mounted) nav.pop();
    });
  }

  Widget _buildDayCard(int day, bool isBig) {
    final isUnlocked = widget.attendanceDays >= day;
    final isToday    = widget.attendanceDays == day;
    final canClaim   = isToday && !_claimed;

    Color bgColor;
    Color borderColor;
    if (isToday && _claimed) {
      bgColor = Colors.grey[200]!;
      borderColor = Colors.grey[400]!;
    } else if (canClaim) {
      bgColor = Colors.amber[100]!;
      borderColor = Colors.amber[600]!;
    } else if (isUnlocked) {
      bgColor = Colors.amber[50]!;
      borderColor = Colors.amber[300]!;
    } else {
      bgColor = Colors.grey[100]!;
      borderColor = Colors.grey[300]!;
    }

    return GestureDetector(
      onTap: canClaim ? () => _handleTap(day) : null,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: canClaim ? 2 : 1),
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
          ],
        ),
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
            const SizedBox(height: 4),
            Text(
              "매일 접속하면 보상을 받아요!",
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.1,
                    children: List.generate(6, (i) => _buildDayCard(i + 1, false)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: AspectRatio(
                      aspectRatio: 0.55,
                      child: _buildDayCard(7, true),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "현재 ${widget.attendanceDays}일 출석 중!",
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
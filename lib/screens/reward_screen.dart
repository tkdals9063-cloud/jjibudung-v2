import 'package:flutter/material.dart';

import '../services/point_manager.dart';

class RewardItem {
  final String brand;
  final String name;
  final int requiredPoints;
  final Color color;
  final IconData icon;

  const RewardItem({
    required this.brand,
    required this.name,
    required this.requiredPoints,
    required this.color,
    required this.icon,
  });
}

final _rewards = [
  const RewardItem(
    brand: '스타벅스',
    name: '아메리카노 Tall',
    requiredPoints: 500,
    color: Color(0xFF00704A),
    icon: Icons.local_cafe_rounded, //icon은 사진 따와서 연동하면 됨, app 버전 참고
  ),
  const RewardItem(
    brand: 'CU',
    name: '상품권 1,000원',
    requiredPoints: 300,
    color: Color(0xFF6C2E8B),
    icon: Icons.store_rounded,
  ),
  const RewardItem(
    brand: 'GS25',
    name: '상품권 1,000원',
    requiredPoints: 300,
    color: Color(0xFF003D96),
    icon: Icons.store_rounded,
  ),
  const RewardItem(
    brand: '배달의민족',
    name: '할인쿠폰 5,000원',
    requiredPoints: 1000,
    color: Color(0xFF2AC1BC),
    icon: Icons.delivery_dining_rounded,
  ),
  const RewardItem(
    brand: '올리브영',
    name: '상품권 5,000원',
    requiredPoints: 1000,
    color: Color(0xFF00A650),
    icon: Icons.spa_rounded,
  ),
  const RewardItem(
    brand: '넷플릭스',
    name: '1개월 이용권',
    requiredPoints: 5000,
    color: Color(0xFFE50914),
    icon: Icons.play_circle_fill_rounded,
  ),
];

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  final PointManager _pointManager = PointManager();

  int _currentPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final points = await _pointManager.getPoints();
    if (!mounted) return;
    setState(() => _currentPoints = points);
  }

  Future<void> _onExchange(RewardItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('교환 확인'),
        content: Text(
          '${item.brand} ${item.name}\n${item.requiredPoints}pt를 사용해 교환하시겠어요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF725AC1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('교환하기'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _pointManager.usePoints(item.requiredPoints);
    await _loadPoints();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              '신청 완료!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${item.brand} ${item.name}\n교환 신청이 완료됐어요.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF725AC1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FC),
      body: CustomScrollView(
        slivers: [
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildRewardCard(_rewards[i]),
                childCount: _rewards.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF725AC1), Color(0xFF9B72CF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상점',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star,
                      color: Colors.amber, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '보유 포인트',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '$_currentPoints pt',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(RewardItem item) {
    final canExchange = _currentPoints >= item.requiredPoints;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(height: 4),
                Text(
                  item.brand,
                  style: TextStyle(
                    fontSize: 13,
                    color: item.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  '${item.requiredPoints} pt',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: canExchange ? const Color(0xFF725AC1) : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canExchange ? () => _onExchange(item) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canExchange
                          ? const Color(0xFF725AC1)
                          : Colors.grey[200],
                      foregroundColor: canExchange ? Colors.white : Colors.grey,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      canExchange ? '교환하기' : '포인트 부족',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

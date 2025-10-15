import 'package:flutter/material.dart';

/// QuickDetailPopup - 텍스트 입력 시 자동으로 나타나는 옵션 선택 팝업
///
/// 피그마: Frame 705 (212×172px)
/// 위치: Quick_Add_ControlBox 우측 하단
///
/// 사용 예시:
/// ```dart
/// QuickDetailPopup(
///   onScheduleSelected: () => print('일정 선택'),
///   onTaskSelected: () => print('할일 선택'),
///   onHabitSelected: () => print('습관 선택'),
/// )
/// ```
class QuickDetailPopup extends StatelessWidget {
  final VoidCallback onScheduleSelected;
  final VoidCallback onTaskSelected;
  final VoidCallback onHabitSelected;

  const QuickDetailPopup({
    Key? key,
    required this.onScheduleSelected,
    required this.onTaskSelected,
    required this.onHabitSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ 피그마: Frame 705 크기
      width: 212,
      height: 172,
      decoration: BoxDecoration(
        // ✅ 피그마: #ffffff 배경
        color: const Color(0xFFFFFFFF),
        // ✅ 피그마: #111111 opacity 10% 테두리
        border: Border.all(
          color: const Color(0xFF111111).withOpacity(0.1),
          width: 1,
        ),
        // ✅ 피그마: cornerRadius 24px
        borderRadius: BorderRadius.circular(24),
        // ✅ 그림자 추가 (iOS 네이티브 스타일)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ 옵션 1: 일정 (今日のスケジュール)
          _buildOption(text: '일정', onTap: onScheduleSelected, isFirst: true),
          // ✅ 구분선
          _buildDivider(),
          // ✅ 옵션 2: 할일 (タスク)
          _buildOption(text: '할일', onTap: onTaskSelected),
          // ✅ 구분선
          _buildDivider(),
          // ✅ 옵션 3: 습관 (ルーティン)
          _buildOption(text: '습관', onTap: onHabitSelected, isLast: true),
        ],
      ),
    );
  }

  /// ✅ 옵션 아이템 빌더
  /// 피그마: Frame 650/651/652 (190×48px)
  Widget _buildOption({
    required String text,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      // ✅ 첫 번째/마지막 아이템의 borderRadius 처리
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(24) : Radius.zero,
        bottom: isLast ? const Radius.circular(24) : Radius.zero,
      ),
      child: Container(
        // ✅ 피그마: 190×48px (내부 여백 포함)
        width: 190,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // ✅ 아이콘 공간 (피그마: 24×24px, 현재는 visible: false)
            const SizedBox(width: 24),
            const SizedBox(width: 12), // 아이콘과 텍스트 간격
            // ✅ 텍스트
            Text(
              text,
              style: const TextStyle(
                // ✅ 피그마: LINE Seed JP App_TTF Bold 14px
                fontFamily: 'LINE Seed JP App_TTF',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                // ✅ 피그마: #262626
                color: Color(0xFF262626),
                // ✅ 피그마: letterSpacing -0.07
                letterSpacing: -0.07,
                // ✅ 피그마: lineHeight 19.6px
                height: 19.6 / 14, // lineHeight / fontSize
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ 구분선
  Widget _buildDivider() {
    return Container(
      width: 190,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 11), // 중앙 정렬
      color: const Color(0xFF111111).withOpacity(0.05), // 미세한 구분선
    );
  }
}

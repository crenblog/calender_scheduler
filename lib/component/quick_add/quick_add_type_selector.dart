import 'package:flutter/material.dart';
import '../../const/quick_add_config.dart';
import '../../const/color.dart';

/// Quick_Add 하단 타입 선택 위젯 (일정/할일/습관)
/// 이거를 설정하고 → 3개의 아이콘 버튼을 가로로 배치해서
/// 이거를 해서 → 사용자가 일정/할일/습관 중 하나를 선택하고
/// 이거는 이래서 → 선택된 타입에 따라 Quick_Add_ControlBox가 확장된다
/// 이거라면 → 타입별 입력 UI가 동적으로 표시된다
class QuickAddTypeSelector extends StatelessWidget {
  final QuickAddType? selectedType;
  final Function(QuickAddType) onTypeSelected;

  const QuickAddTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 이거를 설정하고 → Frame 704 (피그마: 212×52px, radius 34px)
    // 이거를 해서 → 3개의 아이콘을 수평으로 배치한다
    // 이거는 이래서 → 사용자가 쉽게 타입을 선택할 수 있다
    return Container(
      width: 212, // 피그마: Frame 704 width
      height: 52, // 피그마: Frame 704 height
      decoration: BoxDecoration(
        color: QuickAddConfig.controlBoxBackground, // 피그마: #ffffff
        border: Border.all(
          color: QuickAddConfig.modalBorder, // 피그마: #111111 opacity 10%
          width: 1,
        ),
        borderRadius: BorderRadius.circular(
          QuickAddConfig.typeSelectorRadius,
        ), // 피그마: 34px
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1️⃣ 일정 아이콘 (Frame 654)
          _TypeIconButton(
            icon: Icons.calendar_today_outlined,
            isSelected: selectedType == QuickAddType.schedule,
            onTap: () {
              print('📅 [타입 선택] 일정 선택됨');
              onTypeSelected(QuickAddType.schedule);
            },
          ),

          // 2️⃣ 할일 아이콘 (Frame 655)
          _TypeIconButton(
            icon: Icons.check_box_outline_blank,
            isSelected: selectedType == QuickAddType.task,
            onTap: () {
              print('✅ [타입 선택] 할일 선택됨');
              onTypeSelected(QuickAddType.task);
            },
          ),

          // 3️⃣ 습관 아이콘 (Frame 656)
          _TypeIconButton(
            icon: Icons.repeat,
            isSelected: selectedType == QuickAddType.habit,
            onTap: () {
              print('🔄 [타입 선택] 습관 선택됨');
              onTypeSelected(QuickAddType.habit);
            },
          ),
        ],
      ),
    );
  }
}

/// 개별 타입 아이콘 버튼 위젯
/// 이거를 설정하고 → 52×48px 크기의 아이콘 버튼을 만들어서
/// 이거를 해서 → 선택 상태에 따라 시각적 피드백을 제공한다
class _TypeIconButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeIconButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 이거를 설정하고 → 52×48px 터치 영역을 설정해서
    // 이거를 해서 → 아이콘을 중앙에 배치한다
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52, // 피그마: Frame 654/655/656 width
        height: 48, // 피그마: Frame 654/655/656 height
        decoration: BoxDecoration(
          // 선택된 경우 배경색 표시 (선택 사항)
          color: isSelected ? gray100.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 24, // 피그마: icon 크기 24×24px
          color: isSelected
              ? QuickAddConfig
                    .titleText // 선택: #111111
              : QuickAddConfig.subText, // 비선택: #505050
        ),
      ),
    );
  }
}

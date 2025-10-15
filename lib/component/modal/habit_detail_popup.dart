import 'package:flutter/material.dart';
import '../../const/quick_add_config.dart';

/// 습관 바텀시트 위젯 (DetailPopup)
/// 이거를 설정하고 → 피그마 DetailPopup 디자인을 재현해서
/// 이거를 해서 → 키보드 위에 고정된 높이로 표시되고
/// 이거는 이래서 → Safe Area를 무시하고 화면 하단 끝에 배치된다
/// 이거라면 → 습관 입력 시 자연스러운 UX를 제공한다
class HabitDetailPopup extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Map<String, dynamic> data)? onSave;

  const HabitDetailPopup({Key? key, required this.selectedDate, this.onSave})
    : super(key: key);

  @override
  State<HabitDetailPopup> createState() => _HabitDetailPopupState();
}

class _HabitDetailPopupState extends State<HabitDetailPopup> {
  final TextEditingController _textController = TextEditingController();
  String _selectedColorId = 'gray';
  DateTime? _habitTime;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: QuickAddConfig.habitPopupHeight, // 피그마: 553px
      decoration: BoxDecoration(
        color: QuickAddConfig.modalBackground, // 피그마: #fcfcfc
        border: Border.all(
          color: QuickAddConfig.modalBorder, // #111111 opacity 10%
          width: 1,
        ),
        // ✅ 상단만 radius 적용 (바텀시트 스타일)
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          // ✅ TopNavi (피그마: TopNavi)
          _buildTopNavi(),

          const SizedBox(height: 12),

          // ✅ 텍스트 입력 영역 (피그마: DetailView_Title)
          _buildTextInput(),

          const SizedBox(height: 24),

          // ✅ DetailOption 버튼 영역 (피그마: DetailOption/Box)
          _buildDetailOptions(),

          const Spacer(),

          // ✅ 하단: 삭제 버튼 (좌측) (피그마: Frame 774)
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// TopNavi 위젯 (피그마: TopNavi)
  Widget _buildTopNavi() {
    return Container(
      height: QuickAddConfig.topNaviModalHeight, // 피그마: 60px
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 좌측: 제목 "ルーティン"
          Text(
            QuickAddConfig.modalTitleHabit, // 피그마: "ルーティン"
            style: const TextStyle(
              fontFamily: 'LINE Seed JP App_TTF',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF505050), // 피그마: #505050
              letterSpacing: -0.08,
              height: 1.4,
            ),
          ),

          // 우측: 완료 버튼 (피그마: Modal Control Buttons)
          GestureDetector(
            onTap: _handleSave,
            child: Container(
              width: 74,
              height: 42,
              decoration: BoxDecoration(
                color: QuickAddConfig.buttonActive, // #111111
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                QuickAddConfig.buttonComplete, // "完了"
                style: const TextStyle(
                  fontFamily: 'LINE Seed JP App_TTF',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFAFAFA),
                  letterSpacing: -0.065,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 텍스트 입력 위젯 (피그마: DetailView_Title)
  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: _textController,
        autofocus: true,
        style: const TextStyle(
          fontFamily: 'LINE Seed JP App_TTF',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
          letterSpacing: -0.095,
          height: 1.4,
        ),
        decoration: InputDecoration(
          hintText: QuickAddConfig.placeholderHabit, // "新しいルーティンを記録"
          hintStyle: const TextStyle(
            fontFamily: 'LINE Seed JP App_TTF',
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFFAAAAAA), // 피그마: #aaaaaa
            letterSpacing: -0.095,
            height: 1.4,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
        maxLines: 1,
      ),
    );
  }

  /// DetailOption 버튼 영역 (피그마: DetailOption/Box)
  Widget _buildDetailOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1️⃣ DetailOption 버튼 (피그마: 64×64px)
          _DetailOptionButton(
            icon: Icons.alarm_outlined,
            onTap: () {
              print('⏰ [습관 팝업] 시간 설정 버튼 클릭');
              // TODO: 시간 설정 모달
            },
          ),

          const SizedBox(width: QuickAddConfig.detailOptionSpacing),

          // 2️⃣ DetailOption 버튼
          _DetailOptionButton(
            icon: Icons.palette_outlined,
            onTap: () {
              print('🎨 [습관 팝업] 색상 선택 버튼 클릭');
              // TODO: 색상 선택 모달
            },
          ),

          const SizedBox(width: QuickAddConfig.detailOptionSpacing),

          // 3️⃣ DetailOption 버튼
          _DetailOptionButton(
            icon: Icons.repeat,
            onTap: () {
              print('🔄 [습관 팝업] 반복 설정 버튼 클릭');
              // TODO: 반복 설정 모달
            },
          ),
        ],
      ),
    );
  }

  /// 하단 바 (삭제 버튼)
  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // 좌측: 삭제 버튼 (피그마: Frame 774)
          GestureDetector(
            onTap: () {
              print('🗑️ [습관 팝업] 삭제 버튼 클릭');
              Navigator.of(context).pop();
            },
            child: Container(
              width: 100,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA), // 피그마: #fafafa
                border: Border.all(
                  color: const Color(0xFFBABABA).withOpacity(0.08),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(
                  QuickAddConfig.deleteButtonRadius,
                ), // 16px
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: QuickAddConfig.deleteButtonColor, // #f74a4a
                  ),
                  const SizedBox(width: 6),
                  Text(
                    QuickAddConfig.buttonDelete, // "削除"
                    style: QuickAddConfig.deleteButtonStyle, // Bold 13px
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 저장 처리
  void _handleSave() {
    print('\n========================================');
    print('💾 [습관 팝업] 완료 버튼 클릭 - 저장 시작');

    final text = _textController.text.trim();
    if (text.isEmpty) {
      print('❌ [습관 팝업] 텍스트 없음 - 저장 중단');
      return;
    }

    final data = <String, dynamic>{
      'type': QuickAddType.habit,
      'title': text,
      'colorId': _selectedColorId,
      'habitTime': _habitTime ?? widget.selectedDate,
    };

    print('📦 [습관 팝업] 데이터 수집 완료:');
    print('   → 제목: ${data['title']}');
    print('   → 색상: ${data['colorId']}');
    print('   → 시간: ${data['habitTime']}');

    widget.onSave?.call(data);

    print('✅ [습관 팝업] onSave 콜백 실행 완료');
    print('========================================\n');

    Navigator.of(context).pop();
  }
}

/// DetailOption 버튼 위젯 (피그마: DetailOption 64×64px)
class _DetailOptionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _DetailOptionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: QuickAddConfig.detailOptionSize, // 피그마: 64px
        height: QuickAddConfig.detailOptionSize, // 피그마: 64px
        decoration: BoxDecoration(
          color: QuickAddConfig.controlBoxBackground, // #ffffff
          border: Border.all(
            color: QuickAddConfig.controlBoxBorder, // #111111 opacity 8%
            width: 1,
          ),
          borderRadius: BorderRadius.circular(
            QuickAddConfig.detailOptionRadius,
          ), // 24px
        ),
        child: Icon(
          icon,
          size: 24,
          color: QuickAddConfig.normalText, // #262626
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../const/quick_add_config.dart';
import '../../const/color.dart';

/// 색상 선택 모달 위젯
/// 이거를 설정하고 → 피그마 OptionSetting (색상) 디자인을 재현해서
/// 이거를 해서 → 5가지 색상 중 하나를 선택하고
/// 이거는 이래서 → 선택된 색상이 일정/할일에 적용된다
/// 이거라면 → 사용자가 시각적으로 색상을 구분할 수 있다
class ColorPickerModal extends StatefulWidget {
  final String? initialColorId; // 기존 선택된 색상 ID
  final Function(String colorId) onColorSelected;

  const ColorPickerModal({
    Key? key,
    this.initialColorId,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  State<ColorPickerModal> createState() => _ColorPickerModalState();
}

class _ColorPickerModalState extends State<ColorPickerModal> {
  late String _selectedColorId;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    // 이거를 설정하고 → 초기 색상을 설정해서
    // 이거를 해서 → 미리보기에 표시한다
    _selectedColorId = widget.initialColorId ?? 'gray';
    _selectedColor = _getColorFromId(_selectedColorId);
    print('🎨 [색상 모달] 초기 색상: $_selectedColorId');
  }

  // 색상 ID → Color 변환
  Color _getColorFromId(String colorId) {
    final colorMap = {
      'red': QuickAddConfig.modalColorPalette[0],
      'orange': QuickAddConfig.modalColorPalette[1],
      'blue': QuickAddConfig.modalColorPalette[2],
      'yellow': QuickAddConfig.modalColorPalette[3],
      'green': QuickAddConfig.modalColorPalette[4],
      'gray': categoryGray,
    };
    return colorMap[colorId] ?? categoryGray;
  }

  // Color → 색상 ID 변환
  String _getIdFromColor(Color color) {
    return QuickAddConfig.colorToIdMap[color] ?? 'gray';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: QuickAddConfig.modalWidth, // 피그마: 364px
      height: QuickAddConfig.colorPickerModalHeight, // 피그마: 414px
      decoration: BoxDecoration(
        color: QuickAddConfig.modalBackground, // 피그마: #fcfcfc
        border: Border.all(
          color: QuickAddConfig.modalBorder, // 피그마: #111111 opacity 10%
          width: 1,
        ),
        borderRadius: BorderRadius.circular(
          QuickAddConfig.modalRadius,
        ), // 피그마: 36px
      ),
      child: Column(
        children: [
          // ✅ TopNavi (피그마: Frame 784)
          _buildTopNavi(),

          // ✅ 색상 미리보기 영역 (피그마: Frame 783)
          Expanded(child: Center(child: _buildColorPreview())),

          // ✅ 색상 선택 영역 (피그마: 5개 원형)
          _buildColorPalette(),

          const SizedBox(height: 24),

          // ✅ CTA 버튼 (피그마: "完了")
          _buildCTAButton(),
        ],
      ),
    );
  }

  /// TopNavi 위젯 (피그마: TopNavi)
  /// 이거를 설정하고 → 좌측 제목 "色"와 우측 닫기 버튼을 배치해서
  /// 이거를 해서 → 모달의 상단 네비게이션을 구성한다
  Widget _buildTopNavi() {
    return Container(
      height: QuickAddConfig.topNaviHeight, // 피그마: 54px
      padding: EdgeInsets.symmetric(
        horizontal: QuickAddConfig.modalTopNaviLeftPadding,
      ), // 28px
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 좌측: 제목 "色"
          Text(
            QuickAddConfig.modalTitleColor, // 피그마: "色"
            style: QuickAddConfig.topNaviTitleStyle, // Bold 19px, #111111
          ),

          // 우측: 닫기 버튼 (피그마: Modal Control Buttons)
          GestureDetector(
            onTap: () {
              print('❌ [색상 모달] 닫기 버튼 클릭');
              Navigator.of(context).pop();
            },
            child: Container(
              width: 36, // 피그마: 36×36px
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E4E4).withOpacity(0.9), // 피그마
                border: Border.all(
                  color: const Color(0xFF111111).withOpacity(0.02),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Color(0xFF111111),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 색상 미리보기 위젯 (피그마: Ellipse 156)
  /// 이거를 설정하고 → 100×100px 원형으로 선택된 색상을 표시해서
  /// 이거를 해서 → 사용자에게 시각적 피드백을 제공한다
  Widget _buildColorPreview() {
    return Container(
      width: QuickAddConfig.colorPreviewSize, // 피그마: 100px
      height: QuickAddConfig.colorPreviewSize, // 피그마: 100px
      decoration: BoxDecoration(color: _selectedColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        'デザイン', // 피그마: 텍스트
        style: const TextStyle(
          fontFamily: 'LINE Seed JP App_TTF',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Color(0xFF7A7A7A), // 피그마: #7a7a7a
          letterSpacing: -0.095,
        ),
      ),
    );
  }

  /// 색상 팔레트 위젯 (피그마: Ellipse 157~161)
  /// 이거를 설정하고 → 5개의 색상 원형을 가로로 배치해서
  /// 이거를 해서 → 사용자가 색상을 선택한다
  Widget _buildColorPalette() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: QuickAddConfig.modalColorPalette.map((color) {
          final colorId = _getIdFromColor(color);
          final isSelected = color == _selectedColor;

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: QuickAddConfig.colorCircleSpacing / 2,
            ), // 8px
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                  _selectedColorId = colorId;
                });
                print('🎨 [색상 모달] 색상 선택: $colorId → $color');
              },
              child: Container(
                width: QuickAddConfig.colorCircleSize, // 피그마: 32px
                height: QuickAddConfig.colorCircleSize, // 피그마: 32px
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: QuickAddConfig.titleText, // #111111
                          width: 3,
                        )
                      : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// CTA 버튼 위젯 (피그마: CTA)
  /// 이거를 설정하고 → "完了" 버튼을 하단에 배치해서
  /// 이거를 해서 → 선택된 색상을 확정하고 모달을 닫는다
  Widget _buildCTAButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: GestureDetector(
        onTap: () {
          print('✅ [색상 모달] 완료 버튼 클릭 → 선택 색상: $_selectedColorId');
          widget.onColorSelected(_selectedColorId);
          Navigator.of(context).pop();
        },
        child: Container(
          width: 333, // 피그마: CTA width
          height: QuickAddConfig.ctaButtonHeight, // 피그마: 56px
          decoration: BoxDecoration(
            color: QuickAddConfig.buttonActive, // 피그마: #111111
            border: Border.all(
              color: const Color(0xFF111111).withOpacity(0.01),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            QuickAddConfig.buttonComplete, // 피그마: "完了"
            style: QuickAddConfig.ctaButtonStyle, // Bold 15px, #fafafa
          ),
        ),
      ),
    );
  }
}

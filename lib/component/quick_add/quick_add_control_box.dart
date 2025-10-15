import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../const/quick_add_config.dart';
import 'quick_add_type_selector.dart';
import 'quick_detail_button.dart';
import 'quick_detail_popup.dart';
import '../modal/color_picker_modal.dart';
import '../modal/date_time_picker_modal.dart';
import '../full_schedule_bottom_sheet.dart'; // ✅ 전체 일정 바텀시트 import

/// Quick_Add_ControlBox 메인 위젯
/// 이거를 설정하고 → 피그마 Quick_Add_ControlBox 디자인을 완벽 재현해서
/// 이거를 해서 → 일정/할일/습관 입력을 통합 관리하고
/// 이거는 이래서 → 동적으로 높이가 확장/축소되며 애니메이션된다
/// 이거라면 → 사용자가 하나의 UI에서 모든 타입을 입력할 수 있다
class QuickAddControlBox extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Map<String, dynamic> data)? onSave; // 저장 콜백
  final QuickAddType? externalSelectedType; // ✅ 외부에서 전달받는 타입
  final Function(QuickAddType?)? onTypeChanged; // ✅ 타입 변경 콜백

  const QuickAddControlBox({
    Key? key,
    required this.selectedDate,
    this.onSave,
    this.externalSelectedType, // ✅ 외부 타입
    this.onTypeChanged, // ✅ 타입 변경 알림
  }) : super(key: key);

  @override
  State<QuickAddControlBox> createState() => _QuickAddControlBoxState();
}

class _QuickAddControlBoxState extends State<QuickAddControlBox>
    with SingleTickerProviderStateMixin {
  // ========================================
  // 상태 변수
  // ========================================
  QuickAddType? _selectedType; // 선택된 타입 (일정/할일/습관)
  final TextEditingController _textController = TextEditingController();
  String _selectedColorId = 'gray'; // 선택된 색상 ID
  DateTime? _startDateTime; // 시작 날짜/시간
  DateTime? _endDateTime; // 종료 날짜/시간
  bool _showDetailPopup = false; // ✅ QuickDetailPopup 표시 여부

  // ========================================
  // 애니메이션 컨트롤러
  // ========================================
  late AnimationController _heightAnimationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ 외부에서 전달받은 타입이 있으면 초기화
    _selectedType = widget.externalSelectedType;

    // 이거를 설정하고 → AnimationController를 초기화해서
    // 이거를 해서 → 높이 확장 애니메이션을 제어한다
    _heightAnimationController = AnimationController(
      vsync: this,
      duration: QuickAddConfig.heightExpandDuration, // 350ms
    );

    // 이거를 설정하고 → 초기 높이를 설정해서
    // 이거를 해서 → 기본 상태는 132px로 시작한다
    _heightAnimation =
        Tween<double>(
          begin: QuickAddConfig.controlBoxInitialHeight, // 132px
          end: QuickAddConfig.controlBoxInitialHeight,
        ).animate(
          CurvedAnimation(
            parent: _heightAnimationController,
            curve: QuickAddConfig.heightExpandCurve, // easeInOutCubic
          ),
        );

    print('🎬 [Quick Add] 컨트롤 박스 초기화 완료 (외부 타입: $_selectedType)');
  }

  @override
  void didUpdateWidget(QuickAddControlBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ 외부 타입이 변경되면 내부 상태도 업데이트
    if (widget.externalSelectedType != oldWidget.externalSelectedType) {
      setState(() {
        _selectedType = widget.externalSelectedType;
      });
      print('🔄 [Quick Add] 외부 타입 변경 감지: $_selectedType');
    }
  }

  @override
  void dispose() {
    _heightAnimationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ========================================
  // 타입 선택 시 높이 변경
  // ========================================
  void _onTypeSelected(QuickAddType type) {
    setState(() {
      _selectedType = type;
      _showDetailPopup = false; // ✅ 타입 선택 시 팝업 숨김
    });

    // ✅ 외부에 타입 변경 알림
    widget.onTypeChanged?.call(type);

    // 이거를 설정하고 → 선택된 타입에 따라 목표 높이를 설정해서
    // 이거를 해서 → 애니메이션으로 높이를 확장한다
    double targetHeight;
    switch (type) {
      case QuickAddType.schedule:
        targetHeight = QuickAddConfig.controlBoxScheduleHeight; // 196px
        print('📅 [Quick Add] 일정 모드로 확장: ${targetHeight}px');
        break;
      case QuickAddType.task:
        targetHeight = QuickAddConfig.controlBoxTaskHeight; // 192px
        print('✅ [Quick Add] 할일 모드로 확장: ${targetHeight}px');
        break;
      case QuickAddType.habit:
        targetHeight = QuickAddConfig.controlBoxInitialHeight; // 132px (확장 없음)
        print('🔄 [Quick Add] 습관 모드 - 바텀시트 대신 표시');
        // TODO: 습관 바텀시트 표시 로직
        return;
    }

    // 이거를 설정하고 → 애니메이션 범위를 업데이트해서
    // 이거를 해서 → 부드럽게 높이가 변경된다
    _heightAnimation =
        Tween<double>(begin: _heightAnimation.value, end: targetHeight).animate(
          CurvedAnimation(
            parent: _heightAnimationController,
            curve: QuickAddConfig.heightExpandCurve,
          ),
        );

    _heightAnimationController.forward(from: 0.0);

    // 햅틱 피드백 (iOS 네이티브 스타일)
    HapticFeedback.lightImpact();
  }

  // ========================================
  // 색상 선택 모달 표시
  // ========================================
  void _showColorPicker() async {
    print('🎨 [Quick Add] 색상 선택 모달 열기');

    final selectedColorId = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Center(
        child: ColorPickerModal(
          initialColorId: _selectedColorId,
          onColorSelected: (colorId) {
            setState(() {
              _selectedColorId = colorId;
            });
            print('🎨 [Quick Add] 색상 선택됨: $colorId');
          },
        ),
      ),
    );

    if (selectedColorId != null) {
      setState(() {
        _selectedColorId = selectedColorId;
      });
    }
  }

  // ========================================
  // 날짜/시간 선택 모달 표시
  // ========================================
  void _showDateTimePicker() async {
    print('📅 [Quick Add] 일정 선택 모달 열기');

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => Center(
        child: DateTimePickerModal(
          initialStartDateTime: _startDateTime ?? widget.selectedDate,
          initialEndDateTime:
              _endDateTime ?? widget.selectedDate.add(Duration(hours: 1)),
          onDateTimeSelected: (start, end) {
            setState(() {
              _startDateTime = start;
              _endDateTime = end;
            });
            print('📅 [Quick Add] 일정 선택됨: 시작=$start, 종료=$end');
          },
        ),
      ),
    );
  }

  // ========================================
  // 전체 일정 바텀시트 표시
  // ========================================
  void _showFullScheduleBottomSheet() {
    print('📋 [Quick Add] 전체 일정 바텀시트 열기');
    // 이거를 설정하고 → 전체 일정 바텀시트를 isScrollControlled로 표시해서
    // 이거를 해서 → 전체 화면 크기로 확장되도록 한다
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 전체 화면 크기
      backgroundColor: Colors.transparent, // 투명 배경
      builder: (context) => FullScheduleBottomSheet(
        selectedDate: widget.selectedDate,
        initialTitle: _textController.text, // 이거는 이래서 → 기존 입력 제목 전달
      ),
    ).then((_) {
      // 이거라면 → 바텀시트 닫힌 후 원래 바텀시트도 닫기
      print('📋 [Quick Add] 전체 일정 바텀시트 닫힘');
      // Navigator.of(context).pop(); // 원래 바텀시트도 닫으려면 주석 해제
    });
  }

  // ========================================
  // 플레이스홀더 텍스트 반환
  // ========================================
  String _getPlaceholder() {
    // 이거를 설정하고 → 선택된 타입에 따라 플레이스홀더를 반환해서
    // 이거를 해서 → 사용자에게 적절한 안내를 제공한다
    switch (_selectedType) {
      case QuickAddType.schedule:
        return QuickAddConfig.placeholderSchedule; // "予定を追加"
      case QuickAddType.task:
        return QuickAddConfig.placeholderTask; // "やることをパッと入力"
      case QuickAddType.habit:
        return QuickAddConfig.placeholderHabit; // "新しいルーティンを記録"
      default:
        return QuickAddConfig.placeholderDefault; // "まずは一つ、入力してみて"
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none, // ✅ 팝업이 박스 밖으로 나갈 수 있도록
          children: [
            // ✅ 메인 Quick_Add_ControlBox
            Container(
              width: QuickAddConfig.controlBoxWidth, // 피그마: 365px
              height: _heightAnimation.value, // 동적 높이
              decoration: BoxDecoration(
                color: QuickAddConfig.controlBoxBackground, // 피그마: #ffffff
                border: Border.all(
                  color: QuickAddConfig.controlBoxBorder, // #111111 opacity 8%
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(
                  QuickAddConfig.controlBoxRadius,
                ), // 28px
              ),
              child: Column(
                children: [
                  // ✅ 상단: 텍스트 입력 + 추가 버튼 (Frame 700 + Frame 702)
                  _buildTopArea(),

                  // ✅ 중단: QuickDetail 옵션 (일정/할일 선택 시 표시)
                  if (_selectedType != null) _buildQuickDetails(),

                  const Spacer(),
                ],
              ),
            ),

            // ✅ QuickDetailPopup (텍스트 입력 시 우측 하단에 표시)
            if (_showDetailPopup && _selectedType == null)
              Positioned(
                // 피그마: Frame 705 위치 (우측 하단)
                right: 0,
                bottom: -20, // 약간 아래로
                child: QuickDetailPopup(
                  onScheduleSelected: () {
                    print('📋 [QuickDetailPopup] 일정 선택');
                    _onTypeSelected(QuickAddType.schedule);
                    setState(() {
                      _showDetailPopup = false;
                    });
                  },
                  onTaskSelected: () {
                    print('📋 [QuickDetailPopup] 할일 선택');
                    _onTypeSelected(QuickAddType.task);
                    setState(() {
                      _showDetailPopup = false;
                    });
                  },
                  onHabitSelected: () {
                    print('📋 [QuickDetailPopup] 습관 선택');
                    _onTypeSelected(QuickAddType.habit);
                    setState(() {
                      _showDetailPopup = false;
                    });
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  /// 타입 선택기를 외부로 제공하는 getter
  /// 이거를 설정하고 → 외부(CreateEntryBottomSheet)에서 접근 가능하도록 해서
  /// 이거를 해서 → 같은 레벨에 배치할 수 있다
  Widget getTypeSelector() {
    return QuickAddTypeSelector(
      selectedType: _selectedType,
      onTypeSelected: _onTypeSelected,
    );
  }

  /// 상단 영역: 텍스트 입력 + 추가 버튼 (피그마: Frame 700 + Frame 702)
  /// 이거를 설정하고 → Stack으로 배치해서
  /// 이거를 해서 → 텍스트와 버튼이 같은 줄에 표시된다
  Widget _buildTopArea() {
    return Container(
      height: 52, // 피그마: Frame 700 높이
      child: Stack(
        children: [
          // 좌측: 텍스트 입력 영역
          Positioned(
            left: 26,
            top: 0,
            bottom: 0,
            right: 122, // 우측 버튼 영역 확보
            child: Center(
              child: TextField(
                controller: _textController,
                autofocus: true, // ✅ 바텀시트 열릴 때 자동으로 키보드 표시
                onChanged: (text) {
                  // ✅ 텍스트 입력 시 QuickDetailPopup 표시
                  setState(() {
                    _showDetailPopup = text.isNotEmpty && _selectedType == null;
                  });
                  print(
                    '📝 [Quick Add] 텍스트 입력: "$text" → 팝업 표시: $_showDetailPopup',
                  );
                },
                style: const TextStyle(
                  fontFamily: 'LINE Seed JP App_TTF',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                  letterSpacing: -0.08,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: _getPlaceholder(),
                  hintStyle: QuickAddConfig.placeholderStyle,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 1,
              ),
            ),
          ),

          // 우측: DirectAddButton (피그마: Frame 702, 40×40px)
          Positioned(right: 18, top: 6, child: _buildAddButton()),
        ],
      ),
    );
  }

  /// QuickDetail 옵션 영역 (피그마: Frame 709)
  Widget _buildQuickDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: _selectedType == QuickAddType.schedule
            ? _buildScheduleDetails()
            : _buildTaskDetails(),
      ),
    );
  }

  /// 일정 QuickDetail 옵션 (피그마: 색상, 시작-종료, 더보기)
  List<Widget> _buildScheduleDetails() {
    return [
      // 1️⃣ 색상 아이콘 (피그마: QuickDetail_color)
      QuickDetailButton(
        icon: Icons.circle,
        showIconOnly: true,
        onTap: () {
          print('🎨 [Quick Add] 색상 버튼 클릭');
          _showColorPicker();
        },
      ),

      const SizedBox(width: QuickAddConfig.quickDetailSpacing),

      // 2️⃣ 시작-종료 (피그마: QuickDetail_date, "開始-終了")
      QuickDetailButton(
        icon: Icons.access_time,
        text: QuickAddConfig.quickDetailScheduleTime, // "開始-終了"
        onTap: () {
          print('⏰ [Quick Add] 시작-종료 버튼 클릭');
          _showDateTimePicker();
        },
      ),

      const SizedBox(width: QuickAddConfig.quickDetailSpacing),

      // 3️⃣ 더보기 아이콘 (피그마: QuickDetail_more)
      QuickDetailButton(
        icon: Icons.more_horiz,
        showIconOnly: true,
        onTap: () {
          print('📋 [Quick Add] 더보기 버튼 클릭 → 전체 일정 바텀시트 표시');
          // 이거를 설정하고 → 전체 일정 바텀시트를 표시해서
          _showFullScheduleBottomSheet();
        },
      ),
    ];
  }

  /// 할일 QuickDetail 옵션 (피그마: 색상, 마감일, 더보기)
  List<Widget> _buildTaskDetails() {
    return [
      // 1️⃣ 색상 아이콘 (피그마: QuickDetail_color)
      QuickDetailButton(
        icon: Icons.circle,
        showIconOnly: true,
        onTap: () {
          print('🎨 [Quick Add] 색상 버튼 클릭');
          _showColorPicker();
        },
      ),

      const SizedBox(width: QuickAddConfig.quickDetailSpacing),

      // 2️⃣ 마감일 (피그마: QuickDetail_deadline, "締め切り")
      QuickDetailButton(
        icon: Icons.event_outlined,
        text: QuickAddConfig.quickDetailTaskDeadline, // "締め切り"
        onTap: () {
          print('📆 [Quick Add] 마감일 버튼 클릭');
          _showDateTimePicker();
        },
      ),

      const SizedBox(width: QuickAddConfig.quickDetailSpacing),

      // 3️⃣ 더보기 아이콘 (피그마: QuickDetail_more)
      QuickDetailButton(
        icon: Icons.more_horiz,
        showIconOnly: true,
        onTap: () {
          print('📋 [Quick Add] 더보기 버튼 클릭');
          // TODO: 더보기 옵션 모달
        },
      ),
    ];
  }

  /// DirectAddButton (피그마: QuickAdd_DirectAddButton_Input_active!, 40×40px)
  /// 이거를 설정하고 → 원형 아이콘 버튼으로 표시해서
  /// 이거를 해서 → 피그마 디자인과 정확히 일치시킨다
  Widget _buildAddButton() {
    final hasText = _textController.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: hasText ? _handleDirectAdd : null,
      child: Container(
        width: 40, // 피그마: Frame 699 width
        height: 40, // 피그마: Frame 699 height
        decoration: BoxDecoration(
          color: hasText
              ? const Color(0xFF111111) // 활성: #111111
              : const Color(0xFFDDDDDD), // 비활성: #dddddd
          borderRadius: BorderRadius.circular(16), // 피그마: cornerRadius 16px
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.add, // 더하기 아이콘
          size: 24, // 피그마: icon 24×24px
          color: hasText
              ? const Color(0xFFFFFFFF) // 활성: 흰색
              : const Color(0xFFAAAAAA), // 비활성: 회색
        ),
      ),
    );
  }

  /// DirectAddButton 클릭 처리
  /// 이거를 설정하고 → 입력된 데이터를 수집해서
  /// 이거를 해서 → onSave 콜백으로 전달한다
  void _handleDirectAdd() {
    print('\n========================================');
    print('➕ [Quick Add] DirectAddButton 클릭 - 빠른 추가 시작');

    final text = _textController.text.trim();
    if (text.isEmpty) {
      print('❌ [Quick Add] 텍스트 없음 - 추가 중단');
      return;
    }

    // 이거를 설정하고 → 타입별로 데이터를 구성해서
    // 이거를 해서 → 부모 위젯에 전달한다
    final data = <String, dynamic>{
      'type': _selectedType ?? QuickAddType.schedule,
      'title': text,
      'colorId': _selectedColorId,
      'startDateTime': _startDateTime ?? widget.selectedDate,
      'endDateTime':
          _endDateTime ?? widget.selectedDate.add(Duration(hours: 1)),
    };

    print('📦 [Quick Add] 데이터 수집 완료:');
    print('   → 타입: ${data['type']}');
    print('   → 제목: ${data['title']}');
    print('   → 색상: ${data['colorId']}');
    print('   → 시작: ${data['startDateTime']}');
    print('   → 종료: ${data['endDateTime']}');

    widget.onSave?.call(data);

    print('✅ [Quick Add] onSave 콜백 실행 완료');
    print('========================================\n');

    // 햅틱 피드백
    HapticFeedback.mediumImpact();
  }
}

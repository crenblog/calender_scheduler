import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../Database/schedule_database.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart' hide Column;

/// FullScheduleBottomSheet - More 버튼으로 표시되는 전체 일정 입력 바텀시트
/// 이거를 설정하고 → 이미지 기반 Figma 디자인을 완전히 복제해서
/// 이거를 해서 → 모든 일정 옵션을 입력할 수 있는 UI를 제공하고
/// 이거는 이래서 → 사용자가 상세한 일정 정보를 설정할 수 있다
/// 이거라면 → DB에 완전한 일정 데이터가 저장된다
class FullScheduleBottomSheet extends StatefulWidget {
  final DateTime selectedDate; // 선택된 날짜
  final String? initialTitle; // 간단 모드에서 입력한 제목 (있으면 자동 입력)

  const FullScheduleBottomSheet({
    super.key,
    required this.selectedDate,
    this.initialTitle,
  });

  @override
  State<FullScheduleBottomSheet> createState() =>
      _FullScheduleBottomSheetState();
}

class _FullScheduleBottomSheetState extends State<FullScheduleBottomSheet>
    with SingleTickerProviderStateMixin {
  // ========================================
  // ✅ 상태 변수
  // ========================================

  late TextEditingController _titleController; // 제목 입력 컨트롤러
  late AnimationController _headerAnimationController; // 헤더 X → 完了 애니메이션

  // 날짜/시간 관련
  DateTime? _startDate; // 시작 날짜
  DateTime? _endDate; // 종료 날짜
  TimeOfDay? _startTime; // 시작 시간
  TimeOfDay? _endTime; // 종료 시간
  // bool _isAllDay = false; // 종일 여부 (현재는 표시만, 미사용)

  // 하단 옵션
  String? _repeatSetting; // 반복 설정 (예: "2日毎")
  String? _alarmSetting; // 알림 설정 (예: "10分前")
  String _selectedColor = 'blue'; // 선택된 색상 (기본: 파랑)

  @override
  void initState() {
    super.initState();
    // 이거를 설정하고 → 제목 컨트롤러 초기화해서
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    // 이거를 해서 → 간단 모드에서 입력한 제목이 있으면 자동으로 표시한다

    // 이거를 설정하고 → 헤더 애니메이션 컨트롤러 초기화해서
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // 이거를 해서 → X 버튼과 完了 버튼 사이를 부드럽게 전환한다

    // 이거는 이래서 → 제목이 이미 있으면 完了 버튼 상태로 시작
    if (_titleController.text.isNotEmpty) {
      _headerAnimationController.value = 1.0;
    }

    // 이거라면 → 제목 변경을 감지해서 헤더 버튼 애니메이션 제어
    _titleController.addListener(_onTitleChanged);

    // 이거를 설정하고 → 기본 날짜를 선택된 날짜로 초기화한다
    _startDate = widget.selectedDate;
    _endDate = widget.selectedDate;

    print(
      '📅 [FullScheduleBottomSheet] 초기화 완료 - 날짜: ${widget.selectedDate}, 제목: ${widget.initialTitle}',
    );
  }

  @override
  void dispose() {
    // 이거를 설정하고 → 메모리 누수 방지를 위해 리소스 정리
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _headerAnimationController.dispose();
    print('🗑️ [FullScheduleBottomSheet] 리소스 정리 완료');
    super.dispose();
  }

  // ========================================
  // ✅ 제목 변경 감지 (X ↔ 完了 애니메이션)
  // ========================================

  /// 이거를 설정하고 → 제목 입력 상태를 감지해서
  /// 이거를 해서 → 텍스트가 있으면 完了 버튼으로 전환하고
  /// 이거는 이래서 → 비어있으면 X 버튼으로 전환한다
  void _onTitleChanged() {
    if (_titleController.text.isNotEmpty) {
      // 이거라면 → 텍스트가 있으면 完了 버튼으로 애니메이션
      _headerAnimationController.forward();
    } else {
      // 이거를 설정하고 → 텍스트가 없으면 X 버튼으로 되돌림
      _headerAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 이거를 설정하고 → 전체 화면 크기의 바텀시트를 구성해서
    return Container(
      height: MediaQuery.of(context).size.height * 0.9, // 화면의 90% 높이
      decoration: BoxDecoration(
        // 이거를 해서 → 이미지 기반 디자인: 흰색 배경 + 상단 둥근 모서리
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36), // 이미지: 상단 좌측 36px
          topRight: Radius.circular(36), // 이미지: 상단 우측 36px
        ),
      ),
      child: Column(
        children: [
          // ✅ 헤더 (스케쥴 + X/完了 버튼)
          _buildHeader(),

          // ✅ 스크롤 가능한 콘텐츠 영역
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ 제목 입력
                  _buildTitleSection(),

                  const SizedBox(height: 32),

                  // ✅ 종일 섹션 (아이콘 + 레이블)
                  _buildAllDaySection(),

                  const SizedBox(height: 24),

                  // ✅ 날짜/시간 선택
                  _buildDateTimeSection(),

                  const SizedBox(height: 32),

                  // ✅ 하단 3개 옵션 (반복/알림/색상)
                  _buildOptionsSection(),

                  const SizedBox(height: 48),

                  // ✅ 삭제 버튼
                  _buildDeleteButton(),

                  const SizedBox(height: 32), // 하단 여백
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // ✅ UI 컴포넌트들
  // ========================================

  /// 헤더 구성 - "スケジュール" + X/完了 버튼 (애니메이션)
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 이거를 설정하고 → 좌측에 "スケジュール" 텍스트 배치
          const Text(
            'スケジュール',
            style: TextStyle(
              fontFamily: 'LINE Seed JP App_TTF',
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Color(0xFF505050), // 이미지: 회색 텍스트
              letterSpacing: -0.095,
              height: 1.4,
            ),
          ),

          // 이거를 해서 → 우측에 X ↔ 完了 애니메이션 버튼 배치
          _buildAnimatedHeaderButton(),
        ],
      ),
    );
  }

  /// X ↔ 完了 애니메이션 버튼
  Widget _buildAnimatedHeaderButton() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        // 이거는 이래서 → 애니메이션 진행률에 따라 버튼 스타일 변경
        final progress = _headerAnimationController.value;

        // 이거라면 → X 버튼 (progress = 0) ↔ 完了 버튼 (progress = 1)
        final isComplete = progress > 0.5;

        return GestureDetector(
          onTap: () {
            if (isComplete) {
              // 이거를 설정하고 → 完了 버튼이면 저장 처리
              _saveSchedule();
            } else {
              // 이거를 해서 → X 버튼이면 바텀시트 닫기
              Navigator.of(context).pop();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              // 이거는 이래서 → 完了일 때는 검은 배경, X일 때는 투명
              color: Color.lerp(
                Colors.transparent,
                const Color(0xFF111111), // 이미지: 검은색
                progress,
              ),
              borderRadius: BorderRadius.circular(100), // 이미지: 완전한 둥근 모서리
              border: Border.all(
                color: const Color(0xFFE4E4E4), // 이미지: 연한 회색 테두리
                width: 1,
              ),
            ),
            child: isComplete
                ? const Text(
                    '完了',
                    style: TextStyle(
                      fontFamily: 'LINE Seed JP App_TTF',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFAFAFA), // 이미지: 흰색 텍스트
                      letterSpacing: -0.075,
                      height: 1.4,
                    ),
                  )
                : const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF111111), // 이미지: 검은색 X
                  ),
          ),
        );
      },
    );
  }

  /// 제목 입력 섹션
  Widget _buildTitleSection() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        hintText: '予定を追加', // 이미지: 플레이스홀더
        hintStyle: const TextStyle(
          fontFamily: 'LINE Seed JP App_TTF',
          fontSize: 24, // 이미지: 큰 텍스트
          fontWeight: FontWeight.w700,
          color: Color(0xFFAAAAAA), // 이미지: 회색
          letterSpacing: -0.12,
          height: 1.4,
        ),
        border: InputBorder.none, // 테두리 없음
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(
        fontFamily: 'LINE Seed JP App_TTF',
        fontSize: 24, // 이미지: 큰 텍스트
        fontWeight: FontWeight.w700,
        color: Color(0xFF111111), // 이미지: 검은색
        letterSpacing: -0.12,
        height: 1.4,
      ),
      textInputAction: TextInputAction.done,
    );
  }

  /// 종일 섹션 (아이콘 + 레이블만)
  Widget _buildAllDaySection() {
    return Row(
      children: [
        // 이거를 설정하고 → 종일 아이콘 표시
        const Icon(
          Icons.access_time, // 이미지: 시계 아이콘
          size: 20,
          color: Color(0xFF111111),
        ),
        const SizedBox(width: 8),
        // 이거를 해서 → "終日" 레이블 표시
        const Text(
          '終日',
          style: TextStyle(
            fontFamily: 'LINE Seed JP App_TTF',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
            letterSpacing: -0.08,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// 날짜/시간 선택 섹션
  Widget _buildDateTimeSection() {
    return Row(
      children: [
        // ✅ 시작 (開始)
        Expanded(
          child: _buildTimeColumn(
            label: '開始',
            date: _startDate,
            time: _startTime,
            onDateTap: () => _showDatePicker(isStart: true),
            onTimeTap: () => _showTimePicker(isStart: true),
          ),
        ),

        const SizedBox(width: 24),

        // ✅ 화살표
        const Icon(Icons.arrow_forward, size: 20, color: Color(0xFFAAAAAA)),

        const SizedBox(width: 24),

        // ✅ 종료 (終了)
        Expanded(
          child: _buildTimeColumn(
            label: '終了',
            date: _endDate,
            time: _endTime,
            onDateTap: () => _showDatePicker(isStart: false),
            onTimeTap: () => _showTimePicker(isStart: false),
          ),
        ),
      ],
    );
  }

  /// 시작/종료 시간 컬럼
  Widget _buildTimeColumn({
    required String label,
    DateTime? date,
    TimeOfDay? time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이거를 설정하고 → 레이블 (開始/終了) 표시
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'LINE Seed JP App_TTF',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFAAAAAA), // 이미지: 회색
            letterSpacing: -0.07,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 8),

        // 이거를 해서 → 날짜 표시 또는 + 버튼
        GestureDetector(
          onTap: onDateTap,
          child: date != null
              ? Text(
                  '${date.year % 100}.${date.month}.${date.day}', // 이미지: 25.7.30 형식
                  style: const TextStyle(
                    fontFamily: 'LINE Seed JP App_TTF',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111), // 이미지: 검은색
                    letterSpacing: -0.1,
                    height: 1.4,
                  ),
                )
              : _buildPlusButton(),
        ),

        const SizedBox(height: 8),

        // 이거는 이래서 → 시간 표시 또는 + 버튼
        GestureDetector(
          onTap: onTimeTap,
          child: time != null
              ? Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}', // 이미지: 15:30 형식
                  style: const TextStyle(
                    fontFamily: 'LINE Seed JP App_TTF',
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111), // 이미지: 검은색
                    letterSpacing: -0.16,
                    height: 1.2,
                  ),
                )
              : _buildPlusButton(),
        ),
      ],
    );
  }

  /// + 버튼 (날짜/시간 미선택 상태)
  Widget _buildPlusButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF111111), // 이미지: 검은색 배경
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.add,
        size: 24,
        color: Color(0xFFFAFAFA), // 이미지: 흰색 +
      ),
    );
  }

  /// 하단 3개 옵션 (반복/알림/색상)
  Widget _buildOptionsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // ✅ 반복
        _buildOptionButton(
          icon: Icons.repeat,
          label: _repeatSetting ?? '반복',
          onTap: _showRepeatModal,
        ),

        // ✅ 알림
        _buildOptionButton(
          icon: Icons.notifications_outlined,
          label: _alarmSetting ?? '알림',
          onTap: _showAlarmModal,
        ),

        // ✅ 색상
        _buildColorOption(),
      ],
    );
  }

  /// 옵션 버튼 (반복/알림)
  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // 이미지: 둥근 모서리
          border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: const Color(0xFF111111)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'LINE Seed JP App_TTF',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
                letterSpacing: -0.06,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 색상 옵션 (원형)
  Widget _buildColorOption() {
    return GestureDetector(
      onTap: _showColorModal,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getColorFromId(_selectedColor), // 이미지: 선택된 색상
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E5E5), width: 2),
        ),
      ),
    );
  }

  /// 삭제 버튼
  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _deleteSchedule,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.delete_outline,
              size: 20,
              color: Color(0xFFF74A4A), // 이미지: 빨간색
            ),
            SizedBox(width: 8),
            Text(
              '削除',
              style: TextStyle(
                fontFamily: 'LINE Seed JP App_TTF',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF74A4A), // 이미지: 빨간색
                letterSpacing: -0.075,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // ✅ 모달 표시 함수들
  // ========================================

  /// 날짜 선택 모달
  void _showDatePicker({required bool isStart}) async {
    // 이거를 설정하고 → iOS 스타일 날짜 picker를 표시해서
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? widget.selectedDate)
          : (_endDate ?? widget.selectedDate),
      firstDate: DateTime(2020), // 이거를 해서 → 2020년부터 선택 가능
      lastDate: DateTime(2030), // 이거는 이래서 → 2030년까지 선택 가능
      builder: (context, child) {
        // 이거라면 → 다크 모드 대응 및 스타일 커스터마이징
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF111111), // 이미지: 검은색 테마
              onPrimary: Color(0xFFFAFAFA), // 흰색 텍스트
              surface: Colors.white,
              onSurface: Color(0xFF111111),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          // 이거를 설정하고 → 시작 날짜 업데이트
          _startDate = picked;
          print('📅 [날짜 선택] 시작 날짜: ${picked.toString()}');
        } else {
          // 이거를 해서 → 종료 날짜 업데이트
          _endDate = picked;
          print('📅 [날짜 선택] 종료 날짜: ${picked.toString()}');
        }
      });
    }
  }

  /// 시간 선택 picker
  void _showTimePicker({required bool isStart}) async {
    // 이거를 설정하고 → iOS 스타일 시간 picker를 표시해서
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
      builder: (context, child) {
        // 이거를 해서 → 24시간 형식 및 스타일 커스터마이징
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF111111), // 이미지: 검은색 테마
              onPrimary: Color(0xFFFAFAFA), // 흰색 텍스트
              surface: Colors.white,
              onSurface: Color(0xFF111111),
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true, // 이거는 이래서 → 24시간 형식 사용
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          // 이거라면 → 시작 시간 업데이트
          _startTime = picked;
          print('⏰ [시간 선택] 시작 시간: ${picked.format(context)}');
        } else {
          // 이거를 설정하고 → 종료 시간 업데이트
          _endTime = picked;
          print('⏰ [시간 선택] 종료 시간: ${picked.format(context)}');
        }
      });
    }
  }

  /// 반복 설정 모달
  void _showRepeatModal() {
    // 이거를 설정하고 → 반복 옵션 선택 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '반복 설정',
          style: TextStyle(
            fontFamily: 'LINE Seed JP App_TTF',
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 이거를 해서 → 반복 옵션들을 리스트로 표시
            _buildRepeatOption('매일', '毎日'),
            _buildRepeatOption('2일마다', '2日毎'),
            _buildRepeatOption('매주', '毎週'),
            _buildRepeatOption('매월', '毎月'),
            _buildRepeatOption('반복 없음', 'なし'),
          ],
        ),
      ),
    );
  }

  /// 반복 옵션 아이템
  Widget _buildRepeatOption(String value, String label) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'LINE Seed JP App_TTF',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
        ),
      ),
      onTap: () {
        setState(() {
          // 이거는 이래서 → 선택된 반복 설정 저장
          _repeatSetting = label;
          print('🔄 [반복 설정] 선택: $label');
        });
        Navigator.of(context).pop();
      },
    );
  }

  /// 알림 설정 모달
  void _showAlarmModal() {
    // 이거를 설정하고 → 알림 시간 옵션 선택 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'アラーム',
          style: TextStyle(
            fontFamily: 'LINE Seed JP App_TTF',
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 이거를 해서 → 알림 시간 옵션들을 리스트로 표시
            _buildAlarmOption('정시', '定時'),
            _buildAlarmOption('5분 전', '5分前'),
            _buildAlarmOption('10분 전', '10分前'),
            _buildAlarmOption('30분 전', '30分前'),
            _buildAlarmOption('1시간 전', '1時間前'),
            _buildAlarmOption('알림 없음', 'なし'),
          ],
        ),
      ),
    );
  }

  /// 알림 옵션 아이템
  Widget _buildAlarmOption(String value, String label) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'LINE Seed JP App_TTF',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
        ),
      ),
      onTap: () {
        setState(() {
          // 이거는 이래서 → 선택된 알림 설정 저장
          _alarmSetting = label;
          print('🔔 [알림 설정] 선택: $label');
        });
        Navigator.of(context).pop();
      },
    );
  }

  /// 색상 선택 모달
  void _showColorModal() {
    // 이거라면 → 색상 선택 다이얼로그 표시
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '色',
          style: TextStyle(
            fontFamily: 'LINE Seed JP App_TTF',
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 이거를 설정하고 → 5가지 색상 옵션을 가로로 배치
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorCircle('red', const Color(0xFFD22D2D)),
                _buildColorCircle('orange', const Color(0xFFF57C00)),
                _buildColorCircle('blue', const Color(0xFF1976D2)),
                _buildColorCircle('yellow', const Color(0xFFF7BD11)),
                _buildColorCircle('green', const Color(0xFF54C8A1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 색상 선택 원형 버튼
  Widget _buildColorCircle(String colorId, Color color) {
    final isSelected = _selectedColor == colorId;
    return GestureDetector(
      onTap: () {
        setState(() {
          // 이거를 해서 → 선택된 색상 저장
          _selectedColor = colorId;
          print('🎨 [색상 선택] 선택: $colorId');
        });
        Navigator.of(context).pop();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            // 이거는 이래서 → 선택된 색상은 굵은 테두리 표시
            color: isSelected
                ? const Color(0xFF111111)
                : const Color(0xFFE5E5E5),
            width: isSelected ? 3 : 2,
          ),
        ),
      ),
    );
  }

  // ========================================
  // ✅ 데이터 처리 함수들
  // ========================================

  /// 일정 저장
  void _saveSchedule() async {
    // 이거를 설정하고 → 입력된 데이터 검증
    if (_titleController.text.isEmpty) {
      print('⚠️ [저장 실패] 제목이 비어있음');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('제목을 입력해주세요')));
      return;
    }

    try {
      // 이거를 해서 → 시작/종료 DateTime 생성
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime?.hour ?? 0,
        _startTime?.minute ?? 0,
      );

      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime?.hour ?? 23,
        _endTime?.minute ?? 59,
      );

      // 이거는 이래서 → ScheduleCompanion 객체 생성
      final schedule = ScheduleCompanion(
        summary: Value(_titleController.text),
        start: Value(startDateTime),
        end: Value(endDateTime),
        colorId: Value(_selectedColor),
        createdAt: Value(DateTime.now()),
      );

      // 이거라면 → DB에 저장
      await GetIt.I<AppDatabase>().createSchedule(schedule);
      print(
        '💾 [저장 성공] 제목: ${_titleController.text}, 날짜: $startDateTime ~ $endDateTime',
      );

      // 이거를 설정하고 → 저장 후 바텀시트 닫기
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('일정이 저장되었습니다')));
      }
    } catch (e) {
      print('❌ [저장 에러] $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }

  /// 일정 삭제
  void _deleteSchedule() {
    // TODO: 삭제 확인 다이얼로그 + 삭제 처리
    print('🗑️ [삭제] 일정 삭제');
    Navigator.of(context).pop();
  }

  /// 색상 ID → Color 변환
  Color _getColorFromId(String colorId) {
    switch (colorId) {
      case 'red':
        return const Color(0xFFD22D2D);
      case 'orange':
        return const Color(0xFFF57C00);
      case 'blue':
        return const Color(0xFF1976D2);
      case 'yellow':
        return const Color(0xFFF7BD11);
      case 'green':
        return const Color(0xFF54C8A1);
      default:
        return const Color(0xFF111111); // 이미지: 검은색 (기본값)
    }
  }
}

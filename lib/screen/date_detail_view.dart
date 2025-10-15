import 'package:flutter/material.dart';
import '../component/schedule_card.dart';
import '../component/create_entry_bottom_sheet.dart';
import '../component/slidable_schedule_card.dart'; // ✅ Slidable 컴포넌트 추가
import '../widgets/bottom_navigation_bar.dart'; // ✅ 하단 네비게이션 바 추가
import '../utils/common_functions.dart';
import '../const/color.dart';
import '../Database/schedule_database.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // ✅ Slidable 패키지 추가

/// 선택된 날짜의 상세 스케줄을 리스트 형태로 표시하는 화면
/// ⭐️ DB 통합: StreamBuilder를 사용해서 해당 날짜의 일정을 실시간으로 관찰한다
/// 이거를 설정하고 → watchByDay()로 DB 스트림을 구독해서
/// 이거를 해서 → 일정이 추가/삭제될 때마다 자동으로 UI가 갱신된다
/// 이거는 이래서 → setState 없이도 실시간 반영이 가능하다
/// ✅ StatefulWidget 전환: 좌우 스와이프 및 Pull-to-dismiss 기능을 위해 상태 관리 필요
class DateDetailView extends StatefulWidget {
  final DateTime selectedDate; // 선택된 날짜를 저장하는 변수

  const DateDetailView({
    super.key,
    required this.selectedDate, // 선택된 날짜를 필수로 받는다
  });

  @override
  State<DateDetailView> createState() => _DateDetailViewState();
}

class _DateDetailViewState extends State<DateDetailView> {
  late DateTime _currentDate; // 현재 표시 중인 날짜 (좌우 스와이프로 변경됨)
  late PageController _pageController; // 좌우 스와이프를 위한 PageController
  double _dragOffset = 0.0; // Pull-to-dismiss를 위한 드래그 오프셋

  // 무한 스크롤을 위한 중앙 인덱스 (충분히 큰 수)
  static const int _centerIndex = 1000000;

  @override
  void initState() {
    super.initState();
    // 이거를 설정하고 → 기존 selectedDate를 현재 날짜로 초기화해서
    _currentDate = widget.selectedDate;
    // 이거를 해서 → 무한 스크롤을 위한 PageController 생성한다 (중앙 인덱스부터 시작)
    _pageController = PageController(initialPage: _centerIndex);
    print('📅 [DateDetailView] 초기화 완료 - 날짜: $_currentDate');
  }

  @override
  void dispose() {
    // 이거를 설정하고 → 메모리 누수 방지를 위해 컨트롤러 정리
    _pageController.dispose();
    print('🗑️ [DateDetailView] 리소스 정리 완료');
    super.dispose();
  }

  // 이거를 설정하고 → 인덱스를 실제 날짜로 변환하는 함수
  // 이거를 해서 → 중앙 인덱스 기준으로 상대적 날짜를 계산한다
  DateTime _getDateForIndex(int index) {
    final daysDiff = index - _centerIndex;
    return widget.selectedDate.add(Duration(days: daysDiff));
  }

  @override
  Widget build(BuildContext context) {
    // 이거를 설정하고 → 기존 Scaffold를 GestureDetector로 감싸서 Pull-to-dismiss 제스처 추가
    return GestureDetector(
      // 이거를 해서 → 수직 드래그 업데이트를 실시간으로 감지한다
      onVerticalDragUpdate: _handleDragUpdate,
      // 이거는 이래서 → 드래그 종료 시 dismiss 여부를 판단한다
      onVerticalDragEnd: _handleDragEnd,
      child: Transform.translate(
        // 이거라면 → 드래그 오프셋만큼 화면을 이동시킨다
        offset: Offset(0, _dragOffset),
        child: Scaffold(
          // 앱바를 설정해서 뒤로가기 버튼과 제목을 표시한다
          appBar: _buildAppBar(context),
          // 배경색을 밝은 회색으로 설정해서 깔끔한 느낌을 만든다
          backgroundColor: gray050,
          // ⭐️ PageView로 좌우 스와이프 날짜 변경 기능 추가 (기존 Hero 구조 유지)
          body: _buildPageView(),
          // ✅ FloatingActionButton 제거 → 하단 네비게이션 바로 대체
          // ✅ 하단 네비게이션 바 추가 (피그마: Frame 822)
          bottomNavigationBar: CustomBottomNavigationBar(
            onInboxTap: () {
              print('📥 [하단 네비] Inbox 버튼 클릭');
              // TODO: Inbox 화면으로 이동
            },
            onStarTap: () {
              print('⭐ [하단 네비] 별 버튼 클릭');
              // TODO: 즐겨찾기 화면으로 이동
            },
            onAddTap: () {
              // 이거를 설정하고 → 바텀시트를 표시해서
              // 이거를 해서 → 사용자가 일정을 입력하면
              // 이거는 이래서 → CreateEntryBottomSheet에서 DB에 저장한다
              // 이거라면 → StreamBuilder가 자동으로 감지해서 UI 갱신한다
              showModalBottomSheet(
                context: context,
                builder: (context) =>
                    CreateEntryBottomSheet(selectedDate: _currentDate),
              );
              print('➕ [하단 네비] 일정 추가 버튼 클릭 → 바텀시트 표시');
            },
            isStarSelected: false, // TODO: 상태 관리
          ),
        ),
      ),
    );
  }

  // ========================================
  // ✅ Pull-to-Dismiss 제스처 핸들러
  // ========================================

  /// 이거를 설정하고 → 드래그 업데이트 이벤트를 처리해서
  /// 이거를 해서 → 드래그 오프셋을 실시간으로 업데이트한다
  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      // 이거를 설정하고 → 드래그 거리를 누적해서
      _dragOffset += details.delta.dy;
      // 이거를 해서 → 위로 드래그는 무시한다 (음수 방지)
      if (_dragOffset < 0) _dragOffset = 0;
    });
    print('👆 [Pull-to-Dismiss] 드래그 중: $_dragOffset');
  }

  /// 이거를 설정하고 → 드래그 종료 이벤트를 처리해서
  /// 이거를 해서 → dismiss 여부를 판단하고 실행한다
  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    final progress = _dragOffset / MediaQuery.of(context).size.height;

    print(
      '✋ [Pull-to-Dismiss] 드래그 종료 - 속도: $velocity, 진행률: ${(progress * 100).toStringAsFixed(1)}%',
    );

    // 이거는 이래서 → 속도(500px/s 이상) 또는 진행률(30% 이상)이 임계값 초과하면
    if (velocity > 500 || progress > 0.3) {
      // 이거라면 → 기존 Navigator.pop() 방식 그대로 사용해서 HomeScreen으로 복귀
      print('✅ [Pull-to-Dismiss] Dismiss 실행 → HomeScreen 복귀');
      Navigator.of(context).pop();
    } else {
      // 이거를 설정하고 → 임계값 미만이면 원위치로 복귀시킨다
      print('↩️ [Pull-to-Dismiss] 원위치 복귀');
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  // ========================================
  // ✅ PageView 구현 (좌우 스와이프 날짜 변경)
  // ========================================

  /// 이거를 설정하고 → PageView를 구성해서 좌우 스와이프 날짜 변경 기능 제공
  /// 이거를 해서 → 기존 Hero 구조를 그대로 유지하면서 무한 스크롤 구현
  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          // 이거를 설정하고 → 인덱스를 날짜로 변환해서
          _currentDate = _getDateForIndex(index);
          print('📆 [PageView] 날짜 변경: $_currentDate');
        });
      },
      itemBuilder: (context, index) {
        final date = _getDateForIndex(index);
        // 이거를 해서 → 기존 Hero 구조 그대로 유지한다 (애니메이션 보존)
        return Hero(
          tag: 'calendar-cell-${date.toString()}', // 기존 태그 방식 유지
          child: Material(
            color: gray050,
            // 이거는 이래서 → 기존 _buildBody 함수 재사용
            child: _buildBody(context, date),
          ),
        );
      },
    );
  }

  /// 앱바를 구성하는 함수 - 피그마 디자인: ⋯ 버튼 + 날짜 + v 버튼
  /// 이거를 설정하고 → 좌측에 설정(⋯), 중앙에 날짜, 우측에 닫기(v) 버튼을 배치해서
  /// 이거를 해서 → 피그마 디자인과 동일한 레이아웃을 만든다
  /// 이거는 이래서 → iOS 네이티브 앱과 유사한 UX를 제공한다
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: gray050, // 배경색을 화면과 동일하게 설정
      elevation: 0, // 그림자 제거
      automaticallyImplyLeading: false, // 기본 뒤로가기 버튼 제거
      // ✅ 좌측: 설정 버튼 (⋯ 세 점)
      leading: Container(
        margin: const EdgeInsets.only(left: 12),
        child: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE4E4E4).withOpacity(0.9),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: const Color(0xFF111111).withOpacity(0.02),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.more_horiz,
              color: Color(0xFF111111),
              size: 20,
            ),
          ),
          onPressed: () {
            print('⋮ [UI] 설정 버튼 클릭');
            // TODO: 설정 메뉴 표시
          },
        ),
      ),

      // ✅ 수정: 중앙 텍스트 제거 (Figma 디자인에 따라)
      title: null,
      centerTitle: true,

      // ✅ 우측: 닫기 버튼 (v 아래 화살표)
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E4E4).withOpacity(0.9),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color(0xFF111111).withOpacity(0.02),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF111111),
                size: 20,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              print('⬇️ [UI] 닫기 버튼 클릭 → HomeScreen으로 복귀');
            },
          ),
        ),
      ],
    );
  }

  /// 일본어 요일 변환 함수 (피그마 디자인 기준)
  /// 이거를 설정하고 → 숫자 요일을 일본어로 변환해서
  /// 이거를 해서 → AppBar에 "金曜日" 형식으로 표시한다
  String _getWeekdayJapanese(int weekday) {
    const weekdays = ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日'];
    return weekdays[weekday - 1];
  }

  /// 메인 바디를 구성하는 함수 - 피그마 디자인: 날짜 헤더 + 스케줄 리스트
  /// 이거를 설정하고 → 상단에 큰 날짜 표시를 추가하고
  /// 이거를 해서 → 피그마 디자인과 동일한 레이아웃을 만든다
  /// 이거는 이래서 → 시각적으로 명확한 날짜 정보를 제공한다
  /// ✅ 날짜 매개변수 추가: PageView에서 각 페이지마다 다른 날짜 표시
  Widget _buildBody(BuildContext context, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ 날짜 헤더 (피그마 디자인: 8月 금요일 + 11)
        _buildDateHeader(date),

        // ✅ 스케줄 리스트 (확장 영역)
        Expanded(child: _buildScheduleList(date)),
      ],
    );
  }

  /// 날짜 헤더 위젯 - 피그마 디자인 기준
  /// 이거를 설정하고 → 좌측에 날짜 정보를 배치해서
  /// 이거를 해서 → "8月 금요일" + "11" + "今日" 형식으로 표시한다
  /// 이거는 이래서 → 사용자가 어느 날짜를 보고 있는지 명확히 알 수 있다
  /// ✅ 날짜 매개변수 추가: 각 페이지마다 다른 날짜 표시
  Widget _buildDateHeader(DateTime date) {
    final isToday =
        date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ 상단: "8月 금요일" (가로 배치)
          Row(
            children: [
              Text(
                '${date.month}月',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF4444), // 빨간색
                  height: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _getWeekdayJapanese(date.weekday),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF999999), // 회색
                  height: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ✅ 하단: "11" + "今日" (가로 배치)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${date.day}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111111),
                  height: 1.2,
                ),
              ),
              if (isToday) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        '今日',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: const Color(0xFF222222),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// 스케줄 리스트를 구성하는 함수 - StreamBuilder로 실시간 표시
  /// 이거를 설정하고 → watchByDay()로 해당 날짜의 DB 스트림을 구독해서
  /// 이거를 해서 → snapshot이 변경될 때마다 자동으로 UI를 다시 그린다
  /// 이거는 이래서 → 일정 추가/삭제 시 setState 없이도 즉시 반영된다
  /// ✅ 날짜 매개변수 추가: 각 페이지마다 다른 날짜의 일정 표시
  Widget _buildScheduleList(DateTime date) {
    return StreamBuilder<List<ScheduleData>>(
      stream: GetIt.I<AppDatabase>().watchByDay(date),
      builder: (context, snapshot) {
        // 이거를 설정하고 → 스트림 상태를 확인해서
        print('📊 [UI] StreamBuilder 상태: ${snapshot.connectionState}');

        if (snapshot.hasError) {
          // 에러가 발생한 경우
          print('❌ [UI] 스트림 에러: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          // 이거를 해서 → 데이터가 아직 없으면 로딩 표시
          print('⏳ [UI] 데이터 로딩 중...');
          return const Center(child: CircularProgressIndicator());
        }

        final schedules = snapshot.data!;
        print('✅ [UI] 일정 ${schedules.length}개 렌더링');

        // 이거는 이래서 → 일정이 없으면 빈 상태 표시
        if (schedules.isEmpty) {
          return _buildEmptyState();
        }

        // 이거라면 → 일정 리스트를 카드 형태로 표시
        // ✅ SlidableAutoCloseBehavior로 감싸기
        // 이유: iOS 네이티브처럼 한 번에 하나의 Slidable만 열리도록 한다
        // 조건: ListView 전체를 감싸야 그룹 관리가 가능하다
        // 결과: 하나를 열면 다른 열린 Slidable은 자동으로 닫힌다
        return SlidableAutoCloseBehavior(
          child: ListView.separated(
            padding: CommonFunctions.createPadding(vertical: 8),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final schedule = schedules[index];

              // ✅ SlidableScheduleCard로 ScheduleCard를 감싸기
              // 이유: 스와이프 제스처로 완료/삭제 기능을 제공한다
              // 조건: scheduleId와 onComplete/onDelete 콜백이 필요하다
              // 결과: 오른쪽 스와이프로 삭제, 왼쪽 스와이프로 완료 가능
              return SlidableScheduleCard(
                groupTag: 'schedule_list', // 같은 그룹 태그로 묶어서 한 번에 하나만 열림
                scheduleId: schedule.id,

                // ✅ 완료 처리 콜백 (왼쪽 스와이프 - endActionPane)
                // 이거를 설정하고 → DB에서 완료 처리를 하면
                // 이거를 해서 → StreamBuilder가 자동으로 감지해서
                // 이거는 이래서 → UI가 즉시 갱신된다
                onComplete: () async {
                  print('✅ [DateDetailView] 일정 ID=${schedule.id} 완료 시작');
                  await GetIt.I<AppDatabase>().completeSchedule(schedule.id);
                  print('✅ [DateDetailView] 일정 ID=${schedule.id} 완료 완료');
                },

                // ✅ 삭제 처리 콜백 (오른쪽 스와이프 - startActionPane)
                // 이거를 설정하고 → DB에서 삭제를 하면
                // 이거를 해서 → StreamBuilder가 자동으로 감지해서
                // 이거는 이래서 → UI가 즉시 갱신된다
                onDelete: () async {
                  print('🗑️ [DateDetailView] 일정 ID=${schedule.id} 삭제 시작');
                  await GetIt.I<AppDatabase>().deleteSchedule(schedule.id);
                  print('🗑️ [DateDetailView] 일정 ID=${schedule.id} 삭제 완료');
                },

                // ✅ 실제 일정 카드 위젯
                child: ScheduleCard(
                  start: schedule.start,
                  end: schedule.end,
                  summary: schedule.summary,
                  colorId: schedule.colorId,
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
          ),
        );
      },
    );
  }

  /// 빈 상태를 표시하는 함수 - 스케줄이 없을 때 표시한다
  Widget _buildEmptyState() {
    return Center(
      // 가운데 정렬한다
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 세로 가운데 정렬한다
        children: [
          // 빈 상태 아이콘을 표시한다
          Icon(
            Icons.event_note, // 일정 아이콘을 사용한다
            size: 64, // 큰 크기로 설정한다
            color: gray400, // 회색으로 설정한다
          ),
          const SizedBox(height: 16), // 간격을 추가한다
          // 빈 상태 메시지를 표시한다
          Text(
            '등록된 일정이 없습니다', // 빈 상태 메시지를 표시한다
            style: CommonFunctions.createBaseTextStyle(
              fontSize: 16, // 중간 크기 폰트로 설정한다
              color: gray500, // 회색으로 설정한다
            ),
          ),
        ],
      ),
    );
  }
}

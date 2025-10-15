import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../const/color.dart';
import '../const/typography.dart';
import '../const/calendar_config.dart';
import '../const/motion_config.dart';
import '../component/create_entry_bottom_sheet.dart';
import '../screen/date_detail_view.dart';
import '../utils/apple_expansion_route.dart';
import '../Database/schedule_database.dart';
import '../widgets/bottom_navigation_bar.dart'; // ✅ 하단 네비게이션 바 추가
import 'package:get_it/get_it.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime focusedDay = DateTime.now(); //
  DateTime? selectedDay = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ); //현재 선택된 날짜이다. 중요!! 절대 지우거나 하면 안됨.

  // ⭐️ 로컬 schedules Map 제거됨
  // 이거는 이래서 → 이제 모든 일정은 DB에서 관리하고
  // 이거라면 → StreamBuilder로 실시간으로 가져온다

  @override
  Widget build(BuildContext context) {
    // 이거를 설정하고 → watchSchedules()로 전체 일정을 실시간 스트림으로 가져와서
    // 이거를 해서 → Map<DateTime, List<ScheduleData>>로 변환한 다음
    // 이거는 이래서 → TableCalendar가 해당 날짜별 일정 개수를 표시할 수 있다
    return StreamBuilder<List<ScheduleData>>(
      stream: GetIt.I<AppDatabase>().watchSchedules(),
      builder: (context, snapshot) {
        // 로딩 중이거나 에러 처리
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('⏳ [HomeScreen] StreamBuilder 로딩 중...');
        }

        if (snapshot.hasError) {
          print('❌ [HomeScreen] StreamBuilder 에러: ${snapshot.error}');
        }

        // 일정 리스트를 Map<DateTime, List<ScheduleData>>로 변환
        // 이거를 설정하고 → snapshot.data에서 일정 리스트를 가져와서
        // 이거를 해서 → 날짜별로 그룹화된 Map을 생성한다
        final schedules = <DateTime, List<ScheduleData>>{};
        if (snapshot.hasData) {
          print(
            '🔄 [HomeScreen] StreamBuilder 데이터 수신: ${snapshot.data!.length}개 일정',
          );
          for (final schedule in snapshot.data!) {
            // 날짜 키 생성 (시간 정보 제거, 날짜만 사용)
            final dateKey = DateTime(
              schedule.start.year,
              schedule.start.month,
              schedule.start.day,
            );
            schedules.putIfAbsent(dateKey, () => []).add(schedule);
          }
          print('📊 [HomeScreen] 날짜별 일정 그룹화 완료: ${schedules.length}개 날짜');
        }

        return Scaffold(
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
              // 이거를 설정하고 → 현재 선택된 날짜를 기준으로
              // 이거를 해서 → CreateEntryBottomSheet를 표시해
              // 이거는 이래서 → 일정 추가 시 DB에 저장되고
              // 이거라면 → StreamBuilder가 자동으로 UI를 갱신한다
              final targetDate = selectedDay ?? DateTime.now();
              showModalBottomSheet(
                context: context,
                builder: (context) =>
                    CreateEntryBottomSheet(selectedDate: targetDate),
              );
              print('➕ [하단 네비] 더하기 버튼 클릭 → 날짜: $targetDate');
            },
            isStarSelected: false, // TODO: 상태 관리
          ),
          body: SafeArea(
            child: Column(
              // Column으로 감싸서 세로로 배치
              children: [
                // ⭐️ 커스텀 헤더 추가: 햄버거 메뉴 + 날짜 표시
                _buildCustomHeader(),

                // TableCalendar를 Expanded로 감싸서 전체 화면을 차지하도록 만든다
                // 이렇게 하면 네이버 캘린더처럼 캘린더가 화면을 가득 채운다
                Expanded(
                  child: TableCalendar(
                    // 1. 기본 설정: 언어를 한국어로 설정하고 날짜 범위를 지정한다
                    locale: 'ko_KR', // 한국어로 설정해서 월/요일이 한글로 표시되도록 한다
                    firstDay: DateTime.utc(1800, 1, 1), // 캘린더의 최초 시작 날짜를 설정한다
                    lastDay: DateTime.utc(
                      3000,
                      12,
                      30,
                    ), // 캘린더의 마지막 선택 가능 날짜를 설정한다
                    focusedDay: focusedDay, // 현재 화면에 보이는 달을 설정한다
                    // 2. 전체 화면 설정: shouldFillViewport를 true로 설정해서 뷰포트를 완전히 채운다
                    shouldFillViewport: true, // 캘린더가 사용 가능한 모든 공간을 채우도록 설정한다
                    // 3. ⭐️ 헤더 숨김: TableCalendar의 기본 헤더를 숨기고 커스텀 헤더를 사용한다
                    headerVisible: false, // TableCalendar의 기본 헤더를 숨긴다
                    // 4. 캘린더 스타일: 날짜들의 모양과 색상을 설정한다
                    calendarStyle:
                        _buildCalendarStyle(), // 캘린더 전체 스타일을 적용해서 날짜들의 모양을 설정한다
                    // 5. 날짜 선택 처리: 사용자가 날짜를 클릭하면 선택된 날짜로 이동한다
                    onDaySelected:
                        _onDaySelected, // 날짜를 클릭하면 선택된 날짜로 이동하고 상태를 업데이트한다
                    // 6. ⭐️ 페이지(월) 변경 처리: 사용자가 좌우로 스와이프하여 월을 변경하면 헤더 업데이트
                    onPageChanged: (focusedDay) {
                      // focusedDay를 업데이트해서 헤더의 월 표시를 동적으로 변경한다
                      // setState를 호출해서 UI를 다시 그리고 "오늘로 돌아가기" 버튼도 조건부로 표시한다
                      setState(() {
                        this.focusedDay =
                            focusedDay; // 포커스된 날짜를 새로운 월의 날짜로 업데이트
                      });
                    },
                    // 7. 선택된 날짜 판단: 어떤 날짜가 선택된 상태인지 확인한다
                    selectedDayPredicate:
                        _selectedDayPredicate, // 선택된 날짜인지 확인해서 선택된 날짜만 강조 표시한다
                    // 8. 날짜 셀 빌더: 각 날짜 셀의 모양을 커스터마이징한다
                    calendarBuilders: _buildCalendarBuilders(
                      schedules,
                    ), // 각 날짜 셀의 모양을 설정해서 기본/선택/오늘/이전달 날짜를 다르게 표시한다
                  ),
                ),
                // 하단 ListView는 제거 - 스케줄 표시는 DateDetailView에서 처리한다
                // 이제 날짜를 클릭하면 바로 DateDetailView로 이동해서 상세 정보를 볼 수 있다ㄱ
                // 하단 40px 여백 추가 - 이미지 레이아웃과 동일하게 하단에 빈 공간을 만든다
                SizedBox(
                  height: 40,
                ), // 화면 최하단에 40픽셀의 여백을 추가해서 캘린더와 화면 끝 사이에 공간을 만든다
              ],
            ),
          ),
        );
      },
    ); // StreamBuilder 닫기
  }

  /// 위젯 영역 ------------------------------------------------------------------------------------------------
  // ⭐️ 피그마 디자인: TopNavi (54px 높이)
  // 좌측: 아이콘 버튼 (44×44px) + 중앙: "7月 2025" (ExtraBold 27px) + 우측: 날짜 배지 "11" (검은 배경, 36×36px)
  Widget _buildCustomHeader() {
    final today = DateTime.now();
    final isNotCurrentMonth =
        focusedDay.month != today.month || focusedDay.year != today.year;

    return Container(
      height: 54, // 피그마: TopNavi 높이 54px
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ✅ 좌측: 아이콘 버튼 영역 (Frame 685)
          Row(
            children: [
              // 아이콘 버튼 (44×44px)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu,
                  size: 32,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(width: 4),

              // ✅ 날짜 표시 영역 (Frame 688)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  // "7月" (ExtraBold 27px, #111111)
                  Text(
                    '${focusedDay.month}月',
                    style: const TextStyle(
                      fontFamily: 'LINE Seed JP App_TTF',
                      fontSize: 27,
                      fontWeight: FontWeight.w800, // ExtraBold
                      color: Color(0xFF111111),
                      letterSpacing: -0.135,
                      height: 1.4, // lineHeight 37.8 / fontSize 27
                    ),
                  ),

                  const SizedBox(width: 4),

                  // "2025" (Bold 27px, #CFCFCF)
                  Text(
                    '${focusedDay.year}',
                    style: const TextStyle(
                      fontFamily: 'LINE Seed JP App_TTF',
                      fontSize: 27,
                      fontWeight: FontWeight.w700, // Bold
                      color: Color(0xFFCFCFCF),
                      letterSpacing: -0.135,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ✅ 우측: 날짜 배지 (Frame 686) - 오늘이 아닌 월일 때만 표시
          if (isNotCurrentMonth) _buildTodayButton(today),
        ],
      ),
    );
  }

  // ✅ 피그마 디자인: Frame 686 (오늘 날짜 배지)
  // 36×36px, 검은 배경 (#111111), radius 12px, "11" 텍스트 (ExtraBold 12px, 흰색)
  Widget _buildTodayButton(DateTime today) {
    return Hero(
      tag: 'today-button-${today.toString()}',
      createRectTween: (begin, end) {
        return AppleStyleRectTween(begin: begin, end: end);
      },
      flightShuttleBuilder: appleStyleHeroFlightShuttleBuilder,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              focusedDay = today;
              selectedDay = DateTime.utc(today.year, today.month, today.day);
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 36, // 피그마: Frame 123 크기 36×36px
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF111111), // 피그마: 배경색 #111111
              borderRadius: BorderRadius.circular(12), // 피그마: radius 12px
              border: Border.all(
                color: const Color(
                  0xFF000000,
                ).withOpacity(0.04), // 피그마: rgba(0,0,0,0.04)
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${today.day}', // 피그마: "11" 텍스트
              style: const TextStyle(
                fontFamily: 'LINE Seed JP App_TTF',
                fontSize: 12, // 피그마: ExtraBold 12px
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFFFFF), // 피그마: 흰색
                letterSpacing: -0.06,
                height: 1.4, // lineHeight 16.8 / fontSize 12
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 캘린더 스타일 설정 위젯
  CalendarStyle _buildCalendarStyle() {
    return CalendarStyle(
      //캘린더의 전반적인 기본적인 스타일을 설정 가능하게 해주는 함수
      isTodayHighlighted: true,
      todayDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      defaultDecoration: BoxDecoration(
        //이건 기본적으로 평일만을 지정을 하게 된다.
        //기본적으로 선택한 날짜의 그 박스 크기를 지정을 할 수가 있다.
        //응용으로는 해당 날짜 또는 숫자 주변의 스타일을 지정할 수 가 있다.  -> 나중에 스타일링할 때 참고
        borderRadius: BorderRadius.circular(8.0), // 라운드 값 8로 변경
        color: Colors.red,
        border: Border.all(width: 1.0, color: gray100),
      ),
      weekendDecoration: BoxDecoration(
        color: Colors.blue,
        border: Border.all(width: 1.0, color: gray100),
      ),
      defaultTextStyle: CalendarTypography.calendarText.copyWith(
        color: gray1000,
      ),
      selectedDecoration: BoxDecoration(
        // 선택된 날짜 스타일 추가
        color: calendarSelectedBg, // 111111 색상 (color.dart의 gray1000)
        borderRadius: BorderRadius.circular(
          CalendarConfig.borderRadius,
        ), // 라운드 값 8, 코너 스무딩 60%
      ),
      selectedTextStyle: CalendarTypography.calendarText.copyWith(
        // 선택된 날짜 텍스트 스타일
        color: calendarSelectedText, // F7F7F7 색상
      ),
      // 이전 달/다음 달 날짜들도 같은 스타일 적용
      outsideDaysVisible: true, // 이전 달/다음 달 날짜도 표시
      outsideTextStyle: CalendarTypography.calendarText.copyWith(
        color: calendarOutsideText, // #999999와 가장 가까운 색상
      ),
      outsideDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CalendarConfig.borderRadius),
      ),
    );
  }

  // 캘린더 빌더 설정 위젯
  // 이거를 설정하고 → schedules 맵을 받아서 각 셀에 일정 데이터를 전달한다
  CalendarBuilders _buildCalendarBuilders(
    Map<DateTime, List<ScheduleData>> schedules,
  ) {
    return CalendarBuilders(
      // 평일(기본) 셀
      defaultBuilder: (context, day, focusedDay) {
        return _buildCalendarCell(
          day: day,
          backgroundColor: Colors.transparent,
          textColor: gray1000,
          daySchedules: schedules, // 일정 데이터 전달
        );
      },
      // 선택된 날짜 셀 - 색상 제거 (기본 스타일과 동일하게)
      selectedBuilder: (context, day, focusedDay) {
        return _buildCalendarCell(
          day: day,
          backgroundColor: Colors.transparent, // ⭐️ 선택된 날짜 색상 제거
          textColor: gray1000, // ⭐️ 기본 텍스트 색상 사용
          daySchedules: schedules, // 일정 데이터 전달
        );
      },
      // 오늘 날짜 셀 (빨간색으로 표시하되 기본 스타일과 동일)
      todayBuilder: (context, day, focusedDay) {
        return _buildCalendarCell(
          day: day,
          backgroundColor: calendarTodayBg, // 오늘 날짜 배경색
          textColor: calendarTodayText, // 오늘 날짜 텍스트 색상
          isCircular: false, // 기본 스타일과 동일하게 (둥근 모서리)
          daySchedules: schedules, // 일정 데이터 전달
        );
      },
      // 이전 달/다음 달 날짜 셀 (회색으로 표시하고 가운데 정렬)
      outsideBuilder: (context, day, focusedDay) {
        return _buildCalendarCell(
          day: day,
          backgroundColor: Colors.transparent, // 투명 배경
          textColor: calendarOutsideText, // #999999와 가장 가까운 색상
          daySchedules: schedules, // 일정 데이터 전달
        );
      },
    );
  }

  /// 핵심 함수 영역 ------------------------------------------------------------------------------------------------
  /// 날짜 선택 처리 함수: 사용자가 날짜를 클릭하면 DateDetailView로 이동한다
  /// 이거를 설정하고 → 선택된 날짜를 저장하고
  /// 이거를 해서 → DateDetailView로 화면 전환한다
  /// 이거는 이래서 → DB 기반이므로 별도 데이터 전달 불필요
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    print('\n========================================');
    print('📅 [홈] 날짜 선택 이벤트 발생');
    print('   → 선택된 날짜: $selectedDay');
    print('   → 포커스된 날짜: $focusedDay');

    // 1. 먼저 상태를 업데이트해서 선택된 날짜를 화면에 반영한다
    setState(() {
      this.focusedDay = selectedDay;
      this.selectedDay = selectedDay;
    });
    print('✅ [홈] 상태 업데이트 완료');

    // 2. 선택된 날짜를 정규화한다
    final normalizedDate = DateTime.utc(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );
    print('🔄 [홈] 날짜 정규화: $normalizedDate');

    // 3. ⭐️ DateDetailView로 이동 - DB 기반이므로 일정 데이터를 전달하지 않음
    // 이거는 이래서 → DateDetailView가 직접 DB에서 스트림으로 가져온다
    // 이거라면 → 로컬 상태 관리가 불필요하다
    print('🚀 [홈] DateDetailView로 이동 시작 (애플 스타일 애니메이션)');
    await Navigator.push(
      context,
      AppleExpansionRoute(
        builder: (context) => DateDetailView(selectedDate: normalizedDate),
        duration: MotionConfig.cellExpansion,
        curve: MotionConfig.appleDefault,
      ),
    );
    print('⬅️ [홈] DateDetailView에서 돌아옴');
    print('========================================\n');
  }

  // 선택된 날짜 판단 함수: 선택된 날짜인지 확인해서 선택된 날짜만 강조 표시한다
  bool _selectedDayPredicate(DateTime date) {
    // 선택된 날짜인지 확인해서 선택된 날짜만 강조 표시한다
    if (selectedDay == null) return false; // 선택된 날짜가 없으면 false를 반환한다
    return isSameDay(date, selectedDay!); // 날짜가 같으면 true를 반환해서 선택된 날짜로 표시한다
  }

  /// 스케줄 관련 유틸 함수 영역 ------------------------------------------------------------------------------------------------

  // ✅ 기존 스타일 유지: colorId 기반 색상 + 좌측 컬러바 + 좌측 정렬
  Widget _buildScheduleBox(ScheduleData schedule) {
    // 1. Schedule의 colorId를 실제 Color로 변환 (기존 로직 유지)
    final baseColor = categoryColorMap[schedule.colorId] ?? categoryGray;

    // 2. 배경색 생성: 원본 색상의 95% 밝기 (흰색에 가깝게)
    final hsl = HSLColor.fromColor(baseColor);
    final bgColor = hsl.withLightness(0.95).toColor();

    // 3. 테두리색 생성: 원본 색상의 90% 밝기 (배경보다 약간 어둡게)
    final borderColor = hsl.withLightness(0.90).toColor();

    // 4. ✅ 피그마 디자인: 18px 고정 높이 + radius 6px + 좌측 컬러바
    return Container(
      width: double.infinity,
      height: 18, // 피그마: 고정 높이 18px
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor, // 기존: colorId 기반 배경색
        borderRadius: BorderRadius.circular(6), // 피그마: radius 6px
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          // ✅ 좌측 컬러바 (2px, 원본 색상)
          Container(
            width: 2,
            height: 10,
            decoration: BoxDecoration(
              color: baseColor, // 원본 색상 사용
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          const SizedBox(width: 4),

          // ✅ 텍스트 (좌측 정렬)
          Expanded(
            child: Text(
              schedule.summary,
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF111111),
                height: 0.9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left, // 좌측 정렬
            ),
          ),
        ],
      ),
    );
  }

  /// 공통 함수 영역 ------------------------------------------------------------------------------------------------
  // 공통 캘린더 셀 위젯 함수
  // 수정된 부분: 이중 Container 구조로 터치 영역은 확장하되 디자인은 유지한다
  // 외부 Container: 터치 영역 확장 (double.infinity)
  // 내부 Container: 디자인 유지 (22px 고정)
  Widget _buildCalendarCell({
    required DateTime day, // 날짜를 받아서
    required Color backgroundColor, // 배경색을 받고
    required Color textColor, // 텍스트 색상도 받아서
    double size = CalendarConfig.cellSize, // 크기는 기본 22로 설정하고 (내부 Container용)
    bool isCircular = false, // 원형인지 확인해서
    required Map<DateTime, List<ScheduleData>> daySchedules, // 일정 맵을 받아서
  }) {
    // ⭐️ 수정된 구조:
    // 1. 외부 Container (infinity) -> 터치 영역 전체 확장
    // 2. Column으로 날짜 + 스케줄 영역 배치
    // 3. LayoutBuilder로 동적 높이 계산하여 스케줄 개수 결정

    // 이거를 설정하고 → 해당 날짜의 일정 리스트를 조회해서
    // 이거를 해서 → 날짜 키로 Map에서 검색한다
    final dateKey = DateTime(day.year, day.month, day.day);
    final schedulesForDay = daySchedules[dateKey] ?? [];

    // ⭐️ 오늘 날짜인지 확인한다 (Hero 애니메이션 태그 설정에 필요)
    final today = DateTime.now();
    final isToday =
        day.year == today.year && // 연도가 같고
        day.month == today.month && // 월이 같고
        day.day == today.day; // 일이 같으면 오늘 날짜

    // 3. ⭐️ 포커스된 월이 오늘 날짜가 있는 월이 아닌지 확인한다
    // - 이 값이 true이면 앱바에 "오늘로 돌아가기" 버튼이 표시된다
    // - 이 값이 true이고 isToday가 true이면 Hero 애니메이션을 위해 버튼과 같은 tag를 사용한다
    final isNotCurrentMonth =
        focusedDay.month != today.month || focusedDay.year != today.year;

    return Container(
      width: double.infinity, // 가로를 무한대로 설정해서 셀의 가로 전체를 차지
      height: double.infinity, // 세로를 무한대로 설정해서 셀의 세로 전체를 차지
      // 외부 Container는 투명 배경으로 설정
      color: Colors.transparent,

      // 상단에 4px 패딩 추가
      padding: const EdgeInsets.only(top: 4),

      // ⭐️ 핵심 변경: Container → Column으로 변경해서 날짜와 스케줄을 세로로 배치
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 좌측 정렬 (스케줄 박스와 +숫자용)
        children: [
          // 4. 날짜 영역 (22px 고정 크기, 중앙 정렬)
          // ✅ 피그마: 선택된 날짜(20일)는 22×22px 검은 배경 + ExtraBold 10px 흰 텍스트
          Center(
            child: Hero(
              tag: (isToday && isNotCurrentMonth)
                  ? 'today-button-${today.toString()}' // 앱바 버튼과 같은 태그
                  : 'calendar-cell-${day.toString()}', // DateDetailView와 같은 태그
              createRectTween: (begin, end) {
                return AppleStyleRectTween(begin: begin, end: end);
              },
              flightShuttleBuilder: appleStyleHeroFlightShuttleBuilder,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: size, // 가로 22px (고정 크기)
                  height: size, // 세로 22px (고정 크기)
                  decoration: BoxDecoration(
                    // ✅ 수정: 선택된 날짜도 투명 배경으로 변경 (검은색 박스 제거)
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8), // 피그마: radius 8px
                  ),
                  alignment: Alignment.center, // 날짜 숫자 중앙 정렬
                  child: Text(
                    '${day.day}', // 날짜 숫자 표시 (예: "20")
                    style: TextStyle(
                      fontFamily: 'LINE Seed JP App_TTF',
                      // ✅ 수정: 선택된 날짜도 기본 스타일 사용 (흰색 텍스트 제거)
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.045,
                      height: 0.9,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ⭐️ 스케줄 영역: 최대 5개 고정 표시
          // 이거를 설정하고 → 일정을 최대 5개까지만 표시하고
          // 이거를 해서 → 남은 일정은 +숫자로 표시한다
          // 이거는 이래서 → 모든 화면 크기에서 일관된 UI를 제공한다
          // 이거라면 → 너무 많은 일정으로 셀이 복잡해지지 않는다
          Expanded(
            child: Builder(
              builder: (context) {
                // ✅ 월뷰 일정 표시 최대 개수: 5개로 고정
                // 이유: 화면 크기에 관계없이 일정된 UI 제공
                // 조건: 5개 초과 시 +숫자로 나머지 표시
                // 결과: 깔끔하고 일관된 월뷰 표시
                const maxDisplayCount = 5;
                final displaySchedules = schedulesForDay
                    .take(maxDisplayCount)
                    .toList();
                final remainingCount =
                    schedulesForDay.length - displaySchedules.length;

                print(
                  '📅 [셀] ${day.toString().split(' ')[0]} → ${schedulesForDay.length}개 일정, ${displaySchedules.length}개 표시, $remainingCount개 숨김',
                );

                // 일정이 없으면 빈 위젯 반환
                if (schedulesForDay.isEmpty) {
                  return const SizedBox.shrink();
                }

                // 일정이 있으면 Column으로 스케줄 박스들과 +숫자를 배치
                return Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 표시할 스케줄 박스들 (최대 5개)
                      ...displaySchedules.map(
                        (schedule) => _buildScheduleBox(schedule),
                      ),

                      // ✅ 피그마: +숫자 표시 (Bold 9px, #999999)
                      if (remainingCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 2),
                          child: Text(
                            '+$remainingCount',
                            style: const TextStyle(
                              fontFamily: 'LINE Seed JP App_TTF',
                              fontSize: 9, // 피그마: Bold 9px
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF999999), // 피그마: #999999
                              letterSpacing: 0,
                              height: 1.1, // lineHeight 9.9 / fontSize 9
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ⭐️ 애플 스타일 Hero 애니메이션을 위한 커스텀 RectTween
// ─────────────────────────────────────────────────────────────────────────

/// 애플 네이티브 스타일의 부드러운 Hero 애니메이션을 구현하는 커스텀 RectTween
///
/// 작동 원리:
/// 1. begin (시작 위치/크기)과 end (종료 위치/크기)를 받는다
/// 2. lerp() 메서드가 t (0.0 ~ 1.0) 값을 받아서 중간 위치/크기를 계산한다
/// 3. MotionConfig.todayButtonHeroCurve를 적용해서 애플 스타일 가속도를 구현한다
///
/// 사용 예시:
/// - t = 0.0: begin 위치/크기 (오늘 날짜 셀, 22×22px)
/// - t = 0.5: 중간 위치/크기 (애니메이션 진행 중)
/// - t = 1.0: end 위치/크기 (앱바 버튼, 36×36px)
class AppleStyleRectTween extends RectTween {
  AppleStyleRectTween({
    required Rect? begin, // 시작 위치와 크기
    required Rect? end, // 종료 위치와 크기
  }) : super(begin: begin, end: end);

  @override
  Rect lerp(double t) {
    // 1. 애플 스타일 커브를 적용한다
    // - 원본 t 값 (0.0 ~ 1.0)을 애플 커브에 통과시켜서 자연스러운 가속도를 만든다
    // - cubic-bezier(0.25, 0.1, 0.25, 1.0): 부드러운 가속 + 정확한 안착
    final curvedT = MotionConfig.todayButtonHeroCurve.transform(t);

    // 2. 커브가 적용된 t 값으로 위치와 크기를 보간(interpolate)한다
    // - begin과 end 사이의 중간값을 계산한다
    // - curvedT가 0.0이면 begin, 1.0이면 end, 0.5면 중간값을 반환한다
    // - Rect.lerp()는 Flutter의 기본 보간 메서드로 x, y, width, height를 모두 계산한다
    return Rect.lerp(begin, end, curvedT)!;
  }
}

/// Hero 애니메이션 중 비행하는 위젯을 커스터마이징하는 빌더 함수
///
/// 파라미터 설명:
/// - flightContext: 애니메이션 중인 오버레이의 BuildContext
/// - animation: 0.0 (시작) → 1.0 (종료)로 진행되는 애니메이션 객체
/// - flightDirection: HeroFlightDirection.push (나타남) 또는 .pop (사라짐)
/// - fromHeroContext: 시작 위치의 Hero 위젯 컨텍스트 (캘린더 셀)
/// - toHeroContext: 종료 위치의 Hero 위젯 컨텍스트 (앱바 버튼)
///
/// 반환값: 애니메이션 중 표시할 위젯
Widget appleStyleHeroFlightShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  // 1. 애니메이션 방향에 따라 올바른 Hero 위젯을 선택한다
  // - push (다른 월로 이동): fromHeroContext 사용 (캘린더 셀에서 시작)
  // - pop (오늘 월로 복귀): toHeroContext 사용 (앱바 버튼에서 시작)
  final Hero toHero = toHeroContext.widget as Hero;

  // 2. 애니메이션 중 표시할 위젯을 반환한다
  // - toHero.child를 그대로 사용해서 목적지 위젯의 스타일을 유지한다
  // - Flutter의 Hero 시스템이 자동으로 위치와 크기를 애니메이션한다
  return toHero.child;
}

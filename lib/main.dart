import 'package:flutter/material.dart';
import 'package:calender_scheduler/config/app_routes.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:calender_scheduler/Database/schedule_database.dart';
import 'package:get_it/get_it.dart';

// ===================================================================
// ⭐️ Main Entry Point: 앱의 진입점
// ===================================================================
// 이거를 설정하고 → 앱 시작 전 필요한 초기화 작업을 수행하고
// 이거를 해서 → 데이터베이스, 날짜 포맷, 의존성 주입을 준비한다
// 이거는 이래서 → 앱이 안정적으로 실행되고 모든 기능이 정상 작동한다
// 이거라면 → 중앙화된 라우트 시스템으로 화면 전환을 관리한다

void main() async {
  // ===================================================================
  // 1. Flutter 프레임워크 초기화
  // ===================================================================
  WidgetsFlutterBinding.ensureInitialized();
  // 이거를 설정하고 → Flutter 프레임워크가 준비될 때까지 기다려서
  // 이거를 해서 → async 작업이 main 함수에서 안전하게 실행된다
  print('🚀 [main.dart] Flutter 프레임워크 초기화 완료');

  // ===================================================================
  // 2. 날짜 포맷 초기화 (다국어 지원)
  // ===================================================================
  await initializeDateFormatting();
  // 이거를 설정하고 → 한국어 날짜 포맷을 로드해서
  // 이거를 해서 → "10월", "월요일" 같은 한국어 표시가 가능하다
  print('📅 [main.dart] 날짜 포맷 초기화 완료 (한국어)');

  // ===================================================================
  // 3. 데이터베이스 초기화 및 의존성 주입
  // ===================================================================
  final database = AppDatabase();
  GetIt.instance.registerSingleton<AppDatabase>(database);
  // 이거를 설정하고 → AppDatabase 인스턴스를 GetIt에 등록해서
  // 이거를 해서 → 어디서든 GetIt.I<AppDatabase>()로 접근 가능하다
  // 이거는 이래서 → 데이터베이스를 전역으로 공유하고 중복 생성을 방지한다
  print('🗄️ [main.dart] 데이터베이스 초기화 및 GetIt 등록 완료');

  // ===================================================================
  // 4. 초기 데이터 로드 (앱 시작 시 오늘 일정 확인)
  // ===================================================================
  final resp = await database.getSchedulesByDate(DateTime.now());
  print('📊 [main.dart] 오늘 일정 조회 완료: ${resp.length}개');

  // ===================================================================
  // 5. 앱 실행
  // ===================================================================
  runApp(const CalendarSchedulerApp());
}

// ===================================================================
// ⭐️ Calendar Scheduler App: 앱의 루트 위젯
// ===================================================================
// 이거를 설정하고 → MaterialApp에 중앙화된 라우트 시스템을 적용해서
// 이거를 해서 → 모든 화면 전환을 일관되게 관리한다
// 이거는 이래서 → 코드 유지보수가 쉽고 라우트 추가/변경이 간단하다

class CalendarSchedulerApp extends StatelessWidget {
  const CalendarSchedulerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ===================================================================
      // 앱 기본 설정
      // ===================================================================
      title: 'Calendar Scheduler',
      theme: ThemeData(
        fontFamily: 'Gmarket Sans',
        // 추가 테마 설정 가능
      ),

      // ===================================================================
      // ⭐️ 라우트 중앙화: 모든 화면 전환을 한 곳에서 관리
      // ===================================================================
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      // 이거를 설정하고 → AppRoutes의 onGenerateRoute를 사용해서
      // 이거를 해서 → 라우트 이름으로 화면을 생성하고 애니메이션을 적용한다
      // 이거는 이래서 → Navigator.pushNamed()만으로 모든 화면 전환이 가능하다
      // 이거라면 → 라우트 경로를 수정할 때 app_routes.dart만 변경하면 된다

      // ===================================================================
      // 디버그 배너 제거 (릴리즈 빌드 시)
      // ===================================================================
      debugShowCheckedModeBanner: false,
    );
  }
}

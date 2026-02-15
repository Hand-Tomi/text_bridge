# text_bridge 아키텍처 설계 문서

> Clean Architecture 기반 5-레이어 모노레포 구조를 정의한다.

---

## 1. 전체 아키텍처 개요

### 모노레포 디렉토리 구조

```
text_bridge/
├── apps/                              # 애플리케이션 레이어
│   └── text_bridge/                   # 메인 앱 (iOS/Android/macOS)
├── packages/                          # 공통 패키지
│   ├── domain/                        # 도메인 레이어 (비즈니스 엔티티, Repository 인터페이스)
│   ├── system/                        # 시스템 레이어 (API 통신, 로컬 저장소, 환경 설정)
│   ├── data/                          # 데이터 레이어 (Repository 구현, 예외 변환)
│   ├── design_system/                 # 디자인 시스템 레이어 (UI 컴포넌트, 테마, Template)
│   └── presentation/                  # 프레젠테이션 레이어 (Page, ViewModel, Mapper, Router)
├── docs/                              # 프로젝트 문서
├── pubspec.yaml                       # Dart workspace 루트
├── Makefile                           # 빌드 스크립트
└── .fvmrc                             # Flutter 버전 관리 (FVM)
```

### 5-레이어 구조

| 레이어 | 패키지 | 역할 |
|--------|--------|------|
| **Domain** | `packages/domain` | 비즈니스 엔티티, Repository 인터페이스, 예외 클래스. 어떤 패키지에도 의존하지 않는 순수 비즈니스 로직 |
| **System** | `packages/system` | API 통신(Dio+Retrofit), 로컬 저장소, 환경/Flavor 설정. 외부 시스템과의 접점 |
| **Data** | `packages/data` | Repository 구현, DTO → Domain 모델 변환, ApiException → DomainException 변환 |
| **Design System** | `packages/design_system` | Atomic Design UI 컴포넌트, 테마, Template, UiState, UI Model |
| **Presentation** | `packages/presentation` | Page, ViewModel, Mapper, GoRouter 라우팅 |
| **Apps** | `apps/text_bridge` | DI 설정, 앱 진입점, Flavor별 설정, 전역 에러 핸들링 |

---

## 2. 패키지 의존관계

### 의존관계 다이어그램

```
                        ┌───────────────────┐
                        │  apps/text_bridge  │  (DI 설정, 앱 진입점)
                        └─────────┬─────────┘
                  ┌───────────────┼───────────────┐
                  ▼               ▼               ▼
         ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
         │ presentation │ │     data     │ │    system    │
         └──────┬───────┘ └──────┬───────┘ └──────────────┘
                │                │
           ┌────┴────┐     ┌────┴────┐
           ▼         ▼     ▼         ▼
    ┌──────────────┐ ┌──────────────┐
    │design_system │ │    domain    │
    └──────────────┘ └──────────────┘
```

### 의존관계 규칙표

| 패키지 | 의존 가능 | 의존 금지 |
|--------|----------|----------|
| **domain** | 없음 (독립) | 모든 패키지 |
| **system** | 없음 (독립) | domain, presentation, design_system, data |
| **data** | domain, system | presentation, design_system |
| **design_system** | 없음 (독립) | domain, presentation, data, system |
| **presentation** | domain, design_system | data, system |
| **apps/\*** | 모든 패키지 (DI 설정) | - |

> **핵심 원칙**: 의존성은 항상 안쪽(domain) 방향으로만 흐른다. 외부 레이어가 내부 레이어에 의존하지만, 그 반대는 금지된다.

---

## 3. 각 레이어 상세

### 3.1 Domain 레이어 (`packages/domain/`)

비즈니스 엔티티, Repository 인터페이스, 예외 클래스를 정의한다. 어떤 패키지에도 의존하지 않는 순수한 비즈니스 로직 레이어.

#### 디렉토리 구조

```
packages/domain/lib/
├── domain.dart              # 배럴 파일
├── model/                   # 비즈니스 모델 (Freezed)
│   └── result.dart          # Result<T> 타입 (성공/실패 래퍼)
├── repository/              # Repository 인터페이스 + 추상 Provider
└── exception/               # 예외 계층 구조
    └── domain_exception.dart
```

#### 핵심 패턴

**Result 타입** — 모든 Repository 메서드의 반환 타입:

```dart
@freezed
sealed class Result<T extends Object?> with _$Result<T> {
  const factory Result.success(T data) = Success<T>;
  const factory Result.failure(DomainException exception) = Failure<T>;
  const factory Result.successVoid() = SuccessVoid<T>;
}
```

**예외 계층 구조:**

```
DomainException (기저 클래스)
├── NetworkException              # 인터넷 연결 에러
├── TimeoutException              # 타임아웃 에러
├── UnauthorizedException         # 인증 에러
├── UnexpectedStatusCodeException # 예상 외 HTTP 상태코드
└── UnknownException              # 알 수 없는 에러
```

**Repository 인터페이스 + DI용 Provider:**

```dart
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  throw UnimplementedError('앱 기동 시 오버라이드하세요');
}

abstract interface class AuthRepository {
  Future<Result<UserType>> login({...});
  Future<Result<void>> logout();
}
```

---

### 3.2 System 레이어 (`packages/system/`)

API 통신(Retrofit + Dio), 로컬 저장소, 환경 설정(Flavor)을 담당한다.

#### 디렉토리 구조

```
packages/system/lib/
├── system.dart                    # 배럴 파일
├── config/                        # FlavorConfig 설정
├── exception/                     # ApiException 계층
│   └── api_exception.dart
├── api/                           # API 관련 구현
│   ├── dto/                       # Data Transfer Objects
│   ├── client/                    # Retrofit 클라이언트
│   └── interceptor/               # Dio 인터셉터
└── local_data_sources/            # 로컬 저장소 인터페이스
```

#### 핵심 패턴

**ApiException 계층:**

```
ApiException (기저 클래스)
├── NoInternetApiException     # 인터넷 연결 에러
├── TimeoutApiException        # 타임아웃
├── BadResponseApiException    # 불량 응답 (400, 403, 404, 500 등)
├── CancelledApiException      # 요청 취소
├── UnauthorizedApiException   # 401 인증 에러
└── UnknownErrorApiException   # 알 수 없는 에러
```

**FlavorConfig:**

```dart
enum EnvironmentType { dev, prod }

class FlavorConfig {
  const FlavorConfig({required this.flavor, required this.isDebugMode});
  final EnvironmentType flavor;
  final bool isDebugMode;

  String get baseUrl => switch (flavor) {
    EnvironmentType.dev  => 'https://dev-api.example.com',
    EnvironmentType.prod => 'https://api.example.com',
  };
}
```

**LocalDataSources 인터페이스:**

```dart
abstract interface class LocalDataSources {
  Future<void> saveAccessToken(String value);
  Future<String?> getAccessToken();
  Future<void> clearSessionData();
  Future<void> clearAllData();
}
```

---

### 3.3 Data 레이어 (`packages/data/`)

Domain의 Repository 인터페이스를 구현하고, System의 ApiException을 Domain의 DomainException으로 변환한다.

#### 디렉토리 구조

```
packages/data/lib/
├── data.dart                          # 배럴 파일
└── src/
    ├── repository/                    # Repository 구현
    ├── exception/                     # 예외 변환
    │   └── convert_to_domain_exception.dart
    └── util/
        └── result_extension.dart      # Exception → Result 변환
```

#### 핵심 패턴

**예외 변환 (System → Domain):**

```dart
DomainException convertToDomainException(Exception raw) {
  return switch (raw) {
    DomainException _          => raw,
    TimeoutApiException _      => TimeoutException(error: raw),
    NoInternetApiException _   => NetworkException(error: raw),
    CancelledApiException _    => IgnorableException(error: raw),
    UnauthorizedApiException e => UnauthorizedException(error: raw, message: e.message),
    BadResponseApiException e  => UnexpectedStatusCodeException(
        error: raw, message: e.message, statusCode: e.statusCode),
    _                          => UnknownException(error: raw),
  };
}
```

**Result Extension:**

```dart
extension ExceptionToResult on Exception {
  Result<T> toResult<T extends Object?>() {
    return Result<T>.failure(convertToDomainException(this));
  }
}
```

**Repository 구현 + 팩토리 함수:**

```dart
// 팩토리 함수 (DI용)
AuthRepository createAuthRepository(Ref ref) => AuthRepositoryImpl(
      authService: ref.watch(authServiceProvider),
      localDataSources: ref.watch(localDataSourcesProvider),
    );

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<Result<UserType>> login({...}) async {
    try {
      final response = await authService.login(...);
      return Result.success(response.toDomain());
    } on Exception catch (e) {
      return e.toResult();
    }
  }
}
```

---

### 3.4 Design System 레이어 (`packages/design_system/`)

Atomic Design 기반 UI 컴포넌트, 테마, Template, UiState, UI Model을 정의한다.

#### 디렉토리 구조

```
packages/design_system/lib/
├── app_colors.dart            # 색상 정의
├── app_typography.dart        # 텍스트 스타일 정의
├── app_theme.dart             # 테마 설정
├── atoms/                     # Atom 배럴 파일
├── templates/                 # Template 배럴 파일
└── src/
    ├── atoms/                 # 최소 단위 UI 컴포넌트
    ├── molecules/             # Atom 조합 중간 컴포넌트
    ├── organisms/             # 복합 컴포넌트
    └── templates/             # 화면별 Template + UiState + UI Model
```

#### Atomic Design 계층

| 계층 | 설명 | import 가능 | import 금지 |
|------|------|------------|------------|
| **Atoms** | 최소 단위 (버튼, 텍스트, 이미지) | Flutter 프레임워크만 | molecules, organisms, templates |
| **Molecules** | Atom 조합 중간 컴포넌트 | atoms | organisms, templates |
| **Organisms** | 복합 컴포넌트 | atoms, molecules | templates |
| **Templates** | 화면별 전체 구조 | atoms, molecules, organisms | - |

#### 테마 시스템

```dart
final class AppColors {
  static const Color primary = Color(0xFF...);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textPrimary = Color(0xFF26221F);
  // ...
}

final class AppTypography {
  static const TextStyle headingL = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w600, height: 1.3,
  );
  static const TextStyle bodyM = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.3,
  );
  // ...
}
```

---

### 3.5 Presentation 레이어 (`packages/presentation/`)

Page, ViewModel, Mapper, GoRouter 라우팅을 담당한다.

#### 디렉토리 구조

```
packages/presentation/lib/
├── presentation.dart          # 배럴 파일
├── ui/
│   ├── utils/
│   │   └── page_state.dart    # PageState<TUiState, TAction> 래퍼
│   └── {기능그룹}/
│       └── {화면}/
│           ├── {화면}_page.dart               # Page (ConsumerWidget)
│           ├── {화면}_page_view_model.dart     # ViewModel + Action
│           └── {화면}_page_mapper.dart         # Domain → UI 변환
├── extras/                    # GoRouter extra 파라미터
│   └── {기능그룹}/
│       └── {화면}_page_extra.dart
└── app_router.dart            # GoRouter 라우팅 정의
```

#### PageState 래퍼

```dart
class PageState<TUiState, TAction> {
  PageState(this.ui, this.action);
  final TUiState ui;       // UI 렌더링 상태
  final TAction action;    // 네비게이션/다이얼로그 등 UI 부수효과 신호

  PageState<TUiState, TAction> copyWith({
    TUiState? ui,
    TAction? action,
  }) {
    return PageState<TUiState, TAction>(
      ui ?? this.ui,
      action ?? this.action,
    );
  }
}
```

#### AppRoutes

```dart
enum AppRoutes {
  home,
  // ...
}
```

---

### 3.6 Apps 레이어 (`apps/text_bridge/`)

DI 설정, 앱 진입점, Flavor별 설정, 전역 에러 핸들링을 담당한다.

#### 디렉토리 구조

```
apps/text_bridge/lib/
├── main.dart                  # 공통 진입점 (DI 설정, 초기화)
├── main_dev.dart              # Dev Flavor 진입점
├── main_prod.dart             # Production Flavor 진입점
├── app.dart                   # App 위젯 (GoRouter, 에러 핸들링)
└── app_view_model.dart        # 앱 전역 상태/에러 관리
```

#### DI 초기화 흐름

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer(
    overrides: [
      flavorConfigProvider.overrideWithValue(flavorConfig),
      // Repository DI (domain 인터페이스 → data 구현체)
      authRepositoryProvider.overrideWith(createAuthRepository),
      // ...
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}
```

#### 전역 에러 핸들링

```dart
Future<void> _errorHandling(Object? error, StackTrace? stack) async {
  switch (error) {
    case UnauthorizedException _:
      state = AppAction.goToLoginPage();
    case TimeoutException _:
      state = AppAction.showTimeoutErrorDialog();
    case NetworkException _:
      state = AppAction.showNetworkErrorDialog();
    case final DomainException e:
      state = AppAction.showErrorDialog(message: e.message);
    case final Exception e:
      state = AppAction.showErrorDialog();
  }
}
```

---

## 4. 기술 스택

| 카테고리 | 기술 | 용도 |
|---------|------|------|
| **언어** | Dart / Flutter 3.41.1 | 크로스 플랫폼 개발 |
| **상태 관리** | Riverpod (riverpod_annotation) | DI + 상태 관리 |
| **라우팅** | GoRouter | 선언적 라우팅 + 딥링크 |
| **불변 데이터** | Freezed + freezed_annotation | Model, UiState, Action |
| **JSON 직렬화** | json_serializable + json_annotation | DTO 변환 |
| **HTTP** | Dio + Retrofit | API 통신 |
| **코드 생성** | build_runner | Freezed, Riverpod, Retrofit |
| **모노레포 관리** | Melos | 패키지 간 의존성 관리, 스크립트 |
| **Flutter 버전** | FVM | Flutter SDK 버전 관리 |
| **로컬 저장소** | flutter_secure_storage, shared_preferences | 토큰, 설정 저장 |

---

## 5. 데이터 흐름

### 요청 방향 (사용자 인터랙션 → API)

```
[사용자 인터랙션]
    ↓  Template에서 콜백 호출 (UiState의 콜백 함수)
[Page]  (presentation)
    ↓  ref.read(viewModelProvider.notifier).onXxx()
[ViewModel]  (presentation)
    ↓  ref.read(xxxRepositoryProvider).method()
[Repository 인터페이스]  (domain)
    ↓  DI로 주입된 구현체 호출
[Repository 구현]  (data)
    ↓  service.apiCall(Request)
[Service / Retrofit Client]  (system)
    ↓  Dio 인터셉터 체인
[HTTP API]
```

### 응답 방향 (API → 화면 렌더링)

```
[HTTP API 응답]
    ↓  JSON
[Retrofit Client]  (system) → DTO (Response 객체)
    ↓
[Repository 구현]  (data) → DTO → Domain Model 변환
    ↓  Result.success(domainModel)
[ViewModel]  (presentation) → Mapper로 UI Model 변환
    ↓  state = PageState(UiState(...), Action.none())
[Page]  (presentation) → ref.watch로 UiState 감시
    ↓  Template(uiState: uiState)
[Template]  (design_system) → atoms/molecules/organisms 조합
    ↓
[화면 렌더링]
```

### 에러 흐름

```
[HTTP 에러]
    ↓  DioException
[ErrorInterceptor]  (system) → ApiException 변환
    ↓
[Repository 구현]  (data) → catch → e.toResult() → DomainException 변환
    ↓  Result.failure(domainException)
[ViewModel]  (presentation) → result.when(failure: ...) 처리
    ├─ 로컬 처리: Action 발행 → Page에서 다이얼로그 표시
    └─ 전역 위임: throw error → 전역 에러 핸들러 (AppViewModel)
        ↓  DomainException 타입별 분기
[다이얼로그 표시 / 화면 이동]
```

---

## 6. 페이지 아키텍처

### Page / ViewModel / UiState / Template / Mapper / Action 패턴

각 화면은 다음 6개의 구성 요소로 이루어진다:

| 구성 요소 | 패키지 | 역할 |
|----------|--------|------|
| **Page** | presentation | `ConsumerWidget`. Action 감시(`ref.listen`) + UiState 감시(`ref.watch`) |
| **ViewModel** | presentation | `@riverpod` 클래스. 비즈니스 로직, 상태 관리, Repository 호출 |
| **Action** | presentation | Freezed union. 네비게이션/다이얼로그 등 UI 부수효과 신호 |
| **Mapper** | presentation | 정적 메서드. Domain 모델 → UI Model 변환 |
| **UiState** | design_system | Freezed 불변 클래스. Template의 렌더링 데이터 + 콜백 |
| **Template** | design_system | `StatelessWidget`. UiState를 받아 순수 UI 렌더링 |

### Page (ConsumerWidget)

```dart
class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({super.key, required this.extra});
  final EventDetailPageExtra extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Action 감시: UI 부수효과 처리
    ref.listen(
      eventDetailPageViewModelProvider(eventId: extra.eventId)
          .select((value) => value.action),
      (_, next) {
        if (!context.mounted) return;
        next.when(
          none: () {},
          pop: () => context.pop(),
          showErrorDialog: (message) => showErrorDialog(context, message),
        );
        ref.read(...notifier).onFinishedAction();
      },
    );

    // 2. UiState 감시: Template에 전달
    final uiState = ref.watch(
      eventDetailPageViewModelProvider(eventId: extra.eventId)
          .select((value) => value.ui),
    );

    return EventDetailPageTemplate(uiState: uiState);
  }
}
```

### ViewModel

```dart
@riverpod
class EventDetailPageViewModel extends _$EventDetailPageViewModel {
  @override
  PageState<EventDetailPageUiState, EventDetailPageAction> build({
    required String eventId,
  }) {
    Future.microtask(_fetchData);  // 비동기 초기화

    return PageState(
      EventDetailPageUiState(
        isLoading: true,
        onBackButton: _onBackButton,     // 메서드 참조 (람다 금지)
        onRefresh: _onRefresh,
      ),
      EventDetailPageAction.none(),
    );
  }

  void onFinishedAction() {
    state = state.copyWith(action: EventDetailPageAction.none());
  }
}
```

### Action (Freezed union)

```dart
@freezed
class EventDetailPageAction with _$EventDetailPageAction {
  factory EventDetailPageAction.none() = _None;
  factory EventDetailPageAction.pop() = _Pop;
  factory EventDetailPageAction.showErrorDialog({String? message}) = _ShowErrorDialog;
}
```

### UiState

```dart
@freezed
class EventDetailPageUiState with _$EventDetailPageUiState {
  factory EventDetailPageUiState({
    required bool isLoading,
    @Default(false) bool hasError,
    // 콜백은 반드시 메서드 참조 사용 (람다 금지 - Freezed == 비교 문제)
    required VoidCallback onBackButton,
    Future<void> Function()? onRefresh,
  }) = _EventDetailPageUiState;
}
```

### Template

```dart
class EventDetailPageTemplate extends StatelessWidget {
  const EventDetailPageTemplate({super.key, required this.uiState});
  final EventDetailPageUiState uiState;

  @override
  Widget build(BuildContext context) {
    // 비즈니스 로직 없음. UiState의 데이터를 보여주고 콜백을 연결할 뿐.
    return Scaffold(
      body: uiState.isLoading
          ? const LoadingIndicator()
          : _buildContent(context),
    );
  }
}
```

### Mapper

```dart
class EventDetailPageMapper {
  EventDetailPageMapper._();  // 인스턴스화 방지

  static EventDetailUi map(EventDetail model) {
    return EventDetailUi(
      id: model.id,
      title: model.title,
      formattedDate: _formatDate(model.date),
    );
  }
}
```

### Action 처리 흐름

```
1. ViewModel: state = state.copyWith(action: SomeAction())
2. Page: ref.listen → next.when(...) 패턴 매칭으로 처리
3. Page: ref.read(...notifier).onFinishedAction()
4. ViewModel: action을 none()으로 리셋
→ 각 Action이 정확히 1회만 처리됨을 보장
```

### 파일 구조도

```
# presentation 패키지
packages/presentation/lib/ui/
├── {기능그룹}/
│   └── {화면}/
│       ├── {화면}_page.dart               # Page
│       ├── {화면}_page_view_model.dart     # ViewModel + Action
│       └── {화면}_page_mapper.dart         # Mapper

# design_system 패키지
packages/design_system/lib/
├── src/templates/
│   └── {기능그룹}/
│       └── {화면}/
│           ├── {화면}_page_template.dart   # Template
│           ├── {화면}_page_ui_state.dart   # UiState
│           └── {모델명}_ui.dart            # UI Model
├── templates/                              # Export 배럴 파일
│   └── {화면}_template.dart
```

---

## 7. 새 페이지 추가 체크리스트

| # | 패키지 | 작업 | 파일 경로 |
|---|--------|------|------------|
| 0 | `domain` | Domain 모델 정의 (필요 시) | `lib/model/{모델명}.dart` |
| 1 | `design_system` | UiState 정의 | `src/templates/{기능}/{화면}/{화면}_page_ui_state.dart` |
| 2 | `design_system` | UI Model 정의 (필요 시) | `src/templates/{기능}/{화면}/{모델명}_ui.dart` |
| 3 | `design_system` | Template 정의 | `src/templates/{기능}/{화면}/{화면}_page_template.dart` |
| 4 | `design_system` | Export 배럴 파일 추가 | `templates/{화면}_template.dart` |
| 5 | `presentation` | Extra 정의 (파라미터 필요 시) | `extras/{기능}/{화면}_page_extra.dart` |
| 6 | `presentation` | Mapper 정의 | `ui/{기능}/{화면}/{화면}_page_mapper.dart` |
| 7 | `presentation` | ViewModel + Action 정의 | `ui/{기능}/{화면}/{화면}_page_view_model.dart` |
| 8 | `presentation` | Page 정의 | `ui/{기능}/{화면}/{화면}_page.dart` |
| 9 | `presentation` | GoRouter 라우트 등록 | `app_router.dart` |
| 10 | - | 코드 생성 실행 | `make build` (Freezed / Riverpod) |

### 판단 기준

- **UI Model이 필요한 경우**: Domain 모델의 데이터를 UI용으로 변환해야 할 때
- **Extra가 필요한 경우**: 이전 화면에서 ID 등의 파라미터를 전달받아야 할 때
- **Simple vs Family Provider**: 파라미터 없이 단일 인스턴스 → Simple, 파라미터로 인스턴스 구분 → Family

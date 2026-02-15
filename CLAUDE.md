# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

text_bridge는 Dart Workspace와 Melos를 사용하는 Flutter 모노레포입니다. GitHub 레포지토리: `Hand-Tomi/text_bridge`. Flutter 버전은 FVM(3.41.1)으로 관리합니다. 5-레이어 Clean Architecture를 따르며, 현재 초기 설정 단계로 아키텍처 문서는 작성되었으나 패키지는 아직 생성되지 않은 상태입니다.

## 주요 명령어

```bash
make setup          # FVM 설정 + Melos 부트스트랩 + build_runner (최초 설정)
make build          # build_runner 실행 (Freezed, Riverpod, Retrofit 코드 생성)
make get            # 모든 패키지 의존성 설치
make analyze        # 모든 패키지 Dart 분석기 실행
```

FVM을 사용하므로 Flutter 직접 명령 시 `fvm flutter` 접두사 사용:
```bash
fvm flutter run
fvm flutter test
```

단일 테스트 실행:
```bash
cd apps/text_bridge && fvm flutter test test/경로/테스트_파일.dart
```

CI 검사 (PR 머지 전 통과 필수):
```bash
dart analyze --fatal-infos
dart format --set-exit-if-changed .
dart test --coverage=coverage
```

## 모노레포 구조

```
apps/text_bridge/       # 메인 Flutter 앱 (진입점, DI 설정)
packages/               # 공유 패키지 (domain, system, data, design_system, presentation)
docs/                   # 아키텍처 및 git flow 문서
```

## 5-레이어 아키텍처

자세한 내용은 `docs/architecture.md` 참고. 레이어 간 의존관계 규칙은 엄격히 준수해야 한다:

| 레이어 | 패키지 | 의존 가능 대상 |
|--------|--------|----------------|
| Domain | `packages/domain` | 없음 (순수 비즈니스 로직) |
| System | `packages/system` | 없음 (외부 시스템 경계) |
| Data | `packages/data` | domain, system |
| Design System | `packages/design_system` | 없음 (순수 UI 컴포넌트) |
| Presentation | `packages/presentation` | domain, design_system |
| Apps | `apps/*` | 모든 패키지 (DI 연결) |

의존성은 항상 안쪽(domain) 방향으로만 흐른다. 이 규칙을 절대 위반하지 않는다.

## 핵심 아키텍처 패턴

- **Result<T>**: 모든 Repository 메서드는 `Result<T>`를 반환 (성공/실패 래퍼, Freezed sealed class)
- **예외 변환**: System `ApiException` → Data 레이어에서 → Domain `DomainException`으로 변환
- **PageState<UiState, Action>**: 각 페이지는 UiState(렌더링 데이터 + 콜백)와 Action(네비게이션/다이얼로그 등 일회성 부수효과)으로 구성
- **Page/ViewModel/Template 분리**: Page(ConsumerWidget, 상태 연결) → ViewModel(Riverpod, 비즈니스 로직) → Template(StatelessWidget, design_system 내 순수 UI)
- **Mapper**: Domain 모델 → UI 모델 변환 정적 메서드, presentation에 위치
- **Atomic Design**: design_system은 Atoms → Molecules → Organisms → Templates 계층 구조
- **UiState 콜백**: 반드시 메서드 참조 사용, 람다 사용 금지 (Freezed 동등성 비교 문제)
- **Action 흐름**: ViewModel이 Action 설정 → Page가 listen하여 처리 → `onFinishedAction()` 호출로 `none()`으로 리셋

## 기술 스택

- **상태 관리 / DI**: Riverpod (riverpod_annotation)
- **라우팅**: GoRouter
- **불변 데이터**: Freezed
- **HTTP**: Dio + Retrofit
- **코드 생성**: build_runner (어노테이션 클래스 변경 후 `make build` 실행)
- **모노레포 관리**: Melos
- **Flutter 버전 관리**: FVM

## Git 워크플로우

- **기본 브랜치**: `develop` (feature/fix PR 대상)
- **안정 브랜치**: `main` (릴리스 전용)
- **브랜치 네이밍**: `{type}/{이슈번호}-{slug}` (예: `feature/12-add-clipboard-manager`)
- **타입**: `feature/*`, `fix/*`, `hotfix/*` (main 기점), `chore/*`
- **커밋**: Conventional Commits v1.0.0 — `type(scope): description`
- **Scope**: 모노레포 패키지명 사용 (예: `feat(clipboard): add paste formatting`)
- **PR 본문**: `closes #N`으로 관련 GitHub Issue 자동 닫기 포함 필수
- **모든 코드 변경은 GitHub Issue에서 시작**

## 새 페이지 추가 체크리스트

새 페이지를 추가할 때 아래 순서로 파일을 생성한다:
1. Domain 모델 (필요 시) → `packages/domain/lib/model/`
2. UiState → `packages/design_system/lib/src/templates/{기능}/{화면}/`
3. UI Model (필요 시) → 같은 디렉토리
4. Template → 같은 디렉토리 + `templates/`에 배럴 export 추가
5. Extra (파라미터 필요 시) → `packages/presentation/lib/extras/`
6. Mapper → `packages/presentation/lib/ui/{기능}/{화면}/`
7. ViewModel + Action → 같은 디렉토리
8. Page → 같은 디렉토리
9. `app_router.dart`에 라우트 등록
10. `make build` 실행

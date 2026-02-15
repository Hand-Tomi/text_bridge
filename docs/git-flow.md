# Git Flow 설계 문서

> text_bridge 모노레포(apps/, packages/, docs/)의 브랜치 전략, 커밋 컨벤션, CI/CD 워크플로우를 정의한다.
> GitHub 레포지토리: `Hand-Tomi/text_bridge`

---

## 1. 브랜치 전략

| 브랜치      | 용도                    | 기점      | 머지 대상          |
| ----------- | ----------------------- | --------- | ------------------ |
| `main`      | 안정 릴리스             | -         | -                  |
| `develop`   | 통합/개발 (기본 브랜치) | `main`    | `main`             |
| `feature/*` | 새 기능                 | `develop` | `develop`          |
| `fix/*`     | 버그 수정               | `develop` | `develop`          |
| `hotfix/*`  | 긴급 프로덕션 수정      | `main`    | `main` + `develop` |
| `chore/*`   | 유지보수, 설정          | `develop` | `develop`          |

### 브랜치 네이밍

Issue 번호를 접두사로 포함하여 추적성을 확보한다.

```
feature/12-add-clipboard-manager
fix/7-text-encoding-error
hotfix/15-crash-on-paste
chore/3-update-dependencies
```

---

## 2. 이슈 기반 개발

모든 코드 변경은 GitHub Issue에서 시작한다.

### 원칙

- 코드 변경은 반드시 관련 GitHub Issue가 존재해야 한다.
- Issue의 내용을 기반으로 브랜치 type과 이름을 결정한다.
- PR이 기본 브랜치에 머지되면 관련 Issue가 자동으로 닫힌다.

### Issue → 브랜치 매핑

Issue의 유형을 확인하고 적절한 브랜치 type을 선택한다.

| Issue 유형 | 브랜치 type | 브랜치 예시                        |
| ---------- | ----------- | ---------------------------------- |
| 기능 요청  | `feature/*` | `feature/12-add-clipboard-manager` |
| 버그 리포트 | `fix/*`    | `fix/7-text-encoding-error`        |
| 긴급 수정  | `hotfix/*`  | `hotfix/15-crash-on-paste`         |
| 유지보수   | `chore/*`   | `chore/3-update-dependencies`      |

### Issue 자동 닫기

PR 본문에 [GitHub 키워드](https://docs.github.com/en/issues/tracking-your-work-with-issues/using-issues/linking-a-pull-request-to-an-issue)를 사용하여 Issue를 참조한다.

```
closes #12
fixes #7
```

PR이 대상 브랜치(`develop` 또는 `main`)에 머지되면 참조된 Issue가 자동으로 닫힌다.

---

## 3. 워크플로우 흐름

### 일반 개발 흐름

```
Issue ──▶ feature/* ──PR──▶ develop ──릴리스 PR──▶ main ──▶ git tag v1.x.x
Issue ──▶ fix/*     ──PR──▶ develop
Issue ──▶ chore/*   ──PR──▶ develop
```

1. GitHub Issue를 확인하고 작업할 Issue를 선택한다.
2. Issue 유형에 따라 `develop`에서 브랜치를 생성한다. (예: `feature/12-add-clipboard-manager`)
3. 작업 완료 후 `develop`으로 PR 생성 (본문에 `closes #이슈번호` 포함)
4. CI 통과 + 코드 리뷰 후 머지 → Issue 자동 닫힘
5. 릴리스 시점에 `develop` → `main` 릴리스 PR 생성
6. 머지 후 `main`에서 `git tag vX.Y.Z` → push

### 긴급 수정 흐름

```
Issue ──▶ main ──▶ hotfix/* ──PR──▶ main ──▶ git tag vX.Y.Z+1
                              └─PR──▶ develop
```

1. GitHub Issue를 확인하고 긴급 수정이 필요한 Issue를 선택한다.
2. `main`에서 `hotfix/*` 브랜치 생성 (예: `hotfix/15-crash-on-paste`)
3. 수정 후 `main`으로 PR 생성 (본문에 `closes #이슈번호` 포함) → 머지 → Issue 자동 닫힘
4. 동일 변경을 `develop`에도 PR로 머지
5. `main`에서 패치 버전 태그 생성

---

## 4. 커밋 컨벤션

[Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) 형식을 따른다.

```
type(scope): description
```

### Conventional Commits Specification

> 이 문서에서 사용하는 "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", "OPTIONAL"은 [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt)에 따라 해석한다.

1. 커밋은 반드시(MUST) `feat`, `fix` 등의 명사로 구성된 type을 접두사로 가져야 하며, 그 뒤에 선택적(OPTIONAL) scope, 선택적 `!`, 그리고 필수(REQUIRED) 콜론과 공백이 와야 한다.
2. `feat` type은 커밋이 애플리케이션 또는 라이브러리에 새로운 기능을 추가할 때 반드시(MUST) 사용해야 한다.
3. `fix` type은 커밋이 버그 수정을 나타낼 때 반드시(MUST) 사용해야 한다.
4. scope는 type 뒤에 제공될 수 있다(MAY). scope는 반드시(MUST) 코드베이스의 영역을 설명하는 명사를 괄호로 감싸야 한다. 예: `fix(parser):`
5. description은 type/scope 접두사 뒤의 콜론과 공백 바로 다음에 와야 한다(MUST). description은 코드 변경의 짧은 요약이다. 예: *fix: array parsing issue when multiple spaces were contained in string*
6. 짧은 description 뒤에 더 긴 커밋 body를 제공할 수 있다(MAY). body는 반드시(MUST) description 뒤 한 줄을 비운 후 시작해야 한다.
7. 커밋 body는 자유 형식이며, 줄바꿈으로 구분된 여러 단락으로 구성될 수 있다(MAY).
8. 하나 이상의 footer를 body 뒤 한 줄을 비운 후 제공할 수 있다(MAY). 각 footer는 반드시(MUST) 단어 토큰, `:<space>` 또는 `<space>#` 구분자, 그리고 문자열 값으로 구성되어야 한다 (git trailer 규칙에서 착안).
9. footer의 토큰은 공백 대신 `-`를 반드시(MUST) 사용해야 한다. 예: `Acked-by` (이는 여러 단락으로 구성된 body와 footer 섹션을 구분하는 데 도움이 된다). 단, `BREAKING CHANGE`는 예외적으로 토큰으로 사용될 수 있다(MAY).
10. footer의 값은 공백과 줄바꿈을 포함할 수 있으며(MAY), 다음 유효한 footer 토큰/구분자 쌍이 관찰되면 파싱이 반드시(MUST) 종료되어야 한다.
11. Breaking change는 커밋의 type/scope 접두사 또는 footer의 항목으로 반드시(MUST) 표시되어야 한다.
12. footer에 포함하는 경우, breaking change는 반드시(MUST) 대문자 `BREAKING CHANGE`, 콜론, 공백, 그리고 설명으로 구성되어야 한다. 예: *BREAKING CHANGE: environment variables now take precedence over config files*
13. type/scope 접두사에 포함하는 경우, breaking change는 `:` 바로 앞에 `!`로 반드시(MUST) 표시되어야 한다. `!`를 사용하면 footer 섹션에서 `BREAKING CHANGE:`를 생략할 수 있으며(MAY), 커밋 description이 breaking change를 설명하는 데 사용된다(SHALL).
14. `feat`와 `fix` 외의 type도 커밋 메시지에 사용할 수 있다(MAY). 예: *docs: update ref docs.*
15. Conventional Commits를 구성하는 정보 단위는 `BREAKING CHANGE`(반드시 대문자여야 함)를 제외하고 대소문자를 구분하지 않아야 한다(MUST NOT).
16. `BREAKING-CHANGE`는 footer에서 토큰으로 사용될 때 `BREAKING CHANGE`와 동의어여야 한다(MUST).

### Types

| Type       | 설명                           |
| ---------- | ------------------------------ |
| `feat`     | 새로운 기능                    |
| `fix`      | 버그 수정                      |
| `docs`     | 문서 변경                      |
| `style`    | 코드 포맷팅 (동작 변경 없음)   |
| `refactor` | 리팩토링 (기능/버그 변경 없음) |
| `test`     | 테스트 추가/수정               |
| `chore`    | 빌드, 설정 등 기타 변경        |
| `perf`     | 성능 개선                      |
| `ci`       | CI 설정 변경                   |
| `build`    | 빌드 시스템, 외부 의존성 변경  |

### Scope (선택)

모노레포 패키지명 또는 앱명을 사용한다.

```
feat(clipboard): add paste formatting
fix(apps/mobile): resolve crash on startup
chore(packages/core): update dependencies
```

### Breaking Changes

```
feat!: change clipboard API signature

BREAKING CHANGE: ClipboardManager.paste() now returns Future<String?>
```

---

## 5. 버전 관리

### Semantic Versioning

```
MAJOR.MINOR.PATCH
```

- **MAJOR**: 호환되지 않는 API 변경
- **MINOR**: 하위 호환 기능 추가
- **PATCH**: 하위 호환 버그 수정

### 태그 방식

수동으로 태그를 생성하고 push한다.

```bash
git tag v1.0.0
git push origin v1.0.0
```

태그 push 시 릴리스 워크플로우(`release.yml`)가 자동 실행된다.

---

## 6. 브랜치 보호 규칙

### `main` 브랜치

- PR을 통해서만 머지 가능 (직접 push 금지)
- CI 워크플로우 통과 필수
- Force push 금지

### `develop` 브랜치

- CI 워크플로우 통과 필수
- Force push 금지

---

## 7. PR 템플릿

`.github/pull_request_template.md`에 배치한다.

```markdown
## 변경 사항

<!-- 이 PR에서 변경된 내용을 간단히 설명해 주세요 -->

-

## 변경 유형

- [ ] feat: 새로운 기능
- [ ] fix: 버그 수정
- [ ] docs: 문서 변경
- [ ] style: 코드 포맷팅
- [ ] refactor: 리팩토링
- [ ] test: 테스트
- [ ] chore: 기타
- [ ] perf: 성능 개선
- [ ] ci: CI 설정 변경
- [ ] build: 빌드 시스템 변경

## 테스트

- [ ] 기존 테스트 통과 확인
- [ ] 새로운 테스트 추가 (해당 시)
- [ ] 수동 테스트 완료

## 관련 이슈

<!-- closes #이슈번호 -->
```

---

## 검증 체크리스트

1. [ ] `.github/pull_request_template.md` 생성
2. [ ] `feature/*` 브랜치 → `develop` PR → CI 동작 확인
3. [ ] `develop` → `main` 릴리스 PR → 태그 → 릴리스 워크플로우 동작 확인
4. [ ] 브랜치 보호 규칙 적용 확인

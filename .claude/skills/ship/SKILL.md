---
name: ship
description: 현재 변경 사항을 분석하고, GitHub Issue 생성 → 브랜치 생성 → 커밋 → CI 검사 → PR 생성까지 한 번에 수행한다.
argument-hint: "[변경 사항 설명 또는 issue 번호]"
disable-model-invocation: true
context: fork
allowed-tools: Bash(git *), Bash(gh *), Bash(fvm *), Bash(dart *), Bash(make *), Read, Edit, Write, AskUserQuestion
---

# Ship Skill

변경 사항을 분석하고 Issue 생성 → 브랜치 생성 → 커밋 → CI 검사 → PR 생성까지 전체 워크플로우를 한 번에 수행한다.
프로젝트의 git-flow 규칙(`docs/git-flow.md`)을 따른다.

## Phase 0: 사전 검사

1. 아래 명령어를 **병렬**로 실행한다:
   - `git status` — 변경/추적되지 않은 파일 확인 (절대 `-uall` 플래그 사용 금지)
   - `git diff` — 비스테이징 변경 내용 확인
   - `git diff --staged` — 스테이징된 변경 내용 확인
   - `git log --oneline -10` — 최근 커밋 스타일 참고
   - `git branch --show-current` — 현재 브랜치 확인

2. **변경 사항이 없으면** (untracked, modified, staged 파일이 모두 없으면) 사용자에게 안내하고 **즉시 중단**한다.

3. **`$ARGUMENTS` 처리**:
   - 숫자만 (`42`) 또는 `#` 접두사 숫자 (`#42`) → 기존 Issue 번호로 간주한다.
     - `gh issue view <번호> --json number,title,body,labels` 로 Issue 정보를 가져온다.
     - 유효하지 않으면 사용자에게 안내하고 **즉시 중단**한다.
   - 문자열 → Issue 제목 및 커밋 메시지 작성 시 참고용으로 사용한다.
   - 없음 → 변경 내용을 분석하여 자동으로 생성한다.

4. **라우트 결정** — 현재 브랜치에 따라 분기한다:

   | 현재 브랜치 | 라우트 | 실행 Phase |
   |------------|--------|-----------|
   | `main`, `develop`, detached HEAD | **Full Route** | 0 → 1 → 2 → 3 → 4 → 5 |
   | `feature/*`, `fix/*`, `hotfix/*`, `chore/*` | **Branch Route** | 0 → 3 → 4 → 5 |
   | 기타 | `AskUserQuestion`으로 사용자에게 선택 | — |

   - **Branch Route**에서는 브랜치명에서 이슈 번호를 추출한다: `type/번호-slug` → `#번호`
     - 예: `feature/12-add-clipboard-manager` → `#12`
     - 이슈 번호가 없으면 `$ARGUMENTS`에서 추출을 시도한다.
   - **Full Route**에서 `$ARGUMENTS`로 기존 Issue 번호가 주어졌으면 Phase 1의 Issue 생성을 건너뛰고, 해당 Issue 정보를 사용하여 Phase 2로 진행한다.

## Phase 1: Issue 생성 (Full Route만)

1. 변경 사항(`git diff`, `git status`)을 분석하여 Issue 제목과 본문을 작성한다.
   - `$ARGUMENTS`가 문자열이면 이를 참고한다.

2. Issue 라벨을 자동 매핑한다:
   - 새 기능 → `enhancement`
   - 버그 수정 → `bug`
   - 문서 → `documentation`
   - 기타 → 라벨 없음

3. `AskUserQuestion`으로 Issue 제목과 라벨을 확인한다. 옵션:
   - "이대로 생성" (제목과 라벨을 표시)
   - "제목 수정" (사용자가 직접 입력)

4. Issue를 생성한다:
   ```bash
   gh issue create --title "<제목>" --body "<본문>" --label "<라벨>"
   ```

5. 생성된 Issue 번호를 기록한다 → 이후 Phase에서 사용한다.

## Phase 2: 브랜치 생성 (Full Route만)

1. Issue 라벨을 기반으로 **브랜치 타입**을 결정한다:

   | Label | 브랜치 타입 |
   |-------|-----------|
   | `enhancement`, `feature` | `feature/*` |
   | `bug` | `fix/*` |
   | `hotfix`, `urgent`, `critical` | `hotfix/*` |
   | 그 외 / 라벨 없음 | `chore/*` |

2. 브랜치 이름을 생성한다: `type/이슈번호-slug`
   - slug: Issue 제목에서 생성 — 소문자, 공백은 `-`로 치환, 특수문자 제거, 적절한 길이로 제한
   - 예: `feature/12-add-clipboard-manager`

3. 현재 변경 사항을 stash한다:
   ```bash
   git stash push -m "ship: WIP for #<이슈번호>"
   ```

4. `git fetch origin`을 실행한다.

5. 분기 기점에서 새 브랜치를 생성한다:
   - `hotfix/*` → `origin/main`에서 분기
   - 그 외 → `origin/develop`에서 분기
   ```bash
   git checkout -b <브랜치명> origin/<기점>
   ```

6. stash를 복원한다:
   ```bash
   git stash pop
   ```
   - **충돌 발생 시** `git stash drop`을 실행하지 말고, 사용자에게 충돌 파일을 안내하고 **즉시 중단**한다.

## Phase 3: 커밋

1. **파일 개별 스테이징**: 변경된 파일을 하나씩 `git add <파일>` 으로 스테이징한다.
   - **절대 `git add .` 또는 `git add -A`를 사용하지 않는다.**
   - `.env`, `.env.*`, `credentials.json`, `*.key`, `*.pem`, `*.p12`, `*.jks`, `serviceAccountKey.json` 등 민감 파일은 자동으로 제외한다.
   - 민감 파일이 감지되면 사용자에게 경고 메시지를 출력한다.

2. 스테이징된 변경 사항을 분석하여 **커밋 메시지**를 작성한다 — Conventional Commits v1.0.0 형식:

   ```
   type(scope): description
   ```

   ### Type
   | Type | 설명 |
   |------|------|
   | `feat` | 새로운 기능 |
   | `fix` | 버그 수정 |
   | `docs` | 문서 변경 |
   | `style` | 코드 포맷팅 (동작 변경 없음) |
   | `refactor` | 리팩토링 (기능/버그 변경 없음) |
   | `test` | 테스트 추가/수정 |
   | `chore` | 빌드, 설정 등 기타 변경 |
   | `perf` | 성능 개선 |
   | `ci` | CI 설정 변경 |
   | `build` | 빌드 시스템, 외부 의존성 변경 |

   ### Scope
   모노레포 패키지명 또는 앱명을 사용한다.

   ### 규칙
   - description은 소문자로 시작하고, 마침표를 붙이지 않는다.
   - 변경의 "why"에 초점을 맞추고, "what"은 간결하게 작성한다.
   - 영어로 작성한다.
   - `$ARGUMENTS`가 주어지면 이를 참고한다.

3. `AskUserQuestion`으로 커밋 메시지를 확인한다. 옵션:
   - "이대로 커밋" (메시지를 표시)
   - "메시지 수정" (사용자가 직접 입력)

4. 커밋을 생성한다:
   ```bash
   git commit -m "$(cat <<'EOF'
   type(scope): description

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
   EOF
   )"
   ```

5. 커밋 후 `git status`로 성공 여부를 확인한다.

6. **pre-commit hook 실패 시**:
   - 이전 커밋을 amend하지 않는다 (hook 실패 시 커밋이 생성되지 않았으므로).
   - 문제를 수정하고, 다시 스테이징한 후, **새로운 커밋**을 생성한다.

## Phase 4: CI 검사

1. `fvm dart analyze --fatal-infos`를 실행한다.
   - 분석 오류가 있으면 코드를 수정한다.

2. `fvm dart format --set-exit-if-changed .`를 실행한다.
   - 포맷 오류가 있으면 `fvm dart format .`으로 자동 수정한다.

3. 수정이 발생했으면:
   - 수정된 파일을 개별 `git add <파일>`로 스테이징한다.
   - 아래 형식으로 커밋을 생성한다:
     ```bash
     git commit -m "$(cat <<'EOF'
     style: fix formatting and analysis issues

     Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
     EOF
     )"
     ```

4. 수정 후 `fvm dart analyze --fatal-infos`를 다시 실행하여 통과를 확인한다.
   - 여전히 실패하면 사용자에게 안내하고 **즉시 중단**한다.

5. `fvm flutter test`를 실행한다.
   - 테스트 실패 시 사용자에게 실패한 테스트 목록을 안내하고 **즉시 중단**한다.

## Phase 5: Push + PR 생성

### 5-1. Rebase

1. `git fetch origin`을 실행한다.
2. **대상 브랜치 결정**:
   - `hotfix/*` → `main`
   - 그 외 → `develop`
3. `git merge-base --is-ancestor origin/<대상 브랜치> HEAD`로 rebase 필요 여부를 판단한다.
   - 대상 브랜치의 최신 커밋이 이미 현재 브랜치의 조상이면 rebase 불필요.
4. rebase가 필요하면 `git rebase origin/<대상 브랜치>`를 실행한다.
5. **충돌 발생 시**:
   - 충돌 파일을 읽고 해결을 시도한다.
   - 해결 후 `git add <파일>` → `git rebase --continue`를 실행한다.
   - **자동 해결이 불가능하면** `git rebase --abort`를 실행하고 사용자에게 수동 해결을 안내한 후 **즉시 중단**한다.

### 5-2. Push

1. 트래킹 브랜치가 없으면: `git push -u origin <현재 브랜치>`
2. 트래킹 브랜치가 있으면 (rebase 후): `git push --force-with-lease`
3. push 실패 시 사용자에게 안내하고 **즉시 중단**한다.

### 5-3. 기존 PR 확인

1. `gh pr view --json url,state`로 현재 브랜치에 이미 열린 PR이 있는지 확인한다.
2. 이미 열린 PR이 있으면:
   - PR URL을 출력하고 "기존 PR에 push 완료"로 **완료** 처리한다.
   - 새 PR을 생성하지 않고 종료한다.

### 5-4. PR 생성

1. `git log origin/<대상 브랜치>..HEAD --oneline`으로 커밋 내역을 분석한다.

2. `.github/pull_request_template.md` 형식에 맞춰 PR 본문을 구성한다:

   - **`## 변경 사항`**: 커밋 내역을 분석하여 bullet point로 요약한다.
   - **`## 변경 유형`**: 브랜치 타입에 맞는 항목을 `[x]`로 체크한다.
     - `feature/*` → `feat` 체크
     - `fix/*` → `fix` 체크
     - `hotfix/*` → `fix` 체크
     - `chore/*` → `chore` 체크
     - 커밋 내역에 다른 type이 포함되어 있으면 해당 항목도 추가로 체크한다.
   - **`## 테스트`**: 실행한 검사 항목을 체크한다.
     - `fvm flutter test` 통과 → `[x] 기존 테스트 통과 확인`
   - **`## 관련 이슈`**: 이슈 번호가 있으면 `closes #이슈번호`를 작성한다.

3. PR 제목: 커밋 내역을 분석하여 변경 사항을 요약하는 간결한 제목을 작성한다 (70자 이내).
   - `$ARGUMENTS`가 주어지면 이를 참고하여 제목과 본문을 보강한다.

4. PR을 생성한다:
   ```bash
   gh pr create --base <대상 브랜치> --title "<제목>" --body "$(cat <<'EOF'
   <PR 본문>
   EOF
   )"
   ```

5. 생성된 PR URL을 출력한다.

### 5-5. hotfix 후속 작업 안내

- `hotfix/*` 브랜치인 경우에만 아래 안내를 출력한다:
  - "`main` 머지 후 동일 변경을 `develop`에도 반영해야 합니다. `develop` 대상 PR을 별도로 생성하세요."

## 금지 사항

- `git add .` 또는 `git add -A` 금지 — 파일을 반드시 개별 스테이징한다.
- `git push --force` 금지 (`--force-with-lease`만 허용)
- `main`/`develop`에서 직접 커밋/push 금지 (반드시 브랜치를 먼저 생성)
- `reset --hard`, `checkout .`, `restore .`, `clean -f`, `branch -D` 등 파괴적 명령어 금지
- `--no-verify`, `--no-gpg-sign` 등 hook 건너뛰기 금지
- rebase 충돌 자동 해결 불가 시 임의 해결 금지 — 반드시 `git rebase --abort` 후 사용자에게 안내
- git config 변경 금지
- `.env`, 자격 증명 파일 등 민감 파일을 자동 스테이징 금지
- amend 금지 (pre-commit hook 실패 시 새 커밋 생성)

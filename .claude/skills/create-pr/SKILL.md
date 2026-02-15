---
name: create-pr
description: 현재 브랜치를 rebase하고, CI 검사를 실행하고, GitHub PR을 생성한다.
argument-hint: "[추가 컨텍스트 또는 PR 설명]"
disable-model-invocation: true
context: fork
allowed-tools: Bash(git *), Bash(gh *), Bash(dart *), Bash(fvm *), Bash(make *), Read, Edit, Write
---

# Create PR Skill

현재 작업 브랜치를 rebase하고, CI 검사(analyze + format)를 실행하고, GitHub PR을 생성한다.
프로젝트의 git-flow 규칙(`docs/git-flow.md`)을 따른다.

## 절차

### 1단계: 브랜치 검증

1. `git branch --show-current`로 현재 브랜치를 확인한다.
2. `main` 또는 `develop`이면 **즉시 중단**하고 사용자에게 작업 브랜치로 전환하라고 안내한다.
3. 브랜치 이름이 `feature/*`, `fix/*`, `hotfix/*`, `chore/*` 패턴인지 확인한다.
   - 패턴에 맞지 않으면 경고 메시지를 출력하고 `AskUserQuestion`으로 사용자에게 계속 진행할지 확인한다.
4. **대상 브랜치 결정**:
   - `hotfix/*` → `main`
   - 그 외 (`feature/*`, `fix/*`, `chore/*` 등) → `develop`
5. 브랜치 이름에서 **이슈 번호 추출**: `type/번호-slug` 형식에서 번호를 추출한다.
   - 예: `feature/12-add-clipboard-manager` → `#12`
   - 이슈 번호가 없으면 `$ARGUMENTS`에서 추출을 시도하고, 없으면 `관련 이슈` 섹션을 비워둔다.

### 2단계: 기존 PR 확인

1. `gh pr view --json url,state`로 현재 브랜치에 이미 열린 PR이 있는지 확인한다.
2. 이미 열린 PR이 있으면:
   - PR URL을 출력한다.
   - `AskUserQuestion`으로 사용자에게 확인한다: push만 할지(3단계~5단계 실행), 새 PR을 만들지, 중단할지.

### 3단계: Rebase

1. `git fetch origin`을 실행한다.
2. `git merge-base --is-ancestor origin/<대상 브랜치> HEAD`로 rebase 필요 여부를 판단한다.
   - 대상 브랜치의 최신 커밋이 이미 현재 브랜치의 조상이면 rebase 불필요.
3. rebase가 필요하면 `git rebase origin/<대상 브랜치>`를 실행한다.
4. **충돌 발생 시**:
   - 충돌 파일을 읽고 해결을 시도한다.
   - 해결 후 `git add <파일>` → `git rebase --continue`를 실행한다.
   - **자동 해결이 불가능하면** `git rebase --abort`를 실행하고 사용자에게 수동 해결을 안내한 후 **즉시 중단**한다.

### 4단계: CI 검사 (analyze + format)

1. `dart analyze --fatal-infos`를 실행한다.
   - 분석 오류가 있으면 코드를 수정한다.
2. `dart format --set-exit-if-changed .`를 실행한다.
   - 포맷 오류가 있으면 `dart format .`으로 자동 수정한다.
3. 수정이 발생했으면:
   - 수정된 파일을 `git add`로 스테이징한다.
   - 아래 형식으로 커밋을 생성한다:
     ```bash
     git commit -m "$(cat <<'EOF'
     style: fix formatting and analysis issues

     Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
     EOF
     )"
     ```
4. 수정 후 `dart analyze --fatal-infos`를 다시 실행하여 통과를 확인한다.
   - 여전히 실패하면 사용자에게 안내하고 **즉시 중단**한다.

### 5단계: Push

1. 트래킹 브랜치가 없으면: `git push -u origin <현재 브랜치>`
2. 트래킹 브랜치가 있으면 (rebase 후): `git push --force-with-lease`
3. push 실패 시 사용자에게 안내하고 **즉시 중단**한다.

### 6단계: PR 생성

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
     - `dart analyze` 통과 → `[x] 기존 테스트 통과 확인`
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

## 금지 사항

- `git push --force` 금지 (`--force-with-lease`만 허용)
- `main`/`develop`에서 직접 PR 생성 금지
- `reset --hard`, `checkout .`, `restore .`, `clean -f`, `branch -D` 등 파괴적 명령어 금지
- `--no-verify`, `--no-gpg-sign` 등 hook 건너뛰기 금지
- rebase 충돌 자동 해결 불가 시 임의 해결 금지 — 반드시 `git rebase --abort` 후 사용자에게 안내
- git config 변경 금지

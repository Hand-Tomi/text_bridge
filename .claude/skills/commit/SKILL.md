---
name: commit
description: Git commit following the project's Conventional Commits convention defined in docs/git-flow.md. Use when the user asks to commit, make a commit, or save changes.
argument-hint: "[commit message or description of changes]"
disable-model-invocation: true
context: fork
allowed-tools: Bash(git status*), Bash(git diff*), Bash(git log*), Bash(git commit*)
---

# Git Commit Skill

프로젝트의 git-flow 규칙(`docs/git-flow.md`)에 따라 커밋을 생성한다.

## 절차

1. **변경 사항 파악**: 아래 명령어를 **병렬**로 실행한다.
   - `git status` — 변경/추적되지 않은 파일 확인 (절대 `-uall` 플래그 사용 금지)
   - `git diff --staged` — 스테이징된 변경 내용 확인 (커밋 대상)
   - `git log --oneline -10` — 최근 커밋 스타일 참고

2. **커밋 메시지 작성**: Conventional Commits v1.0.0 형식을 따른다.

   ```
   type(scope): description
   ```

   ### Type (필수)
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

3. **커밋 메시지 규칙**:
   - description은 소문자로 시작하고, 마침표를 붙이지 않는다.
   - 변경의 "why"에 초점을 맞추고, "what"은 간결하게 작성한다.
   - 영어로 작성한다.
   - `$ARGUMENTS`가 주어지면 이를 참고하여 메시지를 작성한다.

4. **커밋** (staged 파일만 커밋한다):
   - **절대 `git add`를 실행하지 않는다.** 사용자가 이미 스테이징한 파일만 커밋 대상이다.
   - `git diff --staged`로 스테이징된 변경 사항이 없으면 커밋하지 않고, 사용자에게 먼저 `git add`로 파일을 스테이징하라고 안내한다.
   - `.env`, 자격 증명 파일 등 민감한 파일이 스테이징되어 있으면 경고하고 커밋을 중단한다.
   - 커밋 메시지는 반드시 HEREDOC 형식으로 전달한다:
     ```bash
     git commit -m "$(cat <<'EOF'
     type(scope): description

     Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
     EOF
     )"
     ```
   - 커밋 후 `git status`로 성공 여부를 확인한다.

5. **pre-commit hook 실패 시**:
   - 이전 커밋을 amend하지 않는다 (hook 실패 시 커밋이 생성되지 않았으므로).
   - 문제를 수정하고, 다시 스테이징한 후, **새로운 커밋**을 생성한다.

## 금지 사항

- git config 변경 금지
- `--force`, `reset --hard`, `checkout .`, `restore .`, `clean -f`, `branch -D` 등 파괴적 명령어 금지
- `--no-verify`, `--no-gpg-sign` 등 hook 건너뛰기 금지
- `push` 금지 (사용자가 명시적으로 요청한 경우에만)
- amend 금지 (사용자가 명시적으로 요청한 경우에만)

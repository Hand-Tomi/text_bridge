---
name: start-issue
description: GitHub Issue를 읽고, 브랜치를 생성하고, 작업 계획을 수립한다.
argument-hint: "[issue-number]"
disable-model-invocation: true
context: fork
allowed-tools: Bash(gh *), Bash(git *)
---

# Start Issue Skill

GitHub Issue를 기반으로 브랜치를 생성한다.
프로젝트의 git-flow 규칙(`docs/git-flow.md`)을 따른다.

## 절차

1. **Issue 읽기**: 아래 명령어를 실행하여 Issue 정보를 파악한다.
   ```bash
   gh issue view $ARGUMENTS --json number,title,body,labels,assignees
   ```
   - Issue 번호, 제목, 본문, 라벨을 확인한다.
   - `$ARGUMENTS`가 없거나 유효하지 않으면 사용자에게 Issue 번호를 요청한다.

2. **브랜치 타입 결정**: Issue 라벨을 기반으로 브랜치 타입을 자동 매핑한다.

   | Label                        | 브랜치 타입 |
   | ---------------------------- | ----------- |
   | `enhancement`, `feature`     | `feature/*` |
   | `bug`                        | `fix/*`     |
   | `hotfix`, `urgent`, `critical` | `hotfix/*` |
   | 그 외 / 라벨 없음            | `chore/*`   |

   - 매핑이 모호한 경우(예: 라벨이 여러 타입에 해당) `AskUserQuestion`으로 사용자에게 확인한다.

3. **브랜치 생성**: `docs/git-flow.md`의 네이밍 규칙을 따른다.
   - 먼저 `git fetch origin`을 실행한다.
   - 브랜치 이름: `type/이슈번호-slug` (Issue 제목에서 slug 생성)
     - slug: 소문자, 공백은 `-`로 치환, 특수문자 제거, 적절한 길이로 제한
     - 예: `feature/12-add-clipboard-manager`
   - 분기 기점:
     - `hotfix/*` → `origin/main`에서 분기
     - 그 외 → `origin/develop`에서 분기
   - 브랜치 생성 후 자동으로 checkout한다.

4. **결과 출력**: 메인 에이전트가 후속 작업을 수행할 수 있도록 아래 정보를 반환한다.
   - Issue 번호, 제목, 본문 (전문)
   - 생성된 브랜치 이름
   - 라벨 목록
   - **후속 작업 안내**: "이 Issue의 작업 계획을 수립하려면 EnterPlanMode를 호출하세요."

## 후속 작업 (메인 에이전트)

이 skill이 완료되면 메인 에이전트는 반환된 Issue 정보를 기반으로 `EnterPlanMode`를 호출하여 작업 계획을 수립한다.

## 금지 사항

- git config 변경 금지
- `--force`, `reset --hard`, `checkout .`, `restore .`, `clean -f`, `branch -D` 등 파괴적 명령어 금지
- `push` 금지 (사용자가 명시적으로 요청한 경우에만)
- 이미 존재하는 브랜치를 덮어쓰기 금지 (동일 이름의 브랜치가 있으면 사용자에게 확인)

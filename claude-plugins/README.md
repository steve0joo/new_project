# QuickPoll 품질 도구 플러그인

`.claude/`에 있던 코드리뷰 스킬·서브에이전트·pre-commit 훅을 **각각 독립 Claude Code 플러그인**으로
패키징하고, 로컬에서 설치할 수 있도록 마켓플레이스(`quickpoll-quality-tools`)로 묶었습니다.

## 세 플러그인

| 플러그인              | 내용                              | 설치 후 사용                                        |
| --------------------- | --------------------------------- | --------------------------------------------------- |
| `code-review-skill`   | 코드리뷰 방법론 스킬              | `code-review-skill:comprehensive-code-review` 스킬  |
| `code-reviewer-agent` | 읽기 전용 코드리뷰 서브에이전트   | `code-reviewer` 에이전트 (위 스킬을 로드해 동작)    |
| `precommit-checks`    | `git commit` 차단형 PreToolUse 훅 | prettier + 인라인 JS 문법 실패 시 커밋 차단(exit 2) |

> **의존성:** `code-reviewer-agent` 는 `code-review-skill` 의 스킬을 로드합니다. 에이전트
> 플러그인만 설치하면 방법론 스킬을 찾지 못하니 **둘 다 설치**하세요(매니페스트의
> `dependencies` 에도 명시되어 있습니다).

## 설치

```bash
# 1) 이 폴더를 마켓플레이스로 추가
/plugin marketplace add ./claude-plugins

# 2) 필요한 플러그인 설치 (@뒤는 마켓플레이스 이름)
/plugin install code-review-skill@quickpoll-quality-tools
/plugin install code-reviewer-agent@quickpoll-quality-tools
/plugin install precommit-checks@quickpoll-quality-tools
```

설치 후 `/plugin list` 로 활성화를 확인할 수 있습니다.

## 디렉터리 구조

```
claude-plugins/
├── .claude-plugin/marketplace.json        # 마켓플레이스 카탈로그(세 플러그인 등록)
├── code-review-skill/
│   ├── .claude-plugin/plugin.json
│   └── skills/comprehensive-code-review/SKILL.md
├── code-reviewer-agent/
│   ├── .claude-plugin/plugin.json
│   └── agents/code-reviewer.md
└── precommit-checks/
    ├── .claude-plugin/plugin.json
    ├── hooks/hooks.json                    # ${CLAUDE_PLUGIN_ROOT}/scripts/... 참조
    └── scripts/pre-commit-checks.sh
```

## 기존 `.claude/` 설정과의 관계

이 저장소의 `.claude/` 에는 동일한 스킬/에이전트/훅이 **프로젝트 로컬**로 이미 들어 있습니다.
플러그인은 설치(`/plugin install`) 전에는 활성화되지 않으므로 파일이 공존해도 충돌하지 않습니다.
플러그인으로 전환하기로 했다면, 중복 등록을 피하기 위해 `.claude/skills/comprehensive-code-review/`,
`.claude/agents/code-reviewer.md`, `.claude/hooks/` + `.claude/settings.json` 의 훅 항목을 제거해도
됩니다(원하실 때 정리해 드릴게요).

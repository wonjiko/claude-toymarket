# Claude Context

이 저장소는 Claude Code 플러그인을 모아두는 개인 장터.

## 레퍼런스 우선

새로운 것을 만들기 전에 반드시 공식 레퍼런스를 먼저 확인하라.

| 작업 | 레퍼런스 |
|------|----------|
| Claude 플러그인 | `~/.claude/plugins/marketplaces/claude-plugins-official/` |
| Claude Code 기능 | https://docs.anthropic.com/en/docs/claude-code |
| MCP 서버 | https://github.com/anthropics/anthropic-quickstarts |
| Claude API | https://docs.anthropic.com/en/api |

참고 소스는 Anthropic 공식만 허용:
- https://docs.anthropic.com/
- https://github.com/anthropics/

## 작업 시 참고

- 플러그인 추가할 때: `plugins/` 아래에 폴더 만들고 `plugin.json` 작성
- 목록 갱신할 때: `catalog.json` 수정
- 마케팅 언어 금지. 솔직하게.
- 각 플러그인은 "왜 존재하는지"와 "언제 쓰면 안 되는지" 명시

## 톤

- 캐주얼하지만 기술적으로 정확하게
- 튜토리얼은 요청 시에만
- 과잉 설계 금지

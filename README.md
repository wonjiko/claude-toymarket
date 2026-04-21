# claude-toymarket

개인용 Claude Code 플러그인 장터.
실험적이고, 손으로 만들고, 한 사람이 관리함.

## 원칙

- 이건 장난감이지, 엔터프라이즈 제품이 아님
- 완성도보다 명확함
- 재미는 허용. 과잉 설계는 불허
- 고장나면 그게 정상
- 안정성, 성능, 유지보수에 대한 약속 없음

## 구조

```
claude-toymarket/
├── .claude-plugin/marketplace.json   # 플러그인 카탈로그
├── plugins/                          # 플러그인 모음
│   ├── dice/                         # 결정장애를 위한 주사위
│   ├── skills-toybox/                # 범용 유틸리티 skill 모음
│   ├── matryoshka-plugin/            # 플러그인/컴포넌트 생성 도구
│   ├── mcp-manager/                  # MCP 서버 자동 관리
│   └── ppt-designer/                 # HTML 프레젠테이션 생성
├── templates/                        # 새 플러그인 템플릿
└── CLAUDE.md                         # Claude용 컨텍스트
```

## 설치

1. Claude Code에서 `/plugin` 실행
2. **Marketplace** 탭 → **Add new marketplace** 선택
3. `wonjiko/claude-toymarket` 입력

끝.

## 플러그인 목록

| 플러그인 | 설명 | 주요 기능 |
|----------|------|-----------|
| dice | 결정장애를 위한 주사위 | `/dice` |
| skills-toybox | 범용 유틸리티 skill 모음 | commit, code-review, make-pr, retrospect, reflection, command-validator |
| matryoshka-plugin | 플러그인/컴포넌트 생성 도구 | skill-creator, agent-creator |
| mcp-manager | MCP 서버 자동 관리 | 세션 시작 시 MCP 상태 체크 |
| ppt-designer | HTML 프레젠테이션 생성 | ppt-designer |

## 사용 예시

```bash
# dice - 주사위 굴리기 (slash command)
/dice 점심 메뉴: 짜장면, 짬뽕, 볶음밥

# mcp-manager - MCP 상태 확인 (slash command)
/mcp-check

# ppt-designer - 프레젠테이션 생성 (skill, 자연어로 트리거)
# "프레젠테이션 만들어줘", "PPT 만들어줘" 등으로 호출
```

## 플러그인 추가하기

1. `plugins/[name]/` 아래에 폴더 생성
2. `.claude-plugin/plugin.json` 작성 (`templates/plugin.json` 참고)
3. `.claude-plugin/marketplace.json`에 등록

## 면책

여기 있는 모든 건 언제든 바뀌거나 사라질 수 있음.

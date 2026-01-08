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
├── plugins/          # 플러그인 모음
├── templates/        # 새 플러그인 템플릿
├── catalog.json      # 플러그인 목록
└── CLAUDE.md         # Claude용 컨텍스트
```

## 사용법

### 마켓플레이스 등록
```bash
# 로컬에서
claude plugin marketplace add /path/to/claude-toymarket

# 또는 GitHub에서
claude plugin marketplace add wonjiko/claude-toymarket
```

### 플러그인 설치
```bash
# 목록 확인
claude plugin search claude-toymarket

# 설치
claude plugin install dice@claude-toymarket
claude plugin install typical-process@claude-toymarket
```

### 플러그인 사용
```bash
# dice - 주사위 굴리기
/dice 점심 메뉴: 짜장면, 짬뽕, 볶음밥

# typical-process - 세션 시작
/typical-process:start add-feature
```

## 플러그인 추가하기

1. `plugins/` 아래에 폴더 생성
2. `plugin.json` 작성 (템플릿 참고)
3. `catalog.json`에 등록

## 면책

여기 있는 모든 건 언제든 바뀌거나 사라질 수 있음.

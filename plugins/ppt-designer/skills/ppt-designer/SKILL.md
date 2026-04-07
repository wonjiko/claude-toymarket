---
name: ppt-designer
description: This skill should be used when the user asks to design, create, or generate a presentation (PPT, slides, slide deck) from a topic outline or research document. Triggers on requests like "프레젠테이션 만들어줘", "슬라이드 디자인해줘", "PPT 만들어줘", "make a presentation", "design slides". Reads topic-outline.md (or similar structured markdown) and generates a polished HTML presentation using reveal.js.
version: 0.1.0
---

# PPT Designer

topic-outline.md를 기반으로 세련된 HTML 프레젠테이션을 생성하는 skill.

## 워크플로우

### 1. 소스 파일 확인

현재 디렉토리에서 `topic-outline.md` 파일을 읽는다. 파일이 없으면 사용자에게 먼저 토픽 리서치를 진행하도록 안내한다.

### 2. 아웃라인 파싱

topic-outline.md에서 다음 구조를 추출한다:
- **메타 정보**: 제목, 목적, 대상 청중
- **Executive Summary**: 핵심 포인트 리스트
- **서브토픽들**: 각각의 핵심 메시지, 키포인트, 데이터/통계, 슬라이드 구성 제안

### 3. 프레젠테이션 생성

reveal.js CDN을 사용한 단일 HTML 파일로 프레젠테이션을 생성한다.

#### 슬라이드 구조

```
1. 타이틀 슬라이드 (제목 + 날짜 + 목적)
2. 목차 슬라이드
3. Executive Summary 슬라이드 (핵심 포인트)
4~N. 서브토픽별 슬라이드 그룹:
   - 서브토픽 타이틀 슬라이드 (핵심 메시지)
   - 키포인트 슬라이드 (bullet points)
   - 데이터/통계 슬라이드 (수치 강조)
N+1. 정리/요약 슬라이드
N+2. 참고 자료 슬라이드
```

#### HTML 템플릿

아래 구조를 기반으로 프레젠테이션 HTML을 생성한다:

```html
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{프레젠테이션 제목}</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@5.1.0/dist/reveal.css">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/reveal.js@5.1.0/dist/theme/black.css">
    <style>
        /* 커스텀 스타일 - 아래 디자인 가이드라인 참고 */
    </style>
</head>
<body>
    <div class="reveal">
        <div class="slides">
            <!-- 슬라이드 섹션들 -->
        </div>
    </div>
    <script src="https://cdn.jsdelivr.net/npm/reveal.js@5.1.0/dist/reveal.js"></script>
    <script>
        Reveal.initialize({
            hash: true,
            slideNumber: true,
            transition: 'slide',
            backgroundTransition: 'fade'
        });
    </script>
</body>
</html>
```

### 4. 디자인 가이드라인

#### 컬러 & 테마
- 다크 테마 기본 (배경: #0a0a1a ~ #1a1a2e 계열 다크 네이비/블랙)
- 포인트 컬러: 토픽에 어울리는 비비드 accent color 1개 선택 (예: AI 관련이면 시안/네온블루 #00d4ff, 비즈니스면 골드 #f0c040 등)
- 그라디언트 활용: 배경이나 강조 요소에 미묘한 그라디언트 적용
- CSS 변수로 컬러 시스템 관리

#### 타이포그래피
- Google Fonts CDN 사용
- 제목: 볼드하고 임팩트 있는 폰트 (예: Pretendard, Noto Sans KR Black, Montserrat Bold)
- 본문: 가독성 좋은 클린한 폰트
- 핵심 수치나 통계는 매우 크게 (3rem+) 표시
- 한국어 지원 폰트 필수 포함

#### 레이아웃
- 슬라이드당 핵심 메시지 1개에 집중
- bullet point는 최대 4-5개
- 데이터 슬라이드: 큰 숫자 + 짧은 설명 레이아웃
- 충분한 여백 (padding: 2rem+)
- 타이틀 슬라이드는 풀스크린 임팩트

#### 시각 효과
- reveal.js fragment 애니메이션으로 bullet point 순차 등장
- 서브토픽 전환 시 섹션 구분 명확하게 (배경색 변화 or 대형 타이틀)
- 수치/통계에 CSS counter 애니메이션 또는 큰 폰트 강조
- subtle한 box-shadow, border-radius 활용

#### 슬라이드 유형별 패턴

**타이틀 슬라이드:**
```html
<section data-background-gradient="linear-gradient(135deg, #0a0a1a 0%, #1a1a3e 100%)">
    <h1 style="font-size: 2.5em;">{제목}</h1>
    <p style="opacity: 0.7;">{부제 또는 날짜}</p>
</section>
```

**키포인트 슬라이드:**
```html
<section>
    <h2>{서브토픽 제목}</h2>
    <ul>
        <li class="fragment">{포인트 1}</li>
        <li class="fragment">{포인트 2}</li>
        <li class="fragment">{포인트 3}</li>
    </ul>
</section>
```

**데이터 강조 슬라이드:**
```html
<section>
    <div style="font-size: 4em; font-weight: bold; color: var(--accent);">{수치}</div>
    <p>{수치 설명}</p>
    <small style="opacity: 0.5;">{출처}</small>
</section>
```

**인용/핵심 메시지 슬라이드:**
```html
<section>
    <blockquote style="font-size: 1.5em; border-left: 4px solid var(--accent);">
        {핵심 메시지}
    </blockquote>
</section>
```

### 5. 출력

- 파일명: `presentation.html`
- 현재 디렉토리에 저장
- 생성 후 사용자에게 `open presentation.html`로 열 수 있음을 안내

### 6. 품질 체크리스트

생성 후 확인:
- [ ] 모든 서브토픽이 슬라이드에 포함되었는지
- [ ] 한국어 폰트가 정상 로드되는지
- [ ] reveal.js CDN이 올바른지
- [ ] 데이터/통계의 출처가 표시되었는지
- [ ] 슬라이드 수가 적절한지 (20-35장)
- [ ] fragment 애니메이션이 적용되었는지

## 엣지 케이스

| 상황 | 대응 |
|------|------|
| topic-outline.md 없음 | 사용자에게 리서치 먼저 진행 안내 |
| 서브토픽이 너무 많음 (10+) | 주요 7-8개로 압축 제안 |
| 데이터/통계 없는 서브토픽 | 키포인트 중심 레이아웃으로 대체 |
| 영문 토픽 | 영문 폰트로 전환, 레이아웃 동일 |

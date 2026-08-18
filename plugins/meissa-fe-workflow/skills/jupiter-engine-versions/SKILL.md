---
name: jupiter-engine-versions
description: This skill should be used when the user asks which carta-core or pix4d-core engine version shipped in which jupiter release — triggers include "주피터 릴리즈별 엔진 버전", "jupiter 엔진 버전 표", "carta core 버전 언제 올라갔어", "픽스포디 버전 업데이트 언제", "엔진 버전 이력 정리해줘". Not for deciding which version to deploy, and not for other repositories.
version: 0.1.0
---

# Jupiter Engine Versions

jupiter GitHub 릴리즈마다 어떤 carta-core, pix4d-core 버전이 실렸는지 표로 낸다.

## 왜 존재하는지

엔진 버전은 jupiter `app/core/config.py`의 `ENGINE_MEISSA_V2_TAG`, `ENGINE_PIX4D_V2_TAG`에 문자열로 박혀 있다. 어느 릴리즈에 어떤 버전이 실렸는지는 릴리즈 노트에도 커밋 메시지에도 정리되어 있지 않아 매번 태그를 하나씩 열어봐야 한다. 롤백이 섞이면 버전 번호만으로는 순서를 알 수 없다.

## 언제 쓰면 안 되는지

- jupiter가 아닌 저장소. 변수명과 `app/core/config.py` 경로가 고정되어 있다
- 어느 버전을 올릴지 판단하는 일. 이 skill은 과거 기록만 읽는다
- `gh` 인증이 없는 환경. 릴리즈 목록을 GitHub API로 가져온다

## 절차

### 1. 저장소 찾기

현재 디렉터리가 jupiter가 아니면 사용자에게 경로를 묻는다. 로컬 클론이 오래됐을 수 있으므로 스크립트가 `git fetch --tags`를 먼저 돌린다.

### 2. 수집

```bash
../../scripts/jupiter-engine-versions.sh <jupiter 경로>
```

TSV를 반환한다. 컬럼은 tag, published_kst, carta_core, pix4d_core, changed다. `changed`는 직전 릴리즈 대비 어느 엔진이 바뀌었는지고, 값이 `2.1.1|2.0.9` 형태면 PROD와 STAGING 프로필 값이 다르다는 뜻이다.

### 3. 표

발행 시각 오름차순 그대로 마크다운 표로 옮긴다. 시각은 KST다.

- `changed`가 `-`가 아닌 행은 릴리즈 태그와 바뀐 버전 값을 굵게 처리한다
- `changed` 컬럼 자체는 표에 싣지 않는다. 굵기로 이미 드러난다

### 4. 요약

표 아래에 최근 업데이트를 먼저 쓴다. 두 엔진 각각 마지막으로 값이 바뀐 릴리즈, 발행일, 오늘 기준 경과, 어떤 값에서 어떤 값으로 갔는지.

그다음 표에서 실제로 읽히는 것만 관찰로 적는다. 없으면 적지 않는다.

- 릴리즈에 실리지 않고 건너뛴 엔진 버전. 엔진 저장소에는 릴리즈가 있는데 jupiter 표에 한 번도 안 나타난 값이다
- 버전이 내려간 구간. 하루에 릴리즈를 여러 번 낸 경우가 대개 여기 해당한다
- 엔진 버전이 그대로인 릴리즈가 몇 건인지
- PROD와 STAGING 값이 갈린 구간

## 주의

`git show <tag>:app/core/config.py`가 비면 해당 릴리즈 태그가 로컬에 없거나 파일 경로가 그 시점에 달랐다는 뜻이다. 표에 `?`로 나온다. 값을 지어내지 말고 `?`인 채로 두고 사용자에게 알린다.

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
- macOS나 GNU coreutils가 없는 환경. 날짜 변환에 `date`를 쓴다

## 절차

### 1. 저장소 찾기

현재 디렉터리가 jupiter가 아니면 사용자에게 경로를 묻는다. 로컬 클론이 오래됐을 수 있으므로 스크립트가 `git fetch --tags`를 먼저 돌린다.

### 2. 수집

스크립트는 이 skill 디렉터리 기준 `../../scripts/`에 있다. jupiter 경로는 인자로 넘기므로 어느 디렉터리에서 실행하든 상관없다.

```bash
<skill 디렉터리>/../../scripts/jupiter-engine-versions.sh <jupiter 경로>
```

TSV를 반환한다. 컬럼은 tag, published_kst, carta_core, pix4d_core, changed다.

| 값 | 뜻 |
|---|---|
| `changed` = `기준` | 첫 행. 비교 대상이 없다 |
| `changed` = `-` | 직전 릴리즈와 두 엔진 모두 같다 |
| 버전 = `2.1.1/2.0.9` | PRODUCTION과 STAGING 프로필 값이 다르다 |
| 버전 = `?` | 해당 태그에서 config 파일을 읽지 못했다 |
| 버전 = `-` | config는 읽었으나 변수를 찾지 못했다 |

stderr에 릴리즈 상한 경고가 나오면 더 오래된 릴리즈가 잘렸다는 뜻이므로, 두 번째 인자로 상한을 올려 다시 수집한다.

### 3. 표

발행 시각 오름차순 그대로 마크다운 표로 옮긴다. 시각은 KST다.

- `changed`가 `-`가 아닌 행은 릴리즈 태그와 바뀐 버전 값을 굵게 처리한다
- `changed` 컬럼 자체는 표에 싣지 않는다. 굵기로 이미 드러난다

### 4. 요약

표 아래에 최근 업데이트를 먼저 쓴다. 두 엔진 각각 마지막으로 값이 바뀐 릴리즈, 발행일, 오늘 기준 경과, 어떤 값에서 어떤 값으로 갔는지.

그다음 표에서 실제로 읽히는 것만 관찰로 적는다. 없으면 적지 않는다.

- 릴리즈에 실리지 않고 건너뛴 엔진 버전. 엔진 저장소에는 릴리즈가 있는데 jupiter 표에 한 번도 안 나타난 값이다. 상한 경고가 떴다면 이 관찰은 적지 않는다
- 버전이 내려간 구간. 하루에 릴리즈를 여러 번 낸 경우가 대개 여기 해당한다
- 엔진 버전이 그대로인 릴리즈가 몇 건인지
- PRODUCTION과 STAGING 값이 갈린 구간

## 주의

`?`나 `-`가 나온 행은 값을 지어내지 말고 그대로 두고 사용자에게 알린다. 태그가 로컬에 없거나, config 경로가 그 시점에 달랐거나, 프로필 분기 구조가 바뀌었다는 신호다. 셋 다 표를 못 믿는다는 뜻이므로 요약에서 그 구간을 근거로 삼지 않는다.

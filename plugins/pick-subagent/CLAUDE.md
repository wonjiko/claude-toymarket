# pick-subagent

서브에이전트 모델을 골라 실행하는 슬래시 커맨드 모음.

## 왜 존재하는지

작업을 서브에이전트에 위임할 때 모델을 명시적으로 지정하고 싶을 때 쓴다. `/sub-opus 코드 리뷰해줘`처럼 한 줄로 위임 가능.

## 언제 쓰면 안 되는지

- 서브에이전트 없이 직접 처리해도 되는 간단한 작업
- 대화 컨텍스트가 중요한 작업 (서브에이전트는 현재 대화를 모름)

## 구성

- `commands/sub-opus.md` - `/sub-opus` Opus 모델 서브에이전트
- `commands/sub-sonnet.md` - `/sub-sonnet` Sonnet 모델 서브에이전트
- `commands/sub-haiku.md` - `/sub-haiku` Haiku 모델 서브에이전트

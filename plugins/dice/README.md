# dice

결정장애를 위한 주사위.

## 왜 만들었나

"이거 할까 저거 할까" 고민하는 시간이 아까워서.
Claude한테 물어보면 장단점 분석하고 난리치는데,
가끔은 그냥 던지고 따르는 게 나음.

## 언제 쓰면 안 되나

- 진지한 의사결정
- 돈 관련
- 되돌릴 수 없는 선택

이건 장난감임. 진지하게 쓰지 말 것.

## 설치

`.claude/settings.json`에 추가:

```json
{
  "skills": {
    "dice": {
      "prompt": "[경로]/plugins/dice/prompt.md"
    }
  }
}
```

또는 그냥 prompt.md 내용을 CLAUDE.md에 복붙해도 됨.

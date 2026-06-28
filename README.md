# 퀵폴 (QuickPoll)

링크로 공유하는 빠른 투표 앱. 단일 `index.html` + Supabase 백엔드.

- 질문 + 선택지를 만들면 **공유 링크** 발급
- 링크를 받은 사람들이 투표 → **실제로 표가 합산**
- 결과는 막대그래프 + 비율로 표시
- 같은 브라우저 **중복 투표 방지** (localStorage)

## 셋업 (3단계, 약 10분)

### 1. Supabase 프로젝트 만들기

1. https://supabase.com → GitHub 로그인 → **New project** (프로비저닝 1~2분)
2. **SQL Editor** 에서 [`supabase-setup.sql`](./supabase-setup.sql) 내용을 붙여넣고 **RUN**
3. **Settings → API** 에서 두 값 복사:
   - `Project URL`
   - `anon` `public` key

### 2. 키 입력

`index.html` 상단의 두 상수를 1번에서 복사한 값으로 교체:

```js
const SUPABASE_URL = "https://xxxx.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOi...";
```

> anon key는 공개되어도 안전합니다(클라이언트용). 접근 제어는 RLS 정책이 담당해요.

### 3. 실행 / 배포

- **로컬 확인:** 이 폴더에서
  ```bash
  npx serve .
  ```
  안내되는 주소(예: `http://localhost:3000`)로 접속.
- **배포(공유 링크용):** https://app.netlify.com/drop 에 이 폴더를 드래그&드롭 → 라이브 URL 발급.

## 동작 확인 (E2E)

1. 투표 만들기 → 공유 URL 표시
2. 공유 URL 열어 투표 → 표 +1, 결과 표시
3. 시크릿창/다른 브라우저로 같은 URL 투표 → 표가 **합산**되는지 확인
4. 같은 브라우저 새로고침 → 재투표 막히고 결과만 보이는지 확인

## 파일

- `index.html` — 앱 전체 (만들기 / 투표 / 결과 화면)
- `supabase-setup.sql` — 테이블 + RLS 정책 + `vote()` 함수

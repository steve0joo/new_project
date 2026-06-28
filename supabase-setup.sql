-- 퀵폴 MVP — Supabase SQL Editor에 그대로 붙여넣고 RUN 하세요.

-- 1) 테이블: 질문 + 선택지 라벨 배열 + 표수 배열(병렬)
create table polls (
  id uuid primary key default gen_random_uuid(),
  question text not null,
  options text[] not null,
  counts int[] not null,
  created_at timestamptz default now()
);

-- 2) RLS 켜고 최소 정책만 부여 (읽기/만들기만 허용, 직접 UPDATE/DELETE는 불가)
alter table polls enable row level security;

create policy "anyone can read"   on polls for select using (true);
create policy "anyone can create" on polls for insert with check (true);

-- 3) 원자적 투표 함수
--    opt는 0-based 인덱스 (Postgres 배열은 1-based 라 +1)
--    security definer 라 RLS를 우회해 counts 만 안전하게 증가시킴
create or replace function vote(p_id uuid, opt int)
returns void
language sql
security definer
as $$
  update polls
  set counts[opt + 1] = coalesce(counts[opt + 1], 0) + 1
  where id = p_id;
$$;

-- 4) anon/authenticated 역할에 함수 실행 권한 부여
grant execute on function vote(uuid, int) to anon, authenticated;

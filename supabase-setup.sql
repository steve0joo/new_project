-- 퀵폴 MVP — Supabase SQL Editor에 그대로 붙여넣고 RUN 하세요.

-- 1) 테이블: 질문 + 선택지 라벨 배열 + 표수 배열(병렬)
create table polls (
  id uuid primary key default gen_random_uuid(),
  question text not null,
  options text[] not null,
  counts int[] not null,
  created_at timestamptz default now()
);

-- 2) RLS 켜고 만들기 정책만 부여 (조회는 get_poll RPC로만, 직접 UPDATE/DELETE는 불가)
alter table polls enable row level security;

create policy "anyone can create" on polls for insert with check (
  length(question) between 1 and 140
  and cardinality(options) between 2 and 6
  and cardinality(counts) = cardinality(options)
  and counts = array_fill(0, array[cardinality(options)])
  and (select bool_and(length(o) between 1 and 80) from unnest(options) as o)
);

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
  where id = p_id and opt >= 0 and opt < cardinality(options);
$$;

-- 4) anon/authenticated 역할에 함수 실행 권한 부여
grant execute on function vote(uuid, int) to anon, authenticated;

-- 5) 단건 조회 함수: 링크(UUID)를 아는 사람만 해당 투표를 읽을 수 있음.
--    select 정책을 열어두면 전체 polls 열람/열거가 가능하므로, 조회는 이 RPC로만 노출한다.
create or replace function get_poll(p_id uuid)
returns setof polls
language sql
security definer
set search_path = ''
as $$
  select * from public.polls where id = p_id;
$$;

grant execute on function get_poll(uuid) to anon, authenticated;

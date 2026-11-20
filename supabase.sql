-- Familiekalenderen: kan kjøres i et prosjekt du allerede har. Lager egen tabell «familie_docs» og rører ingenting annet.

create table if not exists public.familie_docs (
  path text primary key,
  coll text not null,
  data jsonb not null,
  updated_at timestamptz default now()
);

alter table public.familie_docs enable row level security;

drop policy if exists "familie_docs les" on public.familie_docs;
drop policy if exists "familie_docs skriv" on public.familie_docs;
create policy "familie_docs les"   on public.familie_docs for select using (true);
create policy "familie_docs skriv" on public.familie_docs for all using (true) with check (true);

-- Gjør at endringer synker live til alle mobiler
alter table public.familie_docs replica identity full;
do $$ begin
  alter publication supabase_realtime add table public.familie_docs;
exception when duplicate_object then null; end $$;

-- Startoppsett: familie, oppdrag og belønninger (kan endres i appen)
insert into public.familie_docs (path, coll, data) values ('family/setup', 'family', '{
  "pin": "admin123",
  "members": [
    {"id":"m1","name":"Andreas","role":"voksen","color":"#2f5bff"},
    {"id":"m2","name":"Mamma","role":"voksen","color":"#ff4d6d"},
    {"id":"m3","name":"Barn 1","role":"barn","color":"#10b981"},
    {"id":"m4","name":"Barn 2","role":"barn","color":"#f59e0b"}
  ],
  "tasks": [
    {"id":"t1","title":"Gjøre lekser","points":10,"days":[1,2,3,4,5]},
    {"id":"t2","title":"Rydde rommet","points":15,"days":[]},
    {"id":"t3","title":"Dekke på bordet","points":5,"days":[]},
    {"id":"t4","title":"Rydde av bordet","points":5,"days":[]},
    {"id":"t5","title":"Spise opp maten","points":5,"days":[]},
    {"id":"t6","title":"Skjermfri dag","points":20,"days":[1,2,3,4]}
  ],
  "rewards": [
    {"id":"r1","title":"Ekstra ukepenger (50 kr)","cost":100},
    {"id":"r2","title":"Velge middag","cost":60},
    {"id":"r3","title":"Kinobillett","cost":250},
    {"id":"r4","title":"Robux (400)","cost":300},
    {"id":"r5","title":"V-Bucks til Fortnite (1000)","cost":350}
  ]
}'::jsonb)
on conflict (path) do nothing;

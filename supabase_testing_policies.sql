alter table public.branches enable row level security;
alter table public.employees enable row level security;
alter table public.profiles enable row level security;
alter table public.attendance_records enable row level security;
alter table public.attendance_corrections enable row level security;
alter table public.requests enable row level security;
alter table public.feed_items enable row level security;
alter table public.feed_comments enable row level security;
alter table public.feed_likes enable row level security;
alter table public.notifications enable row level security;

drop policy if exists "testing read branches" on public.branches;
drop policy if exists "testing read employees" on public.employees;
drop policy if exists "testing read profiles" on public.profiles;
drop policy if exists "testing insert profiles" on public.profiles;
drop policy if exists "testing update profiles" on public.profiles;
drop policy if exists "testing read attendance_records" on public.attendance_records;
drop policy if exists "testing insert attendance_records" on public.attendance_records;
drop policy if exists "testing update attendance_records" on public.attendance_records;
drop policy if exists "testing read attendance_corrections" on public.attendance_corrections;
drop policy if exists "testing insert attendance_corrections" on public.attendance_corrections;
drop policy if exists "testing update attendance_corrections" on public.attendance_corrections;
drop policy if exists "testing read requests" on public.requests;
drop policy if exists "testing insert requests" on public.requests;
drop policy if exists "testing update requests" on public.requests;
drop policy if exists "testing delete requests" on public.requests;
drop policy if exists "testing read feed_items" on public.feed_items;
drop policy if exists "testing read feed_comments" on public.feed_comments;
drop policy if exists "testing insert feed_comments" on public.feed_comments;
drop policy if exists "testing update feed_comments" on public.feed_comments;
drop policy if exists "testing delete feed_comments" on public.feed_comments;
drop policy if exists "testing read feed_likes" on public.feed_likes;
drop policy if exists "testing insert feed_likes" on public.feed_likes;
drop policy if exists "testing delete feed_likes" on public.feed_likes;
drop policy if exists "testing read notifications" on public.notifications;
drop policy if exists "testing insert notifications" on public.notifications;
drop policy if exists "testing update notifications" on public.notifications;

create policy "testing read branches"
on public.branches
for select
to anon
using (true);

create policy "testing read employees"
on public.employees
for select
to anon
using (true);

create policy "testing read profiles"
on public.profiles
for select
to anon
using (true);

create policy "testing insert profiles"
on public.profiles
for insert
to anon
with check (true);

create policy "testing update profiles"
on public.profiles
for update
to anon
using (true)
with check (true);

create policy "testing read attendance_records"
on public.attendance_records
for select
to anon
using (true);

create policy "testing insert attendance_records"
on public.attendance_records
for insert
to anon
with check (true);

create policy "testing update attendance_records"
on public.attendance_records
for update
to anon
using (true)
with check (true);

create policy "testing read attendance_corrections"
on public.attendance_corrections
for select
to anon
using (true);

create policy "testing insert attendance_corrections"
on public.attendance_corrections
for insert
to anon
with check (true);

create policy "testing update attendance_corrections"
on public.attendance_corrections
for update
to anon
using (true)
with check (true);

create policy "testing read requests"
on public.requests
for select
to anon
using (true);

create policy "testing insert requests"
on public.requests
for insert
to anon
with check (true);

create policy "testing update requests"
on public.requests
for update
to anon
using (true)
with check (true);

create policy "testing delete requests"
on public.requests
for delete
to anon
using (true);

create policy "testing read feed_items"
on public.feed_items
for select
to anon
using (true);

create policy "testing read feed_comments"
on public.feed_comments
for select
to anon
using (true);

create policy "testing insert feed_comments"
on public.feed_comments
for insert
to anon
with check (true);

create policy "testing update feed_comments"
on public.feed_comments
for update
to anon
using (true)
with check (true);

create policy "testing delete feed_comments"
on public.feed_comments
for delete
to anon
using (true);

create policy "testing read feed_likes"
on public.feed_likes
for select
to anon
using (true);

create policy "testing insert feed_likes"
on public.feed_likes
for insert
to anon
with check (true);

create policy "testing delete feed_likes"
on public.feed_likes
for delete
to anon
using (true);

create policy "testing read notifications"
on public.notifications
for select
to anon
using (true);

create policy "testing insert notifications"
on public.notifications
for insert
to anon
with check (true);

create policy "testing update notifications"
on public.notifications
for update
to anon
using (true)
with check (true);

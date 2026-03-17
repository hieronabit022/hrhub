insert into storage.buckets (id, name, public)
values ('request-attachments', 'request-attachments', true)
on conflict (id) do nothing;

drop policy if exists "testing read request attachments" on storage.objects;
drop policy if exists "testing insert request attachments" on storage.objects;
drop policy if exists "testing update request attachments" on storage.objects;

create policy "testing read request attachments"
on storage.objects
for select
to anon
using (bucket_id = 'request-attachments');

create policy "testing insert request attachments"
on storage.objects
for insert
to anon
with check (bucket_id = 'request-attachments');

create policy "testing update request attachments"
on storage.objects
for update
to anon
using (bucket_id = 'request-attachments')
with check (bucket_id = 'request-attachments');

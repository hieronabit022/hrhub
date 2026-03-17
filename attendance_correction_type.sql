alter table public.attendance_corrections
add column if not exists correction_type text;

update public.attendance_corrections
set correction_type = case
  when lower(reason) like '%check out%' or lower(reason) like '%clock out%' then 'checkOut'
  else 'checkIn'
end
where correction_type is null;

alter table public.attendance_corrections
alter column correction_type set default 'checkIn';

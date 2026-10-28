-- =====================================================================
--  CƠ SỞ DỮ LIỆU "VƯỜN DÂU THÔNG MINH" CHO SUPABASE
--  Cách dùng: Supabase → SQL Editor → New query → dán toàn bộ → Run
--  Chạy lại nhiều lần vẫn an toàn (không xoá dữ liệu cũ).
-- =====================================================================

-- ---------- 1. Hồ sơ 4 cây dâu ----------
create table if not exists public.cay_trong (
  id          smallint primary key check (id between 1 and 99),
  giong       text not null default 'Dâu tây',
  ngay_trong  date not null default current_date,
  ghi_chu     text default '',
  cap_nhat    timestamptz not null default now()
);
insert into public.cay_trong (id, giong, ngay_trong) values
  (1, 'Dâu tây Mỹ đá', current_date),
  (2, 'Dâu tây Mỹ đá', current_date),
  (3, 'Dâu tây Mỹ đá', current_date),
  (4, 'Dâu tây Mỹ đá', current_date)
on conflict (id) do nothing;

-- ---------- 2. Số liệu cảm biến ----------
create table if not exists public.cam_bien (
  id          bigint generated always as identity primary key,
  thoi_gian   timestamptz not null default now(),
  nhiet_do    real,          -- °C
  do_am       real,          -- % độ ẩm không khí
  do_am_dat   real,          -- % độ ẩm xơ dừa
  anh_sang    real           -- %
);
create index if not exists cam_bien_thoi_gian_idx on public.cam_bien (thoi_gian desc);
-- mỗi phút chỉ một dòng, tránh trùng khi mở webapp trên nhiều máy
create unique index if not exists cam_bien_thoi_gian_uniq on public.cam_bien (thoi_gian);

-- ---------- 3. Nhật ký ảnh và nhận diện bệnh ----------
create table if not exists public.nhat_ky_anh (
  id          bigint generated always as identity primary key,
  thoi_gian   timestamptz not null default now(),
  cay_id      smallint references public.cay_trong(id) on delete set null,
  giai_doan   text,          -- giai đoạn của cây lúc chụp
  ket_qua     text,          -- ví dụ "Bệnh phấn trắng", "Lá xanh tốt"
  nhan_ai     text,          -- tên lớp mô hình AI trả về (khoe, phan_trang…)
  do_tin_cay  real,          -- 0..1
  ti_le_mau   jsonb,         -- tỉ lệ màu: {"xanh":87,"vang":0,...}
  anh_url     text           -- đường link ảnh trong Storage
);
create index if not exists nhat_ky_anh_cay_idx on public.nhat_ky_anh (cay_id, thoi_gian desc);

-- ---------- 4. Đo EC, pH dung dịch ----------
create table if not exists public.do_ec_ph (
  id          bigint generated always as identity primary key,
  thoi_gian   timestamptz not null default now(),
  ec_vao      real,          -- mS/cm dung dịch tưới
  ec_thoat    real,          -- mS/cm nước thoát dưới chậu
  ph          real,
  ml_tuoi     real,
  ml_thoat    real,
  ti_le_thoat real,          -- %
  ghi_chu     text
);

-- ---------- 5. Sự kiện thiết bị (bật/tắt, pha và tưới) ----------
create table if not exists public.su_kien (
  id          bigint generated always as identity primary key,
  thoi_gian   timestamptz not null default now(),
  thiet_bi    text not null check (thiet_bi in ('den','quat','nuoc','dd','tuoi','phatuoi','he_thong')),
  trang_thai  smallint check (trang_thai in (0,1)),
  nguon       text default 'tay' check (nguon in ('tay','lich','nguong','he_thong')),
  ghi_chu     text
);
create index if not exists su_kien_thoi_gian_idx on public.su_kien (thoi_gian desc);

-- ---------- 6. Cài đặt dùng chung giữa các máy (lịch, ngưỡng, công thức) ----------
create table if not exists public.cai_dat (
  khoa        text primary key,          -- ví dụ 'lich', 'nguong', 'cham_soc'
  gia_tri     jsonb not null,
  cap_nhat    timestamptz not null default now()
);

-- ---------- 7. Bảng tổng hợp theo giờ (dùng cho biểu đồ, báo cáo NCKH) ----------
create or replace view public.cam_bien_theo_gio
with (security_invoker = true) as
select date_trunc('hour', thoi_gian)            as gio,
       round(avg(nhiet_do)::numeric, 1)         as nhiet_do_tb,
       round(min(nhiet_do)::numeric, 1)         as nhiet_do_min,
       round(max(nhiet_do)::numeric, 1)         as nhiet_do_max,
       round(avg(do_am)::numeric, 0)            as do_am_tb,
       round(avg(do_am_dat)::numeric, 0)        as do_am_dat_tb,
       round(avg(anh_sang)::numeric, 0)         as anh_sang_tb,
       count(*)                                 as so_lan_do
from public.cam_bien
group by 1;

-- ---------- 8. Quyền truy cập ----------
-- Webapp dùng khoá anon/publishable: được XEM và GHI THÊM, KHÔNG được XOÁ.
alter table public.cay_trong   enable row level security;
alter table public.cam_bien    enable row level security;
alter table public.nhat_ky_anh enable row level security;
alter table public.do_ec_ph    enable row level security;
alter table public.su_kien     enable row level security;
alter table public.cai_dat     enable row level security;

grant usage on schema public to anon, authenticated;
grant select on public.cay_trong, public.cam_bien, public.nhat_ky_anh,
                public.do_ec_ph, public.su_kien, public.cai_dat,
                public.cam_bien_theo_gio to anon, authenticated;
grant insert on public.cam_bien, public.nhat_ky_anh, public.do_ec_ph,
                public.su_kien, public.cai_dat to anon, authenticated;
grant update on public.cay_trong, public.cai_dat to anon, authenticated;

drop policy if exists "xem cay"        on public.cay_trong;
drop policy if exists "sua cay"        on public.cay_trong;
drop policy if exists "xem cam bien"   on public.cam_bien;
drop policy if exists "ghi cam bien"   on public.cam_bien;
drop policy if exists "xem anh"        on public.nhat_ky_anh;
drop policy if exists "ghi anh"        on public.nhat_ky_anh;
drop policy if exists "xem ec"         on public.do_ec_ph;
drop policy if exists "ghi ec"         on public.do_ec_ph;
drop policy if exists "xem su kien"    on public.su_kien;
drop policy if exists "ghi su kien"    on public.su_kien;
drop policy if exists "xem cai dat"    on public.cai_dat;
drop policy if exists "ghi cai dat"    on public.cai_dat;
drop policy if exists "sua cai dat"    on public.cai_dat;

create policy "xem cay"      on public.cay_trong   for select to anon, authenticated using (true);
create policy "sua cay"      on public.cay_trong   for update to anon, authenticated using (true) with check (true);
create policy "xem cam bien" on public.cam_bien    for select to anon, authenticated using (true);
create policy "ghi cam bien" on public.cam_bien    for insert to anon, authenticated
  with check (nhiet_do is null or nhiet_do between -20 and 80);
create policy "xem anh"      on public.nhat_ky_anh for select to anon, authenticated using (true);
create policy "ghi anh"      on public.nhat_ky_anh for insert to anon, authenticated with check (true);
create policy "xem ec"       on public.do_ec_ph    for select to anon, authenticated using (true);
create policy "ghi ec"       on public.do_ec_ph    for insert to anon, authenticated with check (true);
create policy "xem su kien"  on public.su_kien     for select to anon, authenticated using (true);
create policy "ghi su kien"  on public.su_kien     for insert to anon, authenticated with check (true);
create policy "xem cai dat"  on public.cai_dat     for select to anon, authenticated using (true);
create policy "ghi cai dat"  on public.cai_dat     for insert to anon, authenticated with check (true);
create policy "sua cai dat"  on public.cai_dat     for update to anon, authenticated using (true) with check (true);

-- ---------- 9. Kho ảnh (Storage) ----------
insert into storage.buckets (id, name, public)
values ('anh-cay', 'anh-cay', true)
on conflict (id) do nothing;

drop policy if exists "xem anh cay" on storage.objects;
drop policy if exists "tai anh cay" on storage.objects;
create policy "xem anh cay" on storage.objects for select to anon, authenticated
  using (bucket_id = 'anh-cay');
create policy "tai anh cay" on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'anh-cay');

-- ---------- 10. Kiểm tra ----------
select 'Đã tạo xong' as ket_qua,
       (select count(*) from public.cay_trong) as so_cay;

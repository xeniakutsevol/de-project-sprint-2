-- drop tables
drop table if exists public.shipping_info;
drop table if exists public.shipping_status;
drop table if exists public.shipping_country_rates;
drop table if exists public.shipping_agreement;
drop table if exists public.shipping_transfer;


-- create tables
create table public.shipping_country_rates(
shipping_country_id serial4,
shipping_country text,
shipping_country_base_rate numeric(14,3),
primary key (shipping_country_id)
);

create table public.shipping_agreement(
agreement_id bigint,
agreement_number text,
agreement_rate numeric(14,2),
agreement_commission numeric(14,2),
primary key (agreement_id)
);

create table public.shipping_transfer(
transfer_type_id serial4,
transfer_type text,
transfer_model text,
shipping_transfer_rate numeric(14,3),
primary key (transfer_type_id)
);

create table public.shipping_info(
shipping_id int8,
vendor_id int8,
payment_amount numeric(14,2),
shipping_plan_datetime timestamp,
transfer_type_id bigint,
shipping_country_id bigint,
agreement_id bigint,
primary key (shipping_id),
foreign key (transfer_type_id) references  public.shipping_transfer(transfer_type_id) on update cascade,
foreign key (shipping_country_id) references  public.shipping_country_rates(shipping_country_id) on update cascade,
foreign key (agreement_id) references  public.shipping_agreement(agreement_id) on update cascade
);

create table public.shipping_status(
shipping_id int8,
status text,
state text,
shipping_start_fact_datetime timestamp,
shipping_end_fact_datetime timestamp,
primary key (shipping_id)
);
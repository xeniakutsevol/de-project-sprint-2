-- shipping_country_rates
insert into public.shipping_country_rates(
shipping_country, shipping_country_base_rate
)
select distinct shipping_country, shipping_country_base_rate
from public.shipping;

-- check shipping_country_rates
select * from public.shipping_country_rates;
select count(*) from public.shipping_country_rates;
select count(*) from (select distinct shipping_country, shipping_country_base_rate from public.shipping) q;

-- public.shipping_agreement
insert into public.shipping_agreement(
agreement_id, agreement_number, agreement_rate, agreement_commission
)
select
agreement[1]::bigint as agreement_id,
agreement[2] as agreement_number,
agreement[3]::numeric(14,2) as agreement_rate,
agreement[4]::numeric(14,2) as agreement_commission
from (select distinct regexp_split_to_array(vendor_agreement_description, E'\\:+') as agreement from public.shipping) q;

-- check public.shipping_agreement
select count(*) from (select distinct vendor_agreement_description from public.shipping) q;
select count(*) from public.shipping_agreement;
select * from public.shipping_agreement;

-- public.shipping_transfer
insert into public.shipping_transfer(
transfer_type, transfer_model, shipping_transfer_rate
)
select
transfer[1] as transfer_type,
transfer[2] as transfer_model,
shipping_transfer_rate
from (
select distinct regexp_split_to_array(shipping_transfer_description, E'\\:+') as transfer,
shipping_transfer_rate
from public.shipping) q;

-- check public.shipping_transfer
select count(*) from (select distinct shipping_transfer_description, shipping_transfer_rate from public.shipping) q;
select count(*) from public.shipping_transfer;
select * from public.shipping_transfer;

-- public.shipping_info
insert into public.shipping_info(
shipping_id,
vendor_id,
payment_amount,
shipping_plan_datetime,
transfer_type_id,
shipping_country_id,
agreement_id
)
select
s.shippingid as shipping_id,
s.vendorid as vendor_id,
s.payment as payment_amount,
s.shipping_plan_datetime,
t.transfer_type_id,
c.shipping_country_id,
a.agreement_id
from public.shipping s
join public.shipping_transfer t
on t.shipping_transfer_rate = s.shipping_transfer_rate
and (regexp_split_to_array(s.shipping_transfer_description, E'\\:+'))[1] = t.transfer_type
and (regexp_split_to_array(s.shipping_transfer_description, E'\\:+'))[2] = t.transfer_model
join public.shipping_country_rates c
on s.shipping_country = c.shipping_country
join public.shipping_agreement a
on (regexp_split_to_array(s.vendor_agreement_description, E'\\:+'))[1]::bigint = a.agreement_id
group by s.shippingid, s.vendorid, s.payment, s.shipping_plan_datetime, t.transfer_type_id, c.shipping_country_id, a.agreement_id;

-- check public.shipping_info
select count(*) from (select distinct shippingid from public.shipping) q;
select count(*) from public.shipping_info;
select * from public.shipping_info;

-- public.shipping_status
insert into public.shipping_status(
shipping_id,
status,
state,
shipping_start_fact_datetime,
shipping_end_fact_datetime
)
with max_state_datetime as(
select shippingid as shipping_id,
first_value(status) over(partition by shippingid order by state_datetime desc) as status,
first_value(state) over(partition by shippingid order by state_datetime) as start_state,
first_value(state) over(partition by shippingid order by state_datetime desc) as end_state,
first_value(state_datetime) over(partition by shippingid order by state_datetime) as start_state_datetime,
first_value(state_datetime) over(partition by shippingid order by state_datetime desc) as end_state_datetime
from public.shipping
)
select
m.shipping_id,
m.status,
m.end_state as state,
m.start_state_datetime as shipping_start_fact_datetime,
case when m.end_state='recieved' then m.end_state_datetime
when m.end_state='returned' then s.state_datetime
else null end as shipping_end_fact_datetime
from max_state_datetime m
left join public.shipping s
on s.shippingid = m.shipping_id and m.end_state='returned' and s.state='recieved'
group by m.shipping_id, m.status, m.end_state, m.start_state_datetime, m.end_state_datetime, s.state_datetime
;

-- check public.shipping_status
-- check state_datetime for states received, pendind, returned 
select * from public.shipping_status;
select count(*) from public.shipping_status;
select count(*) from (select distinct shipping_id from public.shipping_status) q;
select distinct state from public.shipping_status;
select * from public.shipping_status where state='recieved' limit 1;
select * from public.shipping_status where state='pending' limit 1;
select * from public.shipping_status where state='returned' limit 1;
select * from public.shipping where shippingid in (1,8,34) order by shippingid, state_datetime;




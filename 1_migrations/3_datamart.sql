-- create datamart
drop view shipping_datamart;
create or replace view shipping_datamart as
select
i.shipping_id,
i.vendor_id,
st.transfer_type,
date_part('day', age(ss.shipping_end_fact_datetime, ss.shipping_start_fact_datetime)) as full_day_at_shipping,
case when ss.shipping_end_fact_datetime>i.shipping_plan_datetime
or ss.shipping_end_fact_datetime is null then 1 else 0 end as is_delay,
case when ss.status='finished' then 1 else 0 end as is_shipping_finish,
case when ss.shipping_end_fact_datetime>i.shipping_plan_datetime then date_part('day', age(ss.shipping_end_fact_datetime, i.shipping_plan_datetime))
when ss.shipping_end_fact_datetime is null then date_part('day', current_timestamp-i.shipping_plan_datetime)
else null end as delay_day_at_shipping,
i.payment_amount,
i.payment_amount*(scr.shipping_country_base_rate+sa.agreement_rate+st.shipping_transfer_rate) as vat,
i.payment_amount*sa.agreement_commission as profit
from public.shipping_info i
join public.shipping_transfer st
on i.transfer_type_id = st.transfer_type_id
join public.shipping_status ss
on i.shipping_id = ss.shipping_id
join public.shipping_country_rates scr
on i.shipping_country_id = scr.shipping_country_id
join public.shipping_agreement sa
on i.agreement_id = sa.agreement_id;

-- check datamart
select * from public.shipping_datamart;
select * from shipping where shippingid in(1,5) order by shippingid, state_datetime;
select * from public.shipping_datamart where is_shipping_finish=0 limit 1;
select * from shipping where shippingid in(34) order by shippingid, state_datetime;
select * from public.shipping_datamart where is_shipping_finish=1 and delay_day_at_shipping is not null order by delay_day_at_shipping desc;
select * from public.shipping_datamart where is_shipping_finish=0 order by delay_day_at_shipping desc;

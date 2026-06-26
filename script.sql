-- ============================================================
-- 1. Non-optimized query
-- ============================================================

explain analyze
select 
    c.id,
    c.name,
    c.email,
    (
        select count(*) 
        from opt_orders o 
        where o.client_id = c.id 
          and o.order_date > '2023-01-01'
    ) as total_orders,
    (
        select count(distinct p.product_category)
        from opt_orders o
        join opt_products p on o.product_id = p.product_id
        where o.client_id = c.id 
          and o.order_date > '2023-01-01'
    ) as unique_categories
from opt_clients c
where c.status = 'active'
  and (
        select count(*) 
        from opt_orders o 
        where o.client_id = c.id 
          and o.order_date > '2023-01-01'
  ) > 10
order by total_orders desc
limit 5;

-- ============================================================
-- 2. Indexes for optimization
-- ============================================================

create index if not exists idx_opt_clients_status 
    on opt_clients(status);

create index if not exists idx_opt_orders_date 
    on opt_orders(order_date);

create index if not exists idx_opt_orders_client_id 
    on opt_orders(client_id);
    
create index if not exists idx_opt_orders_product_id 
    on opt_orders(product_id);

-- ============================================================
-- 3. Optimized query
-- ============================================================

explain analyze
with recent_orders as (
    select 
        o.client_id,
        p.product_category
    from opt_orders o
    join opt_products p on o.product_id = p.product_id
    where o.order_date > '2023-01-01'
),
client_stats as (
    select 
        client_id,
        count(*) as total_orders,
        count(distinct product_category) as unique_categories
    from recent_orders
    group by client_id
)
select 
    c.id,
    c.name,
    c.email,
    cs.total_orders,
    cs.unique_categories
from opt_clients c
join client_stats cs on c.id = cs.client_id
where c.status = 'active'
  and cs.total_orders > 10
order by cs.total_orders desc
limit 5;

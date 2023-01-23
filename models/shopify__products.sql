with products as (

    select *
    from {{ ref('int_shopify__products_with_aggregates') }}
), 

order_lines as (

    select *
    from {{ ref('shopify__order_lines') }}
), 

orders as (

    select *
    from {{ ref('shopify__orders')}}
), 

order_lines_aggregated as (

    select 
        order_lines.product_id, 
        order_lines.source_relation,
        sum(order_lines.quantity) as quantity_sold,
        sum(order_lines.pre_tax_price) as subtotal_sold,

        sum(order_lines.quantity_net_refunds) as quantity_sold_net_refunds,
        sum(order_lines.subtotal_net_refunds) as subtotal_sold_net_refunds,

        min(orders.created_timestamp) as first_order_timestamp,
        max(orders.created_timestamp) as most_recent_order_timestamp,
        -- start new columns
        sum(order_lines.total_discount) as total_discount
    from order_lines
    left join orders
        using (order_id, source_relation)
    group by 1,2

), 

joined as (

    select
        products.*,
        coalesce(order_lines_aggregated.quantity_sold,0) as quantity_sold,
        coalesce(order_lines_aggregated.subtotal_sold,0) as subtotal_sold,
        coalesce(order_lines_aggregated.quantity_sold_net_refunds,0) as quantity_sold_net_refunds,
        coalesce(order_lines_aggregated.subtotal_sold_net_refunds,0) as subtotal_sold_net_refunds,
        order_lines_aggregated.first_order_timestamp,
        order_lines_aggregated.most_recent_order_timestamp,
        -- start new columns
        coalesce(order_lines_aggregated.total_discount,0) as total_discounts

    from products
    left join order_lines_aggregated
        on products.product_id = order_lines_aggregated.product_id
        and products.source_relation = order_lines_aggregated.source_relation
)

select *
from joined
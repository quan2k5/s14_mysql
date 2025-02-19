USE ss14_first;
delimiter //
set autocommit=0;
-- 2
create procedure sp_create_order(
    in p_customer_id int,
    in p_product_id int,
    in p_quantity int,
    in p_price decimal(10,2)
)
begin
    declare v_stock_quantity int;
    declare v_order_id int;
    start transaction;
    select stock_quantity into v_stock_quantity from inventory where product_id = p_product_id;
    if v_stock_quantity is null then
        signal sqlstate '45000'
        set message_text = 'sản phẩm không tồn tại trong kho!';
    end if;
    if v_stock_quantity < p_quantity then
        rollback;
        signal sqlstate '45000'
        set message_text = 'không đủ hàng trong kho!';
    end if;
    insert into orders (customer_id, order_date, total_amount, status) values (p_customer_id, now(), 0, 'pending');
    set v_order_id = last_insert_id();
    insert into order_items (order_id, product_id, quantity, price)values (v_order_id, p_product_id, p_quantity, p_price);
    update orders set total_amount = p_quantity * p_price where order_id = v_order_id;
    update inventory set stock_quantity = stock_quantity - p_quantity where product_id = p_product_id;
    commit;
end //
delimiter ;
-- 3
delimiter //
create procedure sp_payment_order(in order_id int,in payment_method varchar(20))
begin
    declare order_status enum('Pending', 'Completed', 'Cancelled');
    declare total_amount decimal(10,2);
    start transaction;
    select status, total_amount into order_status, total_amount from orders where orders.order_id = order_id;
    if order_status != 'Pending' then
        rollback;
        signal sqlstate '45000' set message_text = 'Chỉ có thể thanh toán đơn hàng ở trạng thái Pending!';
    else
        insert into payments(order_id, payment_date, amount, payment_method, status)values(order_id, now(), total_amount, payment_method, 'Completed');
        update orders set status = 'Completed' where orders.order_id = order_id;
        commit;
    end if;
end //
delimiter ;
-- 4
delimiter //
create procedure sp_cancel_order(
    in order_id int
)
begin
    declare order_status enum('Pending', 'Completed', 'Cancelled');
    start transaction;
    select status into order_status from orders where orders.order_id = order_id;
    if order_status <> 'Pending' then
        rollback;
        signal sqlstate '45000' set message_text = 'Chỉ có thể hủy đơn hàng ở trạng thái Pending!';
    else
        update inventory i join order_items oi on i.product_id = oi.product_id set i.stock_quantity = i.stock_quantity + oi.quantity where oi.order_id = order_id;
        delete from order_items where order_items.order_id = order_id;
        update orders set status = 'Cancelled' where orders.order_id = order_id;
        commit;
    end if;
end //
delimiter ;
-- 5
DROP PROCEDURE sp_payment_order;
DROP PROCEDURE  sp_cancel_order;
DROP PROCEDURE sp_create_order;



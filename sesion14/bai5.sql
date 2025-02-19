USE ss14_first;
set autocommit=0;
-- 2
delimiter //
create trigger payment
before insert on payments
for each row
begin
    declare order_total decimal(10,2);
    select total_amount into order_total from orders where order_id = new.order_id;
    if new.amount <> order_total then
        signal sqlstate '45000'
        set message_text = 'số tiền thanh toán không khớp với tổng đơn hàng!';
    end if;
end;
//
delimiter ;
-- 3
CREATE TABLE order_logs (

    log_id INT PRIMARY KEY AUTO_INCREMENT,

    order_id INT NOT NULL,

    old_status ENUM('Pending', 'Completed', 'Cancelled'),

    new_status ENUM('Pending', 'Completed', 'Cancelled'),

    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE

);
-- 4
delimiter //
create trigger after_update_order_status
after update on orders
for each row
begin
    if old.status <> new.status then
        insert into order_logs (order_id, old_status, new_status, log_date)
        values (new.order_id, old.status, new.status, now());
    end if;
end;
//
delimiter ;
-- 5
delimiter //
create procedure sp_update_order_status_with_payment(
    in p_order_id int,
    in p_new_status enum('pending', 'completed', 'cancelled'),
    in p_amount decimal(10,2),
    in p_payment_method enum('credit card', 'paypal', 'bank transfer', 'cash')
)
begin
    declare v_current_status enum('pending', 'completed', 'cancelled');
    declare v_total_amount decimal(10,2);
    declare exit handler for sqlexception
    begin
        rollback;
        signal sqlstate '45000' set message_text = 'Lỗi trong quá trình cập nhật!';
    end;
    
    start transaction;
    select status, total_amount into v_current_status, v_total_amount from orders where order_id = p_order_id;
    if v_current_status = p_new_status then
        rollback;
        signal sqlstate '45000' set message_text = 'Đơn hàng đã có trạng thái này!';
    end if;
    if p_new_status = 'completed' then
        insert into payments (order_id, payment_date, amount, payment_method, status)
        values (p_order_id, now(), p_amount, p_payment_method, 'completed');
    end if;
    update orders set status = p_new_status where order_id = p_order_id;
    commit;
end;
//
delimiter 
-- 6
insert into customers (name, email, phone, address) values ('le anh quan', 'lanhquan130@gmail.com', '123456789', 'Hanoi');
insert into orders (customer_id, total_amount, status) values (1, 1200.00, 'completed');
call sp_update_order_status_with_payment(1, 'completed', 1200.00, 'credit card');
-- 7
drop trigger before_insert_payment;
drop trigger  after_update_order_status;
drop procedure sp_update_order_status_with_payment;
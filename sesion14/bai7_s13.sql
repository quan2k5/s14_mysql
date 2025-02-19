use ss13;
-- 2
create table  banks (
    bank_id int primary key auto_increment,
    bank_name varchar(255) not null,
    status enum('active', 'error') default 'ACTIVE'
);
-- 3
INSERT INTO banks (bank_id, bank_name, status) VALUES 

(1,'VietinBank', 'ACTIVE'),   

(2,'Sacombank', 'ERROR'),    

(3, 'Agribank', 'ACTIVE');   
-- 4
alter table company_funds add column bank_id int;
alter table company_funds add constraint fk_company_funds_bank foreign key (bank_id) references banks(bank_id);
-- 5
UPDATE company_funds SET bank_id = 1 WHERE balance = 50000.00;
INSERT INTO company_funds (balance, bank_id) VALUES (45000.00,2);
-- 6
delimiter //
create trigger CheckBankStatus 
before insert on payroll 
for each row 
begin
    declare bank_status varchar(10);
    select status into bank_status from banks where bank_id = (select bank_id from company_funds limit 1);
    if bank_status = 'error' then
        signal sqlstate '45000' 
        set message_text = 'Giao dịch bị từ chối do ngân hàng gặp sự cố.';
    end if;
end //
delimiter ;
-- 7
delimiter //

create procedure transfer(in p_emp_id int)
begin
    declare v_salary decimal(10,2);
    declare v_balance decimal(15,2);
    declare v_bank_status enum('active', 'error');
    declare v_fund_id int;
    start transaction;
    select salary into v_salary from employees where emp_id = p_emp_id limit 1;
    if v_salary is null then
        rollback;
        signal sqlstate '45000' 
        set message_text = 'nhân viên không tồn tại';
    end if;
    select fund_id, balance, b.bank_id into v_fund_id, v_balance, v_bank_status from company_funds c join banks b on c.bank_id = b.bank_id limit 1;
    if v_bank_status = 'error' then
        rollback;
        signal sqlstate '45000' 
        set message_text = 'ngân hàng gặp lỗi';
    end if;
    if v_balance < v_salary then
        rollback;
        signal sqlstate '45000' 
        set message_text = 'quỹ công ty không đủ tiền';
    end if;
    update company_funds set balance = balance - v_salary where fund_id = v_fund_id;
    insert into payroll (emp_id, salary, pay_date) values (p_emp_id, v_salary, curdate());
    update employees set last_pay_date = NOW() where emp_id = p_emp_id;
    insert transaction_log (emp_id, log_message)values (p_emp_id, 'Lương được chuyển thành công');
    commit;
end //
delimiter ;
-- 8
call Transfer(1);





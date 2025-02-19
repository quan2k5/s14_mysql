use ss13;
create table account (
    emp_id int primary key,
    bank_id int,
    amount_added decimal(10,2) default 0.00,
    total_amount decimal(10,2) default 0.00,
    foreign key (emp_id) references employees(emp_id),
    foreign key (bank_id) references banks(bank_id)
);

insert into account (emp_id, bank_id, amount_added, total_amount) values
(1, 1, 0.00, 12500.00),  
(2, 1, 0.00, 8900.00),   
(3, 1, 0.00, 10200.00),  
(4, 1, 0.00, 15000.00),  
(5, 1, 0.00, 7600.00);

-- 4. tạo procedure để chuyển lương cho tất cả nhân viên
delimiter //
create procedure transfer_salary_all()
begin
    declare v_emp_id int;
    declare v_salary decimal(10,2);
    declare v_bank_id int;
    declare v_balance decimal(10,2);
    declare v_total_salary decimal(10,2);
    declare v_total_employees int default 0;
    declare v_error_message varchar(255);
    declare exit_loop int default 0;
    declare cur cursor for 
    select e.emp_id, e.salary, a.bank_id 
    from employees e
    join account a on e.emp_id = a.emp_id;
    declare continue handler for sqlexception
    begin
        set v_error_message = 'failed: error occurred during salary transfer';
        insert into transaction_log (log_time, log_message) values (now(), v_error_message);
        rollback;
        set exit_loop = 1;
    end;
    start transaction;
    select sum(salary) into v_total_salary from employees;
    select balance into v_balance from company_funds where bank_id = 1;
    if v_balance < v_total_salary then
        set v_error_message = 'failed: insufficient company funds';
        insert into transaction_log (log_time, log_message) values (now(), v_error_message);
        rollback;
    end if;
    open cur;
    read_loop: loop
        fetch cur into v_emp_id, v_salary, v_bank_id;
        if exit_loop = 1 then 
            leave read_loop;
        end if;
        begin
            declare continue handler for sqlexception 
            begin
                set v_error_message = 'failed: bank error detected';
                insert into transaction_log (log_time, log_message) values (now(), v_error_message);
                rollback;
                set exit_loop = 1;
            end;
            update company_funds set balance = balance - v_salary where bank_id = v_bank_id;
            insert into payroll (emp_id, salary, pay_date) values (v_emp_id, v_salary, now());
            update employees set last_pay_date = now() where emp_id = v_emp_id;
            update account 
            set total_amount = total_amount + v_salary, 
                amount_added = v_salary
            where emp_id = v_emp_id;
            set v_total_employees = v_total_employees + 1;
        end;
    end loop;
    close cur;
    insert into transaction_log (log_time, log_message) 
    values (now(), concat('success: paid salary to ', v_total_employees, ' employees'));
    commit;
end //
delimiter ;
-- 5
call transfer_salary_all();
-- 6
select * from company_funds;
select * from payroll;
select * from account;

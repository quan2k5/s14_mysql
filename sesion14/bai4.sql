
USE ss14_second;
delimiter //
set autocommut=0;
-- 2
create procedure increase_salary(in emp_id int,in new_salary decimal(10,2),in reason text)
begin
    declare old_salary decimal(10,2);
    start transaction;
    select base_salary into old_salary from salaries where employee_id = emp_id;
    if old_salary is null then
        rollback;
        signal sqlstate '45000' set message_text = 'nhân viên không tồn tại!';
    end if;
    insert into salary_history (employee_id, old_salary, new_salary, reason)values (emp_id, old_salary, new_salary, reason);
    update salaries set base_salary = new_salary where employee_id = emp_id;
    commit;
end //
delimiter ;
-- 3
call increase_salary(1, 5000.00, 'tăng lương định kỳ');
-- 4
delimiter //
create procedure delete_employee(in emp_id int)
begin
    declare old_salary decimal(10,2);
    start transaction;
    select base_salary into old_salary from salaries where employee_id = emp_id;
    if old_salary is null then
        rollback;
        signal sqlstate '45000' set message_text = 'nhân viên không tồn tại!';
    end if;
    insert into salary_history (employee_id, old_salary, new_salary, reason)values (emp_id, old_salary, null, 'xóa nhân viên');
    delete from salaries where employee_id = emp_id;
    delete from employees where employee_id = emp_id;
    commit;
end //
delimiter ;
-- 5
call delete_employee(2);



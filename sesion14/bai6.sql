USE ss14_second;
set autocommit=0;
-- 2
delimiter //
create trigger before_update_phone
before update on employees
for each row
begin
    if new.phone is not null and (length(new.phone) != 10 or new.phone not regexp '^[0-9]+$') then
        signal sqlstate '45000'
        set message_text = 'số điện thoại phải có đúng 10 chữ số.';
    end if;
end //
delimiter ;
-- 3
CREATE TABLE notifications (

    notification_id INT PRIMARY KEY AUTO_INCREMENT,

    employee_id INT NOT NULL,

    message TEXT NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

 FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE

);
-- 4
delimiter //
create trigger after_insert_employee
after insert on employees
for each row
begin
    insert into notifications (employee_id, message)
    values (new.employee_id, concat('chào mừng ', new.name));
end //

delimiter ;
-- 5
delimiter //
create procedure addNewEmployeeWithPhone(
    in emp_name varchar(255),in emp_email varchar(255),in emp_phone varchar(20),in emp_hire_date date,in emp_department_id int
)
begin
    declare exit handler for sqlexception
    begin
        rollback;
        select 'lỗi xảy ra, quá trình thêm nhân viên đã bị hủy!' as message;
    end;
    start transaction;
    if (select count(*) from employees where email = emp_email) > 0 then
        signal sqlstate '45000'set message_text = 'email đã tồn tại!';
    end if;
    if length(emp_phone) != 10 or emp_phone regexp '[^0-9]' then
        signal sqlstate '45000'set message_text = 'số điện thoại không hợp lệ! phải có đúng 10 chữ số.';
    end if;
    insert into employees (name, email, phone, hire_date, department_id)values (emp_name, emp_email, emp_phone, emp_hire_date, emp_department_id);
    commit;
end //
delimiter ;




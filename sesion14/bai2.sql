CREATE DATABASE ss14_second;
USE ss14_second;
-- 1. Bảng departments (Phòng ban)
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(255) NOT NULL
);

-- 2. Bảng employees (Nhân viên)
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    department_id INT NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE CASCADE
);

-- 3. Bảng attendance (Chấm công)
CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    check_in_time DATETIME NOT NULL,
    check_out_time DATETIME,
    total_hours DECIMAL(5,2),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- 4. Bảng salaries (Bảng lương)
CREATE TABLE salaries (
    employee_id INT PRIMARY KEY,
    base_salary DECIMAL(10,2) NOT NULL,
    bonus DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);

-- 5. Bảng salary_history (Lịch sử lương)
CREATE TABLE salary_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE
);
set autocommit=0;
-- 2
delimiter $$
create trigger employee_email
before insert on employees
for each row
begin
    if new.email not like '%@company.com' then
        set new.email = concat(new.email, '@company.com');
    end if;
end $$
delimiter ;
-- 3
delimiter $$
create trigger employee_salary
after insert on employees
for each row
begin
    insert into salaries (employee_id, base_salary, bonus)values (new.employee_id, 10000.00, 0.00);
end $$
delimiter ;
-- 4
delimiter $$
create trigger history_salary
after delete on employees
for each row
begin
    declare v_salary decimal(10,2);
    declare v_bonus decimal(10,2);
    select base_salary, bonus into v_salary, v_bonus from salaries where employee_id = old.employee_id;
    insert into salary_history (employee_id, old_salary, new_salary, reason) values (old.employee_id, v_salary, null, 'Nhân viên nghỉ việc');
    delete from salaries where employee_id = old.employee_id;
end $$
delimiter ;
-- 5
delimiter $$
create trigger before_update_attendance_hours
before update on attendance
for each row
begin
    if new.check_out_time is not null then
        set new.total_hours = timestampdiff(hour, new.check_in_time, new.check_out_time);
    end if;
end $$
delimiter ;
-- 6
INSERT INTO departments (department_name) VALUES 

('Phòng Nhân Sự'),

('Phòng Kỹ Thuật');

INSERT INTO employees (name, email, phone, hire_date, department_id)

VALUES ('Nguyễn Văn A', 'nguyenvana', '0987654321', '2024-02-17', 1);
select * from employees;
-- 7
INSERT INTO employees (name, email, phone, hire_date, department_id)

VALUES ('Trần Thị B', 'tranthib@company.com', '0912345678', '2024-02-17', 2);

select * from salaries;
-- 8
INSERT INTO attendance (employee_id, check_in_time)

VALUES (1, '2024-02-17 08:00:00');

UPDATE attendance

SET check_out_time = '2024-02-17 17:00:00'

WHERE employee_id = 1;
select * from attendance;









use ss13;
-- 2
create table student_status (
    student_id int primary key,
    status enum('active', 'graduated', 'suspended') not null,
    foreign key (student_id) references students(student_id)
);
-- 3
INSERT INTO student_status (student_id, status) VALUES

(1, 'ACTIVE'), -- Nguyễn Văn An có thể đăng ký

(2, 'GRADUATED'); -- Trần Thị Ba đã tốt nghiệp, không thể đăng ký
-- 4
delimiter //

create procedure register_course_(p_student_name varchar(50),p_course_name varchar(100))
begin
    declare v_student_id int;
    declare v_course_id int;
    declare v_available_seats int;
    declare v_status enum('active', 'graduated', 'suspended');
    start transaction;
    select student_id into v_student_id from students where student_name = p_student_name;
    if v_student_id is null then
        insert into enrollments_history (student_id, course_id, action, timestamp)
        values (null, null, 'FAILED: Student does not exist', now());
        rollback;
    end if;
    select course_id, available_seats into v_course_id, v_available_seats from courses where course_name = p_course_name;
    if v_course_id is null then
        insert into enrollments_history (student_id, course_id, action, timestamp)
        values (v_student_id, null, 'FAILED: Course does not exist', now());
        rollback;
    end if;
    if exists (select 1 from enrollments where student_id = v_student_id and course_id = v_course_id) then
        insert into enrollments_history (student_id, course_id, action, timestamp)
        values (v_student_id, v_course_id, 'FAILED: Already enrolled', now());
        rollback;
    end if;
    select status into v_status from student_status where student_id = v_student_id;
     if v_status in ('graduated', 'suspended') then
        insert into enrollments_history (student_id, course_id, action, timestamp)values (v_student_id, v_course_id, 'FAILED: Student not eligible', now());
        rollback;
    end if;
    if v_available_seats > 0 then
        insert into enrollments (student_id, course_id)values (v_student_id, v_course_id);
        update courses set available_seats = available_seats - 1 where course_id = v_course_id;
        insert into enrollments_history (student_id, course_id, action, timestamp)
        values (v_student_id, v_course_id, 'REGISTERED', now());
        commit;
    else
        insert into enrollments_history (student_id, course_id, action, timestamp)
        values (v_student_id, v_course_id, 'FAILED: No available seats', now());

        rollback;
    end if;
end //

delimiter ;
-- 5
call register_course('Nguyễn Văn An', 'Cơ sở dữ liệu');
-- 6
select * from enrollments;
select * from courses;
select * from enrollments_history;


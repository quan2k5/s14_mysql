use ss13;
-- 2
CREATE TABLE course_fees (

    course_id INT PRIMARY KEY,

    fee DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE

);

CREATE TABLE student_wallets (

    student_id INT PRIMARY KEY,

    balance DECIMAL(10,2) NOT NULL DEFAULT 0,

    FOREIGN KEY (student_id) REFERENCES students(student_id) ON DELETE CASCADE

);
-- 3
INSERT INTO course_fees (course_id, fee) VALUES

(1, 100.00), -- Lập trình C: 100$

(2, 150.00); -- Cơ sở dữ liệu: 150$

 

INSERT INTO student_wallets (student_id, balance) VALUES

(1, 200.00), -- Nguyễn Văn An có 200$

(2, 50.00);  -- Trần Thị Ba chỉ có 50$
-- 4
DELIMITER $$

CREATE PROCEDURE register_course(
    IN p_student_name VARCHAR(50),
    IN p_course_name VARCHAR(100)
)
BEGIN
    DECLARE v_student_id INT;
    DECLARE v_course_id INT;
    DECLARE v_balance DECIMAL(10,2);
    DECLARE v_fee DECIMAL(10,2);
    DECLARE v_available_seats INT;
    START TRANSACTION;
	SELECT id INTO v_student_id FROM students WHERE name = p_student_name;
    IF v_student_id IS NULL THEN
        INSERT INTO enrollment_history(student_name, course_name, status, timestamp)
        VALUES (p_student_name, p_course_name, 'failed: student does not exist', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'student does not exist';
    END IF;
    SELECT id, available_seats INTO v_course_id, v_available_seats FROM courses WHERE name = p_course_name;
    IF v_course_id IS NULL THEN
        INSERT INTO enrollment_history(student_name, course_name, status, timestamp)
        VALUES (p_student_name, p_course_name, 'failed: course does not exist', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'course does not exist';
    END IF;

    IF EXISTS (SELECT 1 FROM enrollments WHERE student_id = v_student_id AND course_id = v_course_id) THEN
        INSERT INTO enrollment_history(student_name, course_name, status, timestamp)
        VALUES (p_student_name, p_course_name, 'failed: already enrolled', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'already enrolled';
    END IF;
    IF v_available_seats <= 0 THEN
        INSERT INTO enrollment_history(student_name, course_name, status, timestamp)
        VALUES (p_student_name, p_course_name, 'failed: no available seats', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'no available seats';
    END IF;

    SELECT balance INTO v_balance FROM student_wallets WHERE student_id = v_student_id;
    SELECT fee INTO v_fee FROM course_fees WHERE course_id = v_course_id;

    IF v_balance < v_fee THEN
        INSERT INTO enrollment_history(student_name, course_name, status, timestamp)
        VALUES (p_student_name, p_course_name, 'failed: insufficient balance', NOW());
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'insufficient balance';
    END IF;
    INSERT INTO enrollments(student_id, course_id, enrollment_date)
    VALUES (v_student_id, v_course_id, NOW());
    UPDATE student_wallets SET balance = balance - v_fee WHERE student_id = v_student_id;
    UPDATE courses SET available_seats = available_seats - 1 WHERE id = v_course_id;
    INSERT INTO enrollment_history(student_name, course_name, status, timestamp)
    VALUES (p_student_name, p_course_name, 'registered', NOW());
    COMMIT;
END$$

DELIMITER ;
-- 5 
call register_course('Nguyễn Văn An', 'Cơ sở dữ liệu');
-- 6
SELECT s.name, w.balance FROM students s JOIN student_wallets w ON s.id = w.student_id WHERE s.name = 'nguyen van a';

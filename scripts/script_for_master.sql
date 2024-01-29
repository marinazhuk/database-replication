use mydb;

SET @sleep_time = '1';

insert into users
(firstname, lastname, age)
VALUES
    ('Alice', 'Smith', 20);

SELECT SLEEP(@sleep_time);

select * from users;

insert into users
(firstname, lastname, age)
VALUES
    ('Bob', 'Johns', 25);

insert into users
(firstname, lastname, age)
VALUES
    ('John', 'Williams', 30);

update users
SET lastname = CONCAT(lastname,'1')
WHERE firstname = 'Alice';

update users
SET age = age+1
WHERE firstname = 'Alice';

insert into users
(firstname, lastname, age)
VALUES
    ('Mary', 'Walker', 30);

update users
SET age = age+1
WHERE firstname = 'Bob';


select lastname from users;

DELETE FROM users
WHERE firstname = 'Alice';
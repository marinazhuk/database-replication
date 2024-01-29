# Set up MySQL Cluster

* Setup master slave replication in docker (Master: mysql-m, Slave: mysql-s1, mysql-s2)
* Ensure, that replication is working
* Test replication:
  * Try to turn off mysql-s1 (stop slave),
  * Try to remove columns in Slave DB (last column and column from the middle)
  * Try to turn on mysql-s1 (start slave)

## Configuration commands

#### Run in Master container 

```
CREATE USER "mydb_slave_user"@"%" IDENTIFIED BY "mydb_slave_pwd"; 
CREATE USER "mydb_slave_user2"@"%" IDENTIFIED BY "mydb_slave_pwd2";
GRANT REPLICATION SLAVE ON *.* TO "mydb_slave_user"@"%";
GRANT REPLICATION SLAVE ON *.* TO "mydb_slave_user2"@"%"; 
FLUSH PRIVILEGES;
```

```
SHOW MASTER STATUS
```
#### Run in Slave1 container

```
CHANGE MASTER TO MASTER_HOST='mysql_master',MASTER_USER='mydb_slave_user',MASTER_PASSWORD='mydb_slave_pwd',MASTER_LOG_FILE='1.000004',MASTER_LOG_POS=157; 
START SLAVE;
```
```
SHOW SLAVE STATUS
```

#### Run in Slave2 container

```
CHANGE MASTER TO MASTER_HOST='mysql_master',MASTER_USER='mydb_slave_user2',MASTER_PASSWORD='mydb_slave_pwd2',MASTER_LOG_FILE='1.000004',MASTER_LOG_POS=157; 
START SLAVE;
```
```
SHOW SLAVE STATUS;
```

or run [build.sh](build.sh) file


## Testing
Create table in Master using script [schema.sql](scripts%2Fschema.sql)


Check that replication is working:

Master
```sql
mysql> select * from users;
+----+-----------+----------+-----+
| id | firstname | lastname | age |
+----+-----------+----------+-----+
|  1 | Alice     | Smith    |  20 |
+----+-----------+----------+-----+
```
Slave1
```sql
mysql> select * from users;
+----+-----------+----------+-----+
| id | firstname | lastname | age |
+----+-----------+----------+-----+
|  1 | Alice     | Smith    |  20 |
+----+-----------+----------+-----+
```
Slave2
```sql
mysql>  select * from users;
+----+-----------+----------+-----+
| id | firstname | lastname | age |
+----+-----------+----------+-----+
|  1 | Alice     | Smith    |  20 |
+----+-----------+----------+-----+
```

### Remove last column in Slave 1
* Drop column
```sql
STOP SLAVE;
USE mydb;
    
ALTER TABLE users DROP COLUMN age;

START SLAVE;
```
* Run modifying queries on Master: 
```sql
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
```

#### Result:
Operations were successfully synchronized, table doesn't have last column, but data in table is consistent in Slave 1.

### Remove column in the middle of the table in Slave 1
* Drop column
```sql
STOP SLAVE;
USE mydb;
ALTER TABLE users DROP COLUMN firstname;
START SLAVE;
```

* Run modifying queries on Master:
```sql
insert into users
(firstname, lastname, age)
VALUES
('Mary', 'Walker', 30);

update users
SET age = age+1
WHERE firstname = 'Bob';

DELETE * FROM users
WHERE firstname = 'Alice';
```

#### Result:

Synchronization is broken in Slave1. 
Data is shifted: column  *'lastname'* has values from deleted *'firstname'* column.

Master:
```sql
mysql> select lastname from users;
+----------+
| lastname |
+----------+
| Johns    |
| Williams |
| Walker   |
| Smith    |
+----------+
```

Slave:
```sql
mysql> select lastname from users;
+----------+
| lastname |
+----------+
| Bob      |
| Williams |
| Mary     |
| Alice    |
+----------+
```

Queries used for testing [script_for_master.sql](scripts%2Fscript_for_master.sql)
SQOOP:
to import selected records from tables [not a table]: [primary key = split-by]
        --query "select * from orders join orders_items on orders.order_id=orders_items.orders_items_id where \$CONDITIONS" \
        --split-by order_id 
to append the records in exisitng table and change the delimiter:
        --target-dir /user/hive/warehouse/flumedata.db/departments
        --append
        --fields-terminated-by '|' \
        --lines-terminated-by '\n' \

important parameters:
where clause: 
	--where "department_id > 7"

incremental load:
	--incremental [append/lastmodified]

if some records are appended from department_id value = 7 in mysql table and to append them in hdfs:
	--append \
	--incremental append \
	--check-column "department_id" \
	--last-value 7

to import data in existing hadoopexam database and depart table in HIVE:
	--hive-import \
	--hive-home /user/hive/warehouse \
	--hive-table hadoopexam.depart \
	--m 1

to import data in existing hadoopexam database but non-existing table in hive:
	--hive-import \
	--hive-home /user/hive/warehouse \
	--hive-table hadoopexam.depart_new \
	--create-hive-table \

MYSQL query to create record doe current time:
	create table table1 (created_time TIMESTAMP DEFAULT NOW());
	insert into table1 values (current timestamp); [OR (null);]

EXPORT SQOOP parameters [hdfs to mysql]:
	--export-dir /user/hive/warehouse/retail_db.db/departments \
	--input-fields-terminated-by '|' \
	--input-lines-terminated-by '\n' \
	--num-mappers 1 \
	--direct \
	--update-key deparment_id \
	--update-mode [allowinsert/updateonly] \ --> if updateonly then we can't insert new records
	--input-null-string nvl \
	--input-null-non-string -999

to create sqoop job:
	sqoop job --create sqoop_jobs \
	--import \
	--connect jdbc:mysql://quickstart:3306/retail_db \
	...........

to list all the sqoop jobs:
	sqoop job --list

to show the sqoop jobs:
	sqoop job --show sqoop_jobs

to execute sqoop_job:
	sqoop job --exec sqoop_jobs
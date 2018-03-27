SQOOP:
to import selected records from tables [not a table]: [primary key / boundary condition = split-by]
query function must have where and \$CONDITIONS. And query and table never come together.
        --query "select * from orders join orders_items on orders.order_id=orders_items.orders_items_id where \$CONDITIONS" \
    OR 	--query "select * from table where \$CONDITIONS"
    OR 	--query "select * from new_categories where category_department_id IS NULL AND \$CONDITIONS" \
		--split-by order_id 
        --target-dir /user/hive/warehouse/flumedata.db/departments ==> creates new dir departments and store data
        --warehouse-dir /user/dirname ==> creates dir dirname and also creates dir with tablename under dirname[/user/dirname/tablename] 
        --append
        --fields-terminated-by '|' \
        --lines-terminated-by '\n' \
        --enclosed-by \' \ ==> fields are enclosed in (') single quote
        --escaped-by \\ \
        --lines-terminated-by :

to compress the output file:
        --compress \
		--compression-codec org.apache.hadoop.io.compress.SnappyCodec \

using boundary query: 
		--boundary-query "select 1, 25 from departments" \ ==> same as --query "select * from department where id between 1 and 25 "

to encode non string null check-column or If null value found for name column, to append the records in exisitng table and change the delimiter: repalce it by empty string and for id column with -999:
		--null-string='N'
		--null-non-string='N'
		--null-string "" \
		--null-non-string -999 \
important parameters:
to overwrite table in hdfs:
	--delete-target-dir \
	--target-dir hdfspath 

to import specific columns:
	--columns department_id,department_name
where clause: 
	--where "department_id > 7"

incremental load:
	--incremental [append/lastmodified]
	==> lastmodified will create new part-m-00001 only new data
	==> append will create new part-m-00001 with only new data

if some records are appended from department_id value = 7 in mysql table and to append them in hdfs:
	--append \
	--incremental append \
	--check-column "department_id" \
	--last-value 7

to append data from mysql to hive:
	--append \
	--incremental append \
	--check-column "department_id" \
	--last-value 10 \
	--fields-terminated-by '\001' \ ==> IMPORTANT TO READ FROM mysql TO HIVE
	--target-dir /user/hive/warehouse/retail.db/departments_sqoop \

incremental - append: create new part-m-00001 file. check-column can be any columns
--connect jdbc:mysql://quickstart.cloudera:3306/retail_db \
--username retail_dba \
--password cloudera \
--table departments \
--incremental append \
--check-column department_id \
--last-value 1021 \
--target-dir /spark/testAppend \
--m 1

incremental - lastmodified: create new part-m-00001 file. append is mandatory and last-value must be date
sqoop import \
--connect jdbc:mysql://quickstart.cloudera:3306/retail_db \
--username retail_dba \
--password cloudera \
--table departments_new \
--target-dir /spark/testAppend \
--append \ 
--incremental lastmodified \ 
--check-column created_date \
--last-value '2017-12-11 14:57:38' \ 
--m 1


EXPORT SQOOP parameters:
sqoop export --connect jdbc:mysql://quickstart/retail_db --username retail_dba --password cloudera \
	--table Employee \
	--export-dir /user/hive/warehouse/retail_db.db/departments \
	--input-fields-terminated-by '|' \
	--input-lines-terminated-by '\n' \
	--batch \ ==> mandatory
	--as-avrodatafile \
	--update-key deparment_id \ ==> mandatory to insert/update data from hdfs to mysql
	--update-mode allowinsert \ ==> new data will be inserted and updated as well.
	--update-mode updateonly \ ==> only exisiting data will be updated. it won't insert new data
	--input-null-string nvl \
	--input-null-non-string -999

to import data in existing hadoopexam database and depart table in HIVE:
	--hive-import \
	--hive-overwrite \
	--hive-home /user/hive/warehouse \
	--hive-table hadoopexam.depart \
	--m 1

check the solution instead of storing data: 
sqoop eval --connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera \
--query 'select count(1) from order_items'

Import all the tables and store in avro format
sqoop import-all-tables --connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera \
--as-avrodatafile \
OR --as-textfile \
OR --as-sequencefile 
--warehouse-dir /user/hive/warehouse/retail_stage.db \
-m 1

Write a sqoop job which will import "retail_db.categories" table to hdfs, in a directory name "categories_target_job":
sqoop job 
--create sqoop_job \
-- import \ ==> -- import space is mandatory
--connect "jdbc:mysql://quickstart.cloudera:3306/retail_db" \
--username retail_dba \
--password cloudera \
--table categories \
--target-dir categories_target_job \
--fields-terminated-by '|' \
--lines-terminated-by '\n'

List all the sqoop jobs:
sqoop job --list

Details of the sqoop jobs:
sqoop job --show sqoop_jobs

Execute the sqoop job:
sqoop job --exec sqoop_job


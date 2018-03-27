1. Keep the record in given format. (Structure format)
1.1 create table if not exists PatientDetail 
(Name STRUCT<First_Name:string, Last_Name:string>,
Address STRUCT<HouseNo:string, LocalityName:string, City:string, Zip:string>,
Phone STRUCT<Mobile:string, Landline:String> )
row format delimited fields terminated by '|'
collection items terminated by ',' 
stored as sequencefile;

1.2 create table if not exists temp_patient(data string);
		Amit|Jain|A-646, Cheru Nagar, Chennai|999999999|98989898|600020

1.3 select split(data,'\\|')[0] FirstName, split(data,'\\|')[1] LastName, 
split(split(data,'\\|')[2],',')[0] HouseNo, split(split(data,'\\|')[2],',')[1] LocalityName, split(split(data,'\\|')[2],',')[2] City,
split(data,'\\|')[5] Zip,
split(data,'\\|')[3] Mobile, split(data,'\\|')[4] Landline from temp_patient;

1.4 insert overwrite table PatientDetail 
select named_struct("First_Name",split(data,'\\|')[0],"Last_Name", split(data,'\\|')[1]),
named_struct("HouseNo",split(split(data,'\\|')[2],',')[0], "LocalityName", split(split(data,'\\|')[2],',')[1],
				"City",split(split(data,'\\|')[2],',')[2], "Zip",split(data,'\\|')[5]),
named_struct("Mobile",split(data,'\\|')[3],"Landline",split(data,'\\|')[4]) 
from temp_patient;

64.242.88.10 - - [07/Jun/2016:16:47:46 -0800] "GET /hadoopexam.com/bin/rdiff/Know/ReadmeFirst?rev1=1.5?rev2=1.4 HTTP/1.1" 200 5724
64.242.88.10 - - [07/Jun/2016:16:49:04 -0800] "GET /hadoopexam.com/bin/view/Main/hadoopexam.comGroups?rev=1.2 HTTP/1.1" 200 5162

2.1 create table hadoopexam_log1 (
host string,
identity string,
user string,
time string,
request string,
status string,
size string)
row format serde 'org.apache.hadoop.hive.contrib.serde2.RegexSerDe'
with SERDEPROPERTIES (
"input.regex" = '([^\ ]*) - - \\[([^\\]]*)\\] "([^\ ]*) ([^\ ]*) ([^\\"]*)" (\\d*) (\\d*)',
"output.format.string" = '%1$$s %2$$s %3$$s %4$$s %5$$s %6$$s %7$$s')
stored as textfile;

Jun  3 07:10:54 hadoopexam.com_node01 init: tty (/dev/tty6) main process (1208) killed by TERM signal
Jun  3 07:11:31 hadoopexam.com_node01 kernel: registered taskstats version 1
Jun  3 07:11:31 hadoopexam.com_node01 kernel: sr0: scsi3-mmc drive: 32x/32x xa/form2 tray
3. Use partition by year and month
3.1. create table Hadoopexam_log7 (
month_name String, Day string, Time string, Node string, Process string, Log_msg string
)
Partitioned By (year int, month int)
row format SerDe 'org.apache.hadoop.hive.contrib.serde2.RegexSerDe'
with iPERTIES (
'input.regex' = '([^\ ]*)[\ ]*([^\ ]*) ([^\ ]*) ([^\ ]*) ([^:]*): (.*)',
'output.format.string' = '%1$$s %2$$s %3$$s %4$$s %$5$$s %6$$s' 
)
stored as textfile;

3.2 Alter table hadoopexam_log1 Add if not exists partition(year = 2016, month = 06)
Location '/HadoopExam/logs/jun16' ;


4 Remove duplicate records:
4.1 create table temp_emp_report (
FirstName String, LastName String, EmpId int, LoggedInDate int, JoiningDate int, DeptId String
)
row format delimited fields terminated by ',' 
location '/user/hive/warehouse/temp_emp_report' ; 
4.2 create table emp_report as select FirstName, LastName, EmpId, JoiningDate, max(LoggedInDate) LoggedInDate, DeptId
from temp_emp_report 
GROUP BY FirstName, LastName, EmpId, JoiningDate, DeptId ;

5. Denormalize the records, uniform DOB format, separate records of below 200 blood pressure and born in June.
5.1 create table patientinfo (
id int, FirstName String, LastName String, Age int, BirthDate date
)
row format delimited fields terminated by ','
tblproperties ("skip.header.line.count"="1") ;

create table healthdetail (
id int, LowBP int, HighBP int, LDL int, TotalCol int, Triglycerides int
)
row format delimited fields terminated by ','
tblproperties ("skip.header.line.count"="1") ;

5.2 create table patient_health_info as select 
p.id, FirstName, LastName, age, birthdate, LowBP, HighBP, LDL, TotalCol, Triglycerides 
from patientinfo as p 
left join healthdetail as h 
on p.id = h.id ;

5.3 insert into table final_patient_health select id, FirstName, LastName, Age, 
(CASE  
when BirthDate REGEXP '(\\d{1,2})-([a-zA-Z]{3})-(\\d{4})' then from_unixtime(UNIX_TIMESTAMP(BirthDate,'dd-MMM-yyyy'),'MM/dd/yyyy')
when BirthDate REGEXP '(\\d{1,2})/([a-zA-Z]{3})/(\\d{4})' then from_unixtime(UNIX_TIMESTAMP(BirthDate,'dd/MMM/yyyy'),'MM/dd/yyyy')
when BirthDate REGEXP '(\\d{1,2})/(\\d{1,2})-(\\d{4})' then from_unixtime(UNIX_TIMESTAMP(BirthDate,'dd-mm-yyyy'),'MM/dd/yyyy')
when BirthDate REGEXP '([a-zA-Z]{3})-(\\d{1,2})\\ (\\d{4})' then from_unixtime(UNIX_TIMESTAMP(BirthDate,'dd-MMM-yyyy'),'MM/dd/yyyy')
ELSE BirthDate
END
) as BirthDate,
LowBP, HighBP, LDL, TotalCol, Triglycerides 
from patient_health_info ;

5.3 To filter the record who are born in Jun:
select * from final_patient_health where from_unixtime(Unix_Timestamp(birthdate, 'MM/dd/yyyy'), 'MMM') = 'Jun';

5.4 To filter the record who have ldl > 50:
select * from final_patient_health where ldl >50;

6. Static and dynamic partition
6.1 create external table log_static_partition (
month_name string, day string, time string, node string, process string, log_msg string
)
partitioned by (year int, month int)
row format SerDe 'org.apache.hadoop.hive.contrib.serde2.RegexSerDe' 
with SERDEPROPERTIES (
'input.regex' = '([^\ ]*)[\ ]*([\\d ]\\d) ([^\ ]*) ([^\ ]*) ([^\ :]*): (\.*)$'
)
stored as textfile ;

6.2. Alter table log_static_partition add patition(year=2015, month=06) location '/HadoopExam/logs/jun16';
Alter table log_static_partition add partition (year=2016, month=06) location '/HadoopExam/logs/jun15' ;

6.3 create table log_dynamic_partition (
month_name string, time string, node string, process string, log_msg string
)
partitioned by (year int, month int, day string)
row format delimited fields terminated by '\t' ;

-- 6.4 Insert into log_dynamic_partition partition(year, month, day) 
-- select month_name, time, node, process, log_msg, year, month, day from log_static_partition;

ID,URL,DATE,PUBID,ADVERTISERID
1,http://hadoopexam.com/path1/p.php?keyword=hadoop&country=india#Ref1,30/JUN/2016,PUBHADOOPEXAM,GOOGLEADSENSE
2,http://QuickTechie.com/path1/p.php?keyword=hive&country=us#Ref1,30/JUN/2016,PUBQUICKTECHIE,GOOGLEADSENSE

7. PARSE_URL(STRING) and partition by host and  county:
7.1 create table ad_part (
id string, date string, Pubid string, advertiserid string, keyword string
)
partitioned by (host string, country string)
row format delimited fields terminated by ',' ;

7.2 create table temp_ad_part (data string);

7.3 load data inpath '/HadoopExam/logs/ads.log' into table temp_ad_part;

7.4 Insert into ad_part partition(host, country) 
select split(data, '\\,')[0] id, split(data, '\\,')[2] date, split(data, '\\,')[3] Pubid, split(data, '\\,')[4] advertiserid,
PARSE_URL(split(data,'\\,')[1], 'QUERY', 'keyword') keyword, 
PARSE_URL(split(data,'\\,')[1], 'HOST') Host,
PARSE_URL(split(data, '\\,')[1],'QUERY', 'country') country
from temp_ad_part ;

8.total ad expense by domain and country:
8.1 create table ad_log1 (
id int, URL string, date string, pubid string, advertiserid string
)
row format delimited fields terminated by ',';

8.2 create table ad_cpc_log1 (
id int, adname string, cpc int
)
row format delimited fields terminated by ',';

8.3 create table merge_ad_log1 
as select ad.id, parse_url(url, 'HOST') domain, parse_url(url, 'QUERY', 'country') country, date, pubid, advertiserid, adname, cpc 
from ad_log1 ad 
left join ad_cpc_log1 ad1 
on ad.id = ad1.id;

9.1 create table ad_shown_log_final1(
id int, url string, date string, ........
);

9.2 create table ad_shown_log_final 
select distinct id, upper(url) url, date, upper(pubid) pubid, upper( advertiserid) advertiserid
from ad_shown_log_final1 
where parse_url(url, 'HOST') regexp '([^\.]*).com';

9.3 select id, date, pubid, advertiserid, 
parse_url(url,'QUERY', 'KEYWORD') keyword, parse_url(url, 'HOST') host, parse_url(url, 'QUERY', 'COUNTRY') country 
from ad_shown_log_final;

10. Use hive UDF from /usr/lib/hive/lib/hive-exec.jar. 
temporary functions (hadoopexam_lower, hadoopexam_negative) using org/apache/hadoop/hive/ql/udf/generic/GenericUDFLower.class

10.1 Add jar /usr/lib/hive/lib/hive-exec.jar ;
10.2 create temporary function hadoopexam_lower as 'org.apache.hadoop.hive.ql.udf.generic.GenericUDFLower' ;
10.3 create table temp_healthdetail (id int, name string, HighBP int, LDL int, .......) 
row format delimited fields terminated by ',' ;
10.3 create temporary function hadoopexam_negative 
as 'org.apache/hadoop/hive/ql/udf/generic/GenericUDFOPNegative' ;

10.4 create table healthdetail (
id int, name string, LowBP int, HighBP int, LDL int, totalCol int, Triglycerides int
)
row format delimited fields terminated by ',' ;
10.5 insert into healthdetail
select id, hadoopexam_lower(name) name, LowBP, HighBP, hadoopexam_negative(LDL) LDL, totalCol, Triglycerides
from temp_healthdetail;

11. Extract the schema from this Avro file:

12.
12.1 Import single table (without specifying directory): 
#Sqoop import --connect jdbc:mysql://quickstart:3306/retail_db --username=retail_dba --password=cloudera -table=categories
⇒ categories/part-m-00000

12.2 Import tables Specifying target directory (use number of mappers):
#sqoop import --connect jdbc:mysql://quickstart:3306/retail_db --username=retail_dba --p --table=categories --target-dir=categories_target --m 1;
⇒ categories_target/part-m-00000 (depends on value of m)

12.3 Specifying parent directory for copying more than one table:
#sqoop import --connect jdbc:mysql://quickstart:3306/retail_db --username=retail_dba -p --table=categories --warehouse-dir=categories_warehouse --m 1;
⇒ categories_warehouse/categories/part-m-00000

13. 
13.1 Check all the available command ==> hdfs dfs
13.2 Get help on individual command ==> hdfs dfs -help get 
13.3 Create a new empty directory name Employee ==> hdfs dfs -mkdir Employee
13.4 Over-ride the existing Employee directory ==> hdfs dfs -put text1 Employee 
											   ==> hdfs dfs -put text2 Employee
13.5 Check all the files in directory ==> hdfs dfs -ls Employee
13.6 Merge all the files in Employee directory ==> hdfs dfs -getmerge -nl Employee mergedEmployee.txt
13.7 Check the content of the file ==> cat mergedEmployee.txt

14.
14.1 Import data from categories table, where category = 22:
#sqoop import --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera \
--table categories \
--warehouse-dir /HadoopExam/sqoopImport/categories_subset \
--where 'category_id = 22' \
--m 1

14.2 Import data from categories table, where category between 1 and 22:
#sqoop import --connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera \
--table categories \
--warehouse-dir /HadoopExam/sqoopImport/category_subset2 \
--where 'category_id between 1 and 22' \
--m 1

14.3 While importing categories data change the delimiter to "|" :
#sqoop import --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera \
--table categories \
--target-dir /HadooopExam/sqoopImport/category_subset4 \
--where 'category_id > 22' \
--fields-terminated-by "|" \
-m 1

16.In hive, store data with other properties: "Database creator" = "Samita", "Database_created_on" = '2016-01-01':
16.1 create database IF NOT EXISTS Family
COMMENT 'This database will be used for collectiong various family data and their daily habits'
LOCATION '/HadoopExam/family'
WITH DBPROPERTIES ('Database creator' = 'Samita' , 'Database_created_on' = '2016-01-01');

16.2 Describe DATABASE EXTENDED family; 

17. Import deparments table, insert new records in department in mysql, then import only new inserted records:
17.1 sqoop import --connect jdbc:mysql://quickstart/retail_db --username retail_dba --password cloudera \
--table departments \
--target-dir /HadoopExam/sqoopImport/departments

17.2 mysql>insert into deparments values (10, 'Physics'); --> appended from department_id's value = 7 

17.3 sqoop import --connect jdbc:mysql://quickstart/retail_db --username retail_dba --password cloudera \
--table departments_new \
--target-dir /HadoopExam/sqoopImport/departments \
--append \
--check-column 'department_id' \
--incremental append \
--last-value 7 \
-m 1

18. Hive, table must ne created inside hive warehouse directory amd should not be an external:

18.1 create table IF NOT EXISTS Family_head (
name string,
business_places Array <string>,
sex_age STRUCT <sex: string, age: int>,
fathername_NuOfChild MAP<string, int>
)
row format delimited
fields terminated by '|'
collection items terminated by ','
map keys terminated by ':' ;

19. Import the entire database to hadoop e.g group data in column
and should able to query this data using IMPALA. Save with compression using SNAPPY CODEC.

19.1 #sqoop import-all-tables --connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera \
--compression-codec snappy \
--warehouse-dir /HadoopExam/retail_warehouse \
--as-parquetfile \
--hive-import \
--m 1

19.2 To find most 5 popular product categories:
#create table popular_product
as select c.category_name, count(order_item_quantity) count 
from order_items oi
inner join products p on p.product_id = oi.order_item_product_id
inner join categories c on c.category_id = p.product_id
group by c.category_name
order by count desc
limit 5;

19.3 Top 10 revenue generating products:
create table revenue_generating
as select p.product_id, p.product_name, tb1.revenue
from products p
inner join (
select order_item_product_id, sum(cast(oi.order_item_subtotal as float)) as revenue
from order_items oi
inner join orders o1 on oi.order_item_order_id = o1.order_id
where order_status <> 'CANCELLED'
and order_status <> 'FRAUD'
group by order_item_product_id) as tb1
on p.product_id = tb1.order_item_product_id
order by revenue
limit 10;

20. List the table using sqoop 
20.1 #sqoop list-tables --connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera

20.1 #sqoop eval --connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera \
--query 'select count(1) from order_items'

20.2 import all the tables as avro file:
#sqoop import-all-tables --connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera \
--as-avrodatafile
--warehouse-dir /user/hive/warehouse/retail_stage.db \
-m 1

20.3 import departments table as a text file in /user/cloudera/deparments:
#sqoop import --connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera \
--as-textfile \
--target-dir /user/cloudera/departments

21. make each tables file is partitioned in 3 files (--m 3) and
store all the java files in a directory called java_output to evaluate the further: 
21.1 sqoop import-all-tables \
--m 3 \
--connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera \
--hive-import \
--hive-overwrite \
--create-hive-table \
--outdir java_output \
--compress \
--compression-codec org.apache.hadoop.io.compress.SnappyCodec \

22. Import department tables using boundary query (which import departments between 1 to 25)
and import only two columns from the table (department_id, department_name):

22.1 sqoop import \
--connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera \
--table departments \
--target-dir /HadoopExam/sqoopImport/departments1 \
--m 3 \
--boundary-query 'select 1, 25 from departments' \
--columns department_id,department_name

25.1 import data in existing hadoopexam database and table in HIVE:
#sqoop import \
--connect ....................\
--hive-import \
--hive-overwrite \
--hive-home /user/hive/warehouse \
--hive-table hadoopexam.departments 

25.2 import data in existing database and non-existing tables in HIVE:
#sqoop import \
--connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba -p \
--table department \
--hive-import \
--hive-home /user/hive/warehouse \
--hive-table hadoopexam.department_new \
--create-hive-table 

26. Incremental import based on created_date column:
26.1 mysql> create table departments_new (department_id int(11), department_name varchar(50), 
			created_date TIMESTAMP DEFAULT NOW());
	 mysql> insert into departments_new select a.*, null from departments a;
26.2 # sqoop import --connect jdbc:.........\
--table department_new \
--target-dir /user/cloudera/deparments_new \
split-by department_id

26.3 #sqoop import ................\
--table department_new \
--target-dir /user/cloudera/deparments_new \
--append \
--check-column created_date \
--incremental lastmodified \
--split-by department_id \
--last-value "2016-09-01 17:17:24"

27. Import data from HDFS(/user/cloudera/deparments_new) to departments_export table in mysql:
mysql> create departments_export (department_id int(11), department_name varchar(45), 
		created_date TIMESTAMP DEFAULT NOW() );

27.1 #sqoop export --connect jdbc:mysql://quickstart/retail_db --username retail_dba, -p \
--table department_export \
--export-dir /user/cloudera/departments_new \
--batch

29.1 Allow insert data to existing table in mysql(primary key = update-key, update-mode allowinsert)
#sqoop export --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera \
--table updated_departments \
--export-dir /HadoopExam/sqoopExport/updated_departments.csv \
--batch \
--m 1 \
--update-key department_id \
--update-mode allowinsert

29.2 Allow updateonly to mysql table:(update-mode updateonly which will not insert new record)
# sqoop export --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera \
--table updated_departments \
--export-dir /HadoopExam/sqoopExport/new_departments.csv \
--batch \
--m 1 \
--update-key department_id \
--update-mode updateonly

30. A system is designed the way that it can process only files if fields are enclosed in 'single quote'
separater of the field should be (~) and line needs to be terminated by (:).If data itself contains
the "double quote" then it should be escaped by \.
#sqoop import --connect jdbc:mysql://quickstart/retail_db --username retail_dba --password cloudera \
--table departments \
--target-dir /user/cloudera/deparments_enclosedby \
--enclosed-by \' \
--fields-terminated-by '~' \
--lines-terminated-by : \
--escaped-by \\

32. Import hdfs to RDBMS and save as avro file:
#sqoop export --connect jdbc:mysql://quickstart/retail_db --username retail_dba --password cloudera \
--table Employee \
--export-dir /HadoopExam/sqoopExport/Employee \
--as-avrodatafile 

33. import data from mysql to hive table. Should be visible using hive command (select * dept_hive)
[default hive field terminater is ^A 001]. If null value found for name column, repalce it by empty string
and for id column with -999:
#sqoop import jdbc:mysql://quickstart/retail_db --username retail_dba -p \
--table departments \
--hive-import \
--hive-overwrite \
--hive-home /user/hive/warehouse/ \
--hive-table /may_batch2016/dept_hive \
--fields-terminated-by '\001' \
--null-string "" \
--null-non-string -999 \
--split-by id \
--m 1

34. Same conditions but import hive (dept_hive) to mysql(depart):
#sqoop export jdbc:mysql://quickstart/retail_db --username retail_dba -p \
--table depart \
--export-dir /user/hive/warehouse/may_batch2016/dept_hive \
--input-fields-terminated-by '\001' \
--input-lines-terminated-by '\n' \
--batch \
--num-mappers 1 \
--input-null-string "" \
--input-null-non-string -999 \

36. Create a sqoop job to import "retail_db.categories" table to hdfs, in a directory name "categories_target_job":
36.1 connecting to existing Mysql database:
mysql --user retail_db -password cloudera retail_db 

36.2 create sqoop job to import:
#sqoop job --create sqoop_job \
--import \
--connect "jdbc:mysql://quickstart/retail_db" \
--username retail_dba --password cloudera \
--table categories \
--target-dir /user/cloudera/categories_target_job
--fields-terminated-by '|'

36.3 list all the sqoop jobs:
#sqoop job --list

36.4 show details of the sqoop jobs:
#sqoop job --show sqoop_job

36.5 Execute the sqoop job:
#sqoop job --exec sqoop_job

36.6 Check the output of import job:
#hdfd dfs -cat categories_target_job/part* 

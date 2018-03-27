HIVE: 
to create table:
	create table table1 
		(name string, salary int, sex string, age int)
		row format delimited
		fields terminated by ',';

to load data from hdfs file:
	load data inpath '/HadoopExam/logs/ads.log' into table temp_ad_part;

to load data from local file:
	LOAD DATA LOCAL INFILE '/path/pet.txt' INTO TABLE pet;
		
to change table type external to managed or vice versa:
	alter table purchase set tblproperties ('EXTERNAL'='TRUE'); ==> all in capital letters
	alter table table1 set tblproperties ('skipAutoProvisioning'='FALSE');
#commandline:
	hive -e "alter table table1 set tblproperties ('skipAutoProvisioning'='FALSE');"	

to create hive table from avro data file in hdfs:
	create external table departments_avro stored as avro location '/spark/departments_avro/departments' tblproperties ('avro.schema.url'='/spark/departments_avro/departments.avsc');
		
to compress the output file OR to change the file format to compressed one:
        hive>set hive.exec.compress.output=true;
        hive>set mapred.compress.map.output=true;
        hive>set mapred.output.compression.codec=org.apache.hadoop.io.compress.BZip2Codec;

to remove header: tblproperties("skip.header.line.count"="1");

to create structure format table:
create table table_struct 
(
Name struct<fname:string, lname:string>,
Address struct<housenumber:string, city:string, state:string, zip:string>,
Phone struct<home:string, mobile:string>
)
comment "Created by: Samita Maharjan"
row format delimited fields terminated by '|'
collection items terminated by ','
stored as sequencefile
;

Amit|Jain|A-646, Cheru Nagar, Chennai|999999999|98989898|600020
Sumit|Saxena|D-100, Connaught Place, Delhi|1111111111|82828282|110001
	
	create table table1(data1 string);

	insert into table_struct select named_struct("fname", split(data1, '\\|')[0], "lname", split(data1, '\\|')[1]),
									named_struct("city", split(split(data1, '\\|')[2], ',')[1], "state", split(split(data1, '\\|')[2], ',')[2])
									named_struct("mobile", split(data1,'\\|')[4])
							from table1;

Jun  3 07:10:54 hadoopexam.com_node01 init: tty (/dev/tty6) main process (1208) killed by TERM signal
Jun  3 07:11:31 hadoopexam.com_node01 kernel: registered taskstats version 1

to load above log into the table:
	create table table1(
		month_name string, day string, time string, node string, process string, log_msg string
		)
	partitioned by (year int, month int)
	row format serde 'org.apache.hadoop.hive.serde2.RegexSerde'
	with serdeproperties (
		"input.regex"="^(\\w+)[ ]+(\\d+)[ ]+(\\d+:\\d+:\\d+)[ ]+([^ ]*)[ ]+(.*)$"
		)
	stored as textfile;
	
	Alter table table1 add partition(year = 2016, month = 06) location '/HadoopExam/logs' ;

to change date format of BirthDate:
	Id,FirstName,LastName,Age,BirthDate
	1,Ajit,Jogi,45,19-Aug-1970
	2,Anubhav,shyam,56,30-Sep-1965
	3,Raghu,Prasad,43,30/Jul/1963

	insert into table1 as select id, FirstName, LastName, Age,
		(case
		When BirthDate REGEXP ='(\\d{1,2})-(\\w{3})-(\\d{4})' then from_unixtime(UNIX_TIMESTAMP(BirthDate,'dd-MMM-yyyy'),'MM-dd-yyyy')
		When BirthDate REGEXP ='(\\d{1,2})/(\\w{3})/{\\d{4}}' then from_unixtime(UNIX_TIMESTAMP(BirthDate,'dd/MMM/yyyy'),'MM-dd-yyyy')
		else BirthDate
		End) as BirthDate
		from patientdetails;
		
to filter the BirthDate who are born in jun:
	select * from table1 where from_unixtime(UNIX_TIMESTAMP(BirthDate,'MM-dd-yyyy'), 'MMM') = "jun";
	
to rank the price:
	select *, rank() over (order by price) rank from products;
	1004	PEC	Pencil 2B	10000	0.48	1
	1005	PEC	Pencil 2H	8000	0.49	2
	1001	PEN	Pen Red		5000	1.23	3
	1003	PEN	Pen Black	2000	1.25	4
	1002	PEN	Pen Blue	8000	1.25	4
	1006	PEC	Pencil HB	0		9999.99	6 <== rank() function skips 5 

	select *, dense_rank() over (order by price) rank from products;
	1004	PEC	Pencil 2B	10000	0.48	1
	1005	PEC	Pencil 2H	8000	0.49	2
	1001	PEN	Pen Red		5000	1.23	3
	1003	PEN	Pen Black	2000	1.25	4
	1002	PEN	Pen Blue	8000	1.25	4
	1006	PEC	Pencil HB	0		9999.99	5 <== dense_rank() function includes 5

	select name, product, price, dense_rank() over (partition by name, product order by price desc) from table_name1;
	1001	PEN	Pen Red		5000	1.23	1
	1002	PEN	Pen Blue	8000	1.25	1
	1003	PEN	Pen Black	2000	1.25	1
	1004	PEC	Pencil 2B	10000	1.5		1 <= if prder by price asc, 0.48 will be in rank 1
	1004	PEC	Pencil 2B	10000	0.48	2 <=
	1004	PEC	Pencil 2B	10000	0.48	2 <=
	1005	PEC	Pencil 2H	8000	0.49	1
	1006	PEC	Pencil HB	0		9999.99	1

#to display 3rd highest department_id:	
mysql/hive>select * from (select department_id, department_name from depart order by  department_id desc limit 3) as table1 order by department_id limit 1 ;	

to remove duplicate using rank function:
	create table table_name2 as 
		(select name, product, price from (
			select name, product, price, rank() over (partition by name, product order by price desc) rank
			 from table_name1) rank_table) where rank_table.rank=1 ;

	create table table_name2 as 
		(select name, product, price from (
			select name, product, price, rank() over (partition name, product order by price desc) rank from table_name1) rank_table) where rank.rank_table=1;
		) 

samita samita eats apple apple apple

What are difference on the three channels?
Memory channels store events an in-memory queue. It is very useful for high-throughput data flow but day have no durability which means if agent goes down, data will be lost.

File channels persist events to disk and have a strong durability.

JDBC channels store events in database and have the strongest durability. But JDBC channels are the slowest compared to other 2 types of channels.

# Q: student name,  grade
You are required to use Spark RDD to calculate the average grades for each student 
A, 100
A, 99
B, 80

var managerPairRDD = manager.map(x => (x.split(",")(0), x.split(",")(1).toInt))
val xpair = xmap.aggregateByKey((0, 0))((x, y) =>(x._1 + y, x._2 + 1), (x1, y1) => (x1._1 + y1._1, x1._2 + y1._2))
val avg = xpair.mapValues(x => (x._1 / x._2))
avg.collect();

//method 1
val rdd = textFile.flatMap(line=> { val p = line.split(","); (p(0), p(1))})
val agg_rdd = rdd.aggregateByKey((0,0))((acc, value) => (acc._1 + value, acc._2 + 1),(acc1, acc2) => (acc1._1 + acc2._1, acc1._2 + acc2._2))



			
val avg = agg_rdd.mapValues(x => (x._1/x._2))
avg.collect();


//method 2 
val rdd = textFile.flatMap(line=> { val p = line.split(","); (p(0), p(1))})
val com_rdd = rdd.combineByKey((x) => (x,1),
                             (pair1, x) => (pair1._1 + x, pair1._2 + 1), 
                             (pair1, pair2) => (pair1._1 + pair2._1, pair1._2 + pair2._2))

val avg = com_rdd.mapValues(x => (x._1/x._2))
avg.collect()


Q: list all the major components of HBase
zookeeper, HMaster, HRegionServer, HRegion, Catalog Tables.
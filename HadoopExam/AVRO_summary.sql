In sqoop==> as-avrodatafile ==> create .avsc file in local where sqoop command was run.
In hive==> create external table departments_avro 
				stored as avro 
				location '/spark/departments_avro/departments' 
				tblproperties ('avro.schema.url'='/spark/departments_avro/departments.avsc');
			
create table <table_name>(parameters)
			row format serde 'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
			stored as input'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
			output 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
			location '/HadoopExam/<path_to_data_dir>'
			tblproperties ('avro.schema.url'='/HadoopExam/<path_to_avsc_file');

			create table <table_name>
			stored as avro
			tblproperties('avro.schema.url'='/HadoopExam/<path_to_avsc_file')

			"OR"
	tblproperties ('avro.schema.literal'='{
	  "type" : "record",
	  "name" : "sqoop_import_departments",
	  "doc" : "Sqoop import of departments",
	  "fields" : [ {
	    "name" : "department_id",
	    "type" : [ "int", "null" ],
	    "columnName" : "department_id",
	    "sqlType" : "4"
	  }, {
	    "name" : "department_name",
	    "type" : [ "string", "null" ],
	    "columnName" : "department_name",
	    "sqlType" : "12"
	  } ],
	  "tableName" : "departments"
	}')

to create table with partition in avro format:
	create table table1(order_id int, order_date bigint, order_customer_id int, order_status string)
	partitioned by (date_month string)
	stored as avro
	location '<hdfs_hivetable_path>'
	tblproperties('avro.schema.literal'='{
		"type" : "record",
	  "name" : "orders_partition",
	  "doc" : "Hive partitioned table schema ",
	  "fields" : [ {
	    "name" : "order_id",
	    "type" : [ "int", "null" ]
	  }, {
	    "name" : "order_date",
	    "type" : [ "long", "null" ]
	  }, {
	    "name" : "order_customer_id",
	    "type" : [ "int", "null" ]
	  }, {
	    "name" : "order_status",
	    "type" : [ "string", "null" ]
	  } ],
	  "tableName" : "orders_partition"
	}');

Static partition:
	alter table table1 add partition(date_month='2014-02'); 
	
	insert into table1 partition(date_month="2014-02")
		select * from orders
		where from_unixtime(cast(substr(order_date,1,10) as int)) like '2014-02%';

Dynamic partition:
	set hive.exec.dynamic.partition.mode=nonstrict;
	
	insert into table1 partition(date_month)
		select order_id, order_customer_id, order_status, 
		substr(from_unixtime(cast(substr(order_date,1,10) as int)),1,7) date_month
		from orders;

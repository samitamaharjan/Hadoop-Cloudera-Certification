46. Save table in HDFS and hive. Using sqoop export the table in Avro file format. And, create table in hive using avro files.
46.1 export table in Avro file format from Mysql to hdfs
#sqoop import --connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera \
--table orders \
--as-avrodatafile \
--target-dir /user/hive/warehouse/flumedata.db/orders_sqoop \
--m 1

Note: Above command line will create orders.avsc file in local directory where the command was run.
		This .avsc file should put into the hdfs to match tblproperties in hive. 
		The transferred file will not open in hive query. So we have to create an external table in hive as below.
46.2 hdfs dfs -put orders.avsc /user/hive/warehouse/flumedata.db/orders_import_sqoop.avsc 
		
46.3 create an external table in hive
#create external table orders_sqoop 
row format serde 'org.apache.hadoop.hive.serde2.avro.AvroSerDe' 
stored as inputformat 'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat' 
outputformat 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
Location '/user/hive/warehouse/flumedata.db/orders_sqoop'
tblproperties ('avro.schema.url'='hdfs://quickstart.cloudera:8020/user/hive/warehouse/flumedata.db/orders_import_sqoop.avsc');

47. Export tables from mysql to hdfs and to hive using stored as AVRO instead of SERDE.
47.1 import to hdfs 
# sqoop import --connect jdbc:mysql://quickstart.cloudera:3306/retail_db \
--username retail_dba --password cloudera \
--table departments \
--as-avrodatafile \
--target-dir /user/hive/warehouse/flumedata.db/departments_sqoop \
--m 1

47.2 hdfs dfs -put departments.avsc /user/hive/warehouse/flumedata.db/departments_import_sqoop.avsc

47.3 create hive table
 #create external table departments_sqoop stored as avro location '/user/hive/warehouse/flumedata.db/departments_sqoop' tblproperties ('avro.schema.url'='hdfs://quickstart.cloudera:8020/user/hive/warehouse/flumedata.db/departments_import_sqoop.avsc');
 
48. Create hive table using given AVRO schema and data file (use "avro.schema.literal"):

48.1 copy existing table departments_sqoop data to new table 
create external table departments2
row format serde 'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
stored as
inputformat 'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
outputformat 'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
Location '/user/hive/warehouse/flumedata.db/departments_sqoop'
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
}');

49. Using Impala create table (customers2) in flumedata schema.
	Avro data file location: hdfs://user/hive/warehouse/flumedata.db/customer_sqoop
	Avro schema file location: hdfs://quickstart.cloudera/user/cloudera/avrodata/sqoop_import_customers.avsc
	
#create external table customers2
stored as avro
location 'hdfs:///user/hive/warehouse/flumedata.db/customers_sqoop'
tblproperties ('avro.schema.url'='hdfs://quickstart.cloudera/HadoopExam/avrodata/customers.avsc');

50. Partition, Avro file
50.1 
#create table orders_partition (
order_id int, order_date bigint, order_cuustomer_id int, order_status string
)
partitioned by (order_month string)
stored as avro
Location 'hdfs:///user/hive/warehouse/flumedata.db/orders_partition'
tblproperties ('avro.schema.literal'='{
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
}') ;

50.2 create manual partition on the table:
#alter table orders_partition add partition (order_month='2014-12');

50.3 load data from orders_sqoop table:
#insert into orders_partition partition(order_month='2014-02')
select * from orders_sqoop where from_unixtime(cast(substr(order_date,1,10) as int)) like '2014-02%';

51. same as 50 with dynamic partition:
#set hive.exec.dynamic.partition.mode=nonstrict;

#insert into orders_partition partition(order_month)
select order_id, order_date, order_customer_id, order_status,
substr(from_unixtime(cast(substr(order_date,1,10) as int)), 1, 7) order_month from orders_sqoop;

52. 
52.1 create static partition table:
#create table static_partition (
first_name string, last_name string, address string, city string, 
pincode int, home int, office string, email string, website string
)
partitioned by (country string, state string)
row format delimited fields terminated by ',' ;

52.2 #load data local inpath '/home/cloudera/HadoopExam/namelist.csv' 
into table static_partition partition (country='IN', state='RJ');

52.3 create dynamic partition table:
#set hive.exec.dynamic.partition.mode=nonstrict;

#create static partition table:
#create table dynamic_partition (
first_name string, last_name string, address string, city string, 
pincode int, home int, office string, email string, website string
)
partitioned by (country string, state string)
row format delimited fields terminated by ','
stored as sequencefile ;

#create table dynamic_partition_temp (
first_name string, last_name string, address string, country string, city string, state string,
pincode int, home int, office string, email string, website string
)
row format delimited fields terminated by ',';

#insert into table dynamic_partition
partition (country, state)
select first_name, last_name, address, city, pincode, home, office, email, website, country, state 
from dynamic_partition_temp ;

53. create managed hive table orders_part4 with additional two columns:
	order_value with default value as -9999 (This column can not be null)
	order_description with default value as "Not defined" (This column can store null)


{
  "type" : "record",
  "name" : "orders_partition4",
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
  }, {
	"name" : "order_value",
	"type" : "int", 
	"default" : -9999
  }, {
	"name" : "order_description",
	"type" : ["string","null"],
	"default" : "Not Defined"
 }],
  "tableName" : "orders_partition2"
}	

53.2 hdfs dfs -put order_partition.avsc /HadoopExam/avrodata/

53.3 Create hive table using existing table:
#create table orders_partition2 (
order_id int, order_date bigint, order_customer_id int, order_value int, order_description string
)
stored as avro
Location '/user/hive/warehouse/flumedata.db/orders_sqoop'
tblproperties ("avro.schema.url"="hdfs://quickstart.cloudera/HadoopExam/avrodata/orders_partition.avsc") ;
	
54. Import joined data from mysql db. DO the join between categories and departments table based on department_id.

54.1 
#sqoop import \
--connect jdbc:mysql://quickstart:3306/retail_db \
--username retail_dba --password cloudera \
--query 'select categories.*, departments.* from categories JOIN departments ON (departments.department_id = categories.category_department_id) WHERE $CONDITIONS' \
--split-by categories.category_department_id \
--target-dir /HadoodExam/sqoopImport/Hadeoopexam1 \
-m 1

NOTE: for join query, "WHERE $CONDITIONS" [literal value] is required, but this is used by sqoop to control the job parallelism.

55. Create a Pig Script to find the result having wallet balance less than or equal to 100:
55.1 Create two files in hdfs:
/HadoopExam/pig/purchase.txt
/HadoopExam/pig/wallet.txt

55.2 Write a Pig Script:
purchase = LOAD '/HadoopExam/pig/purchase.txt' USING PigStorage ('|') AS (id:long, fname, lname, product, purchaseamount:int);
wallet = LOAD '/HadoopExam/pig/wallet.txt' USING PigStorage ('|') AS (id:long, walletamount:int);
joinedValues = JOIN purchase by id, wallet by id ;
joinedFiltered = FILTER joinedValues BY (walletamount - purchaseamount) <= 100;
result = FOREACH joinedFiltered GENERATE fname, (walletamount - purchaseamount);
STORE result INTO '/HadoopExam/pig/result01' USING PigStorage ('|');

Note: FILTER must be in boolean value

56. to remove duplicate using rank function:
#create table duplicate_purchase as 
	(select fname, item, price from (
		select fname, item, price, rank() over (partition by fname, item order by price desc) rnk
		 from purchase) rank_table) where rank_table.rnk=1 ;

57. Join two tables. Order by all the salesman based on their sales amount and rank them as per their position.
	Order sales man based on their sales with teritory
57.1 create Hive Tables and load data into them:
# create table salesman (
repid int, repname string, territory int
) 
row format delimited
fields terminated by ','
lines terminated by '\n' ;

# load data local inpath '/home/cloudera/HadoopExam/sales' into table salesman;

# create table purchases (
salesrepid int, purchaseorderid int, amount int
)
row format delimited
fields terminated by ','
lines terminated by '\n' ;

# load data local inpath '/home/cloudera/HadoopExam/purchases.csv' into table purchases;

57.2 Join both tables:
# select p.purchaseorderid, s.repname, p.amount, s.territory
from purchases p 
join salesman s
where p.salesrepid = s.repid;

57.3 Order by all the SalesMan based on their sales amount and rank them as per their position:
# select s.repname, s.territory, v.volume,
rank() over (order by v.volume DESC) as rank
from salesman s
Join (
select salesrepid, sum(amount) as volume 
from purchases 
group by salesrepid) v
where v.salesrepid = s.repid
order by v.volume desc ;

57.4 Order salesman bases on their sales within territory:
# select s.repname, s.territory, v.volume, 
rank() over (partition by s.territory order by v.volume desc) as rank
from 
salesman s
join 
(select 
salesrepid, sum(amount) as volume
from purchases
group by salesrepid) v
where v.salesrepid = s.repid
order by v.volume desc;

58. Oozie 
58.1 create a parameter file in hdfs /HadoopExam/OozieHadoopExam/option.par :
--connect
jdbc:mysql://quickstart:3306/retail_db
--username
retail_db
--password
cloudera
--table
departments_new
--split-by
department_id
--target-dir
/HadoopExam/sqoopImport/departments_new
-m
1

58.2 create a workflow.xml file in hdfs /HadoopExam/OozieHadoopExam/workflow.xml

<workflow-app xmlns='uri:oozie:workflow:0.4' name='sqoop-workflow'>
	<start to='sqoop-import'/>
	
	<action name="sqoop-import">
		<sqoop xmlns="uri:oozie:sqoop-action:0.2">
			<job-tracker>${jobTracker}</job-tracker>
			<name-node>${nameNode}</name-node>
			<configuration>
				<property>
					<name>mapred.job.queue.name</name>
					<value>${queueName}</value>
				</property>
			</configuration>
			<command> import --connect jdbc:mysql://localhost/retail_db --username retail_db --password cloudera --table departments_new --split-by department_id --target-dir /HadoopExam/sqoopImport/departments_new -m 1 </command>
		</sqoop>
		<ok to="end"/>
		<error to="sqoop-import-fail"/>
	</action>
	<kill name="sqoop-import-fail">
		<message>Sqoop import failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
	</kill>
	
	<end name='end' />
</workflow-app>

58.3 properties file:
#Location of the Name node
nameNode=hdfs://quickstart.cloudera:8020

#Location of the Resource Manager
jobTracker=quickstart.cloudera:8032

#Queue Name in which your job will be submitted
queueName=default

#Root Directory of our application.
examplesRoot=OozieHadoopExam

#Name of the xml file in which our Oozie workflow is configured.
oozie.wf.application.path=${nameNode}/HadoopExam/${examplesRoot}/workflow.xml

#This property will be used in workflow.xml, and reducer will use to write its output.
#outputDir=map-reduce
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib

optionFile=option.par

59. Workflow for export sqoop. Export departments_new data from hdfs to mysql table departments_export: 

59.1 create a new table departments_export in mysql

59.2 workflow.xml file in HDFS /HadoopExam/Oozie/workflow1/workflow.xml:
<workflow-app xmlns='uri:oozie:workflow:0.4' name='sqoop-export-workflow'>
        <start to='sqoopAction'/>
                <action name="sqoopAction">
                        <sqoop xmlns="uri:oozie:sqoop-action:0.2">
                                <job-tracker>${jobTracker}</job-tracker>
                                <name-node>${nameNode}</name-node>
                                <command>export --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera --table departments_export --batch --export-dir /HadoopExam/sqoopImport/departments_new</command>
                        </sqoop>
                        <ok to="end"/>
                        <error to="sqoop-export-fail"/>
                </action>
        <kill name="sqoop-export-fail">
                <message>"Sqoop export failed, error message:${wf:errorMessage(wf:lastErrorNode())}"]</message>
        </kill>

        <end name="end" />
</workflow-app>

59.3 Create a job.properties file in local:
nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032
queueName=default

examplesRoot=workflow1

oozie.wf.application.path=${nameNode}/HadoopExam/Oozie/${examplesRoot}/workflow.xml
#hdfs://quickstart.cloudera:8020/HadoopExam/Oozie/workflow1/workflow.xml

oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib

59.4 Run oozie server:

#cd /etc/init.d/ ==> service oozie start  ==> service hadoop-yarn-resourcemanager start
#oozie job -oozie http://quickstart.cloudera:11000/oozie -config job.properties -run

60. Write a pig script which will generate data, having visits more than 15 and write output to hdfs which is sorted by visits.
	Create oozie workflow and run pig script in workflow. 

60.1 save Pig script: webvisitors.pigscript in hdfs /HadoopExam/Oozie/workflow2/webvisitors.pigscript

webvisitors = load '/HadoopExam/Oozie/workflow2/webvisitors.txt' using PigStorage (',') as (name, website, course, visits);
web_filter = Filter webvisitors by visits > $visitsCount;
web_order = Order web_filter by visits;
store web_order into '$output' using PigStorage(',');

[Note: Do not forget to save the data file in hdfs. /HadoopExam/Oozie/workflow2 
		output folder should be new folder]

60.2 Test the pig script locally:
#pig -Dmapreduce.job.queuename=default -f webvisitors.pigscript -param visitsCount=15 -param output=/HadoopExam/Oozie/workflow2/test_output

60.3 Create workflow.xml file at /HadoopExam/Oozie/workflow2
<?xml version="1.0" encoding="UTF-8"?>
<workflow-app xmlns='uri:oozie:workflow:0.4' name='pig-workflow'>
	<start to='pig-action'/>
	<action name="pig-action">
		<pig>
			<job-tracker>${jobTracker}</job-tracker>
			<name-node>${nameNode}</name-node>
			<prepare>
				<delete path="/HadoopExam/Oozie/workflow2/output" />
			<prepare>
			<configuration>
				<property>
					<name>mapred.job.queue.name</name>
					<value>${queueName}</value>
				</property>
			</configuration>	
			<script>webvisitors.pigscript</script>
			<argument>-param</argument>
			<argument>visitsCount=15</argument>
			<argument>-param</argument>
			<argument>output=/HadoopExam/Oozie/workflow2/output</argument>
		</pig>
		<ok to="end" />
		<error to="script-fail"/>
	</action>
	<kill name="script-fail">
		<message>Pig Script failed, error message[${wf:errorMessage(wf:lastErrorNode())}]</message>
	</kill>
	<end name='end' />
</workflow-app>

60.4 Create job.properties file locally:

nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032

queueName=default

oozie.wf.application.path=${nameNode}/HadoopExam/workflow2/workflow.xml

oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib

60.5. Run oozie
oozie job -oozie http://quickstart.cloudera:11000/oozie -config job.properties -run
	
61. Using Oozie workflow, change the permission of folder in hdfs:

61.1 create a folder input in hdfs and dump some files in it.

61.2 workflow.xml file:
<?xml version="1.0" encoding="UTF-8"?>
<workflow-app xmlns='uri:oozie:workflow:0.4' name='fs-workflow'>
	<start to='chmod-action' />
	<action name="chmod-action" >
		<fs>
			<name-node>${nameNode}</name-node>
			<delete path='/HadoopExam/Oozie/workflow3/input'/>
			<mkdir path='/HadoopExam/Oozie/workflow3/input'/>
			<chmod path='/HadoopExam/Oozie/workflow3/' permission='777' dir-files='true'>
				<recursive/>
			</chmod>
		</fs>
		<ok to="end"/>
		<error to="fail" />
	</action>
	<kill name="fail" >
		<message> FS Command Script failed, error message [${wf:errorMessage(wf:lastErrorNode())}]</message>
	</kill>
	<end name='end' />
</workflow-app>

61.3 job.properties file:

nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032

queueName=default
examplesRoot=workflow3

oozie.wf.application.path=${nameNode}/HadoopExam/Oozie/{examplesRoot}/workflow.xml

oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib

61.3 Run the oozie command:
oozie job -oozie http://quickstart.cloudera:11000/oozie -config job.properties -run

62. create a table for log file in mysql. Write a pig script using regex separation and store output at hdfs.
	Using oozie workflow, run pig script. create a subworkflow (child workflow) to export data from pig output to mysql table.

62.1 save file.log data file in hdfs /HadoopExam/Oozie/workflow3/file.log
Jul 7 22:53:31 hadoopexam-n1 root: registered taskstats version1
Jul 7 22:53:31 hadoopexam-n1 root: sr0: scsi3-mmc drive: 32x/32x xa/form2 tray

62.2 Create table in mysql:
#create table file_log (month varchar(4), date int, time varchar(8), machineId varchar(15), processId varchar(15), logmessage varchar(100) );

62.2 Pig script to separate log data into column. Save it at hdfs /HadoopExam/Oozie/workflow4/
logdata = load '/HadoopExam/Oozie/workflow4/file.log';

separatetocolumn = FOREACH logdata GENERATE \
FLATTEN(REGEX_EXTRACT_ALL($0, '(\\w+)[ ]+(\\d+)[ ]+(\\d+:\\d+:\\d+)[ ]+([^ ]+)[ ]+([^:]*):[ ]+(.*)')) \
AS (month_name, day, time, node, process, logmessage);

STORE separatetocolumn INTO '$output' using PigStorage();

62.3 job.properties:
#Location of the Name node
nameNode=hdfs://quickstart.cloudera:8020

#Location of the Resource Manager
jobTracker=quickstart.cloudera:8032

#Queue Name in which job will be submitted
queueName=default

#Name of the xml file in which out Oozie workflow configured.
oozie.wf.application.path=${nameNode}/HadoopExam/Oozie/workflow4/workflow.xml

#This property will be used in workflow.xml, and reducer will use to write its output
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib

#For pig script action:
#----------------------
#Path where output of pig action will be stored
output=/HadoopExam/Oozie/workflow4/output

#We will be using this shell command to check. However, will be executed on hdfs.
recordCount=`cat /HadoopExam/Oozie/workflow4/file.log | wc -l`

#minimum number of records required to process this file
requiredRecordCount=1

#For subworkflow having sqoop-action:
#-------------------------------------
#Directory where subworkflow application
subWorkflowCodeDir=/HadoopExam/Oozie/workflow4/subworkflow

#We will be using this shell command to check. However, will be executed on hdfs.
sqoopInputRecordCount=`cat /HadoopExam/Oozie/workflow4/output | wc -l`
minRequiredRecordCount=1

62.4 Workflow.xml 
<workflow-app name="pigAction-parent" xmlns='uri:oozie:workflow:04'>
	<start to="dataValidation"/>
		<decision name="dataValidation" >
			<switch>
				<case to="generateData">
					${recordCount gt requiredRecordCount}
				</case>
				<default to="end" />
			</switch>
		</decision>
	<action name="generateData">
		<pig>
			<job-tracker>${jobTracker} </job-tracker>
			<name-node>${nameNode} </name-node>
			<prepare>
				<delete path="/HadoopExam/Oozie/workflow4/output" />
			</prepare>
			<configuration>
				<property>
					<name>mapred.job.queue.name</name>
					<value>${queueName}</value>
				</property>
			</configuration>
			<script>logfile.script</script>
			<argument>-param</argument>
			<argument>output=/HadoopExam/Oozie/workflow4/output</argument>
		</pig>
			<ok to="dataExporterSubworkflow" />
			<error to="killJob" />
	</action>
	<action name="dataExporterSubworkflow" />
		<sub-workflow>
			<app-path>${subWorkflowCodeDir}</app-path>
			<propagate-configuration/>
		</sub-workflow>
	<ok to="end" />
	<error to="killJob" />
	
	</action>
		<kill name="killJob" >
			<message>"Killed job due to error: ${wf:errorMessage(wf:lastErrorNode())}" </message>
		</kill>
		<end name="end" />
</workflow-app>

62.4 SubWorkFlow--> workflow.xml
<workflow-app name="subworkflow" xmlns="uri:oozie:workflow:0.4">
    <decision name="dataValidationSubworkflow">
		<switch>
			<case to="finalAction">
				${sqoopInputRecordCount gt minRequiredRecordCount}
			</case>
			<default to="end" />
		</switch>
	</decision>
    <action name="finalAction">
        <sqoop xmlns="uri:oozie:sqoop-action:0.2">
			<job-tracker>${jobTracker} </job-tracker>
			<name-node> ${nameNode} </name-node>
			<!--configuration>
                <property>
                    <name>oozie.libpath</name>
                    <value>${oozieLibPath}}</value>
                </property>
            </configuration> -->
			<command>export --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera --table file_log --direct --export-dir /HadoopExam/Oozie/workflow4/output --fields-terminated-by "\t" </command>
		</sqoop>
		<ok to="end"/>
        <error to="killJob"/>
    </action>
	<kill name="killJob" >
		<message> "Killed job due to error: ${wf:errorMessage (wf:lastErrorNode())}" </message>
	</kill>
	<end name="end" />
</workflow-app>

63.

63.1 pigscript file:
file_log = load '/HadoopExam/Oozie/workflow5/file1.log';
separate_log = Foreach file_log Generate Flatten(REGEX_EXTRACT_ALL($0,'(\\w+)[ ]+(\\d+)[ ]+(\\d+:\\d+:\\d+)[ ]+([^ ]+)[ ]+([^:]*):[ ]+(.*)')) AS (month_name, day, time, node, process, logmessage);
store separate_log into '$output' using PigStorage();

63.2 Workflow file:
<workflow-app name="pigaction-parent" xmlns="uri:oozie:workflow:0.4">
    <start to="dataValidation"/>
		<decision name="dataValidation">
			<switch>
				<case to="generateData">
					${recordCount gt requiredRecordCount}
				</case>
				<default to="end"/>
			</switch>
		</decision>
    <action name="generateData">
		<pig>
			<job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <prepare>
               <delete path="/HadoopExam/Oozie/workflow5/output"/>
            </prepare>
            <configuration>
                <property>
                    <name>mapred.job.queue.name</name>
                    <value>${queueName}</value>
                </property>
            </configuration>
            <script>pigfile.script</script>
            <argument>-param</argument>
            <argument>output=/HadoopExam/Oozie/workflow5/output</argument>
        </pig>
		<ok to="dataExporterSubworkflow"/>
        <error to="killJob"/>
    </action>
	 <action name="dataExporterSubworkflow">
        <sub-workflow>
            <app-path>${subWorkflowCodeDir}</app-path>
            <propagate-configuration/>
		</sub-workflow>
        <ok to="SqoopImportAction"/>
        <error to="killJob"/>
    </action>
	<!--Sqoop Action -->
	<action name="sqoopImportAction">
        <sqoop xmlns="uri:oozie:sqoop-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <command>import --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera --table file1_log --hive-import -m 1</command>
            <file>/HadoopExam/Oozie/workflow5/hive-site.xml</file>
        </sqoop>
        <ok to="hiveAction"/>
        <error to="killJob"/>
    </action>
	<!--Hive Action -->
	<action name="hiveAction">
        <hive xmlns="uri:oozie:hive-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <job-xml>/HadoopExam/Oozie/workflow5/hive-site.xml</job-xml>
            <script>/HadoopExam/Oozie/workflow5/hive_log.hql</script>
        </hive>
        <ok to="end"/>
        <error to="killJob"/>
    </action>
	<kill name="killJob">
		<message>"Killed job due to error: ${wf:errorMessage (wf:lastErrorNode())}"</message>
	</kill>
	<end name ="end" />
</workflow-app>

63.3 sub-workflow file:
<workflow-app name="subworkflow" xmlns="uri:oozie:workflow:0.4">
    <start to="dataValidation"/>
		<decision name="dataValidation">
			<switch>
				<case to="finalAction">
					${sqoopInputRecordCount gt minRequiredRecordCount}
				</case>
				<default to="end"/>
			</switch>
    </decision>
    <action name="finalAction">
        <sqoop xmlns="uri:oozie:sqoop-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <!--<configuration>
                <property>
                    <name>oozie.libpath</name>
                    <value>${oozieLibPath}</value>
                </property>
            </configuration> -->
            <command>export --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera --table file1_log --direct --export-dir /HadoopExam/Oozie/workflow5/output --fields-terminated-by "\t"</command>
        </sqoop>
        <ok to="end"/>
        <error to="killJob"/>
    </action>
	<kill name="killJob">
		<message>"Killed job due to error:${wf:errorMessage(wf:lastErrorNode())}"</message>
	</kill>
	<end name="end" />
</workflow-app>
 
63.4 hive_log.hql file:
use default;
drop table node_hadoopexam;
drop table node_quicktechie;
drop table node_training4exam;

create table if not exists node_hadoopexam (
month string, date int, time string, processId string, logmessage string)
row format delimited
fields terminated by ','
lines terminated by '\n';

create table if not exists node_quicktechie (
month string, date int, time string, processId string, logmessage string)
row format delimited
fields terminated by ','
lines terminated by '\n';

create table if not exists node_training4exam (
month string, date int, time string, processId string, logmessage string)
row format delimited
fields terminated by ','
lines terminated by '\n';

Insert overwrite table node_hadoopexam
select month, date, time, processId, logmessage from file1_log where machineId like '%hadoopexam%';
Insert overwrite table node_quicktechie
select month, date, time, processId, logmessage from file1_log where machineId like '%quicktechie%';
Insert overwrite table node_training4exam
select month, date, time, processId, logmessage from file1_log where machineId like '%training4exam%';

63.5 job.properties file:
#location of the Name Node
nameNode=hdfs://quickstart.cloudera:8020

#Location of the resource manager
jobTracker=quickstart.cloudera:8032

#Queue name in which job will be submitted
queueName=default

#Name of the xml file which our Oozie workflow configured
oozie.wf.application.path=${nameNode}/HadoopExam/Oozie/workflow5/workflow}

#This property will be used in workflow.xmlm and reducer will be use to write its output
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib

#For Pig script action:
#-----------------------
#Path where output of pig action will be stored
output=/HadoopExam/Oozie/workflow5/output

#we will be using this shell command to check. However, will be executed on hdfs.
recordCount=`cat /HadoopExam/Oozie/workflow5/file1.log | wc -l`

#minimum number of records required to process the file
requiredRecordCount=1

#For sub-workflow having sqoop action
#--------------------------------------
#DIRECTORY where sub-workflow application
subWorkflowCodeDir=/HadoopExam/Oozie/workflow5/subworkflow

#We will be using this shell command to check. However, will be exe
ted on hdfs
sqoopInputRecordCount=`cat /HadoopExam/Oozie/workflow5/output | wc -l`
minRequiredRecordCount=1

64. Write a shell action in OOzie workflow to execute the shell script file.
	once data is uploaded in hdfs, write a pig script to parse the log file
	create hive external table to load parsed data by pig script
	
64.1 create a Shell script(shellfile.sh) and copy to hdfs:
hadoop fs -put /home/cloudera/HadoopExam/workflow6/data.log /HadoopExam/Oozie/workflow6/
status=$?
if [ $status = 0 ]
then
echo "Status = Success!"
else
echo "Status = Fail!"
fi

64.2 job.properties file:
nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032
queueName=default
oozie.wf.application.path=${nameNode}/HadoopExam/Oozie/workflow6/workflow.xml
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib

#shell action parameter
shellScriptPath=/HadoopExam/Oozie/workflow6/shellfile.sh
shellScript=shellfile.sh

#for data validation:
recordCount=`cat /HadoopExam/Oozie/workflow6/data.log | wc -l`
requiredRecordCount=1
#For pig script:
#Path where output of pig action will be stored.
output=/HadoopExam/Oozie/workflow6/output

#Hive setting file:
hive_site=/HadoopExam/Oozie/workflow6/hive-site.xml
hive_script=/HadoopExam/Oozie/workflow6/hivefile.ql

64.3 create a pig script(pigfile.script)  and copy to hdfs:
file_log = load '/HadoopExam/Oozie/workflow6/data.log';
separate_log = Foreach file_log Generate Flatten(REGEX_EXTRACT_ALL($0,'(\\w+)[ ]+(\\d+)[ ]+(\\d+:\\d+:\\d+)[ ]+([^ ]+)[ ]+([^:]*):[ ]+(.*)')) AS (month_name, day, time, node, process, logmessage);
store separate_log into '$output' using PigStorage();

64.4 Hive query file(hivefile.ql):
create external table if not exists hive_import (
month string, date int, time string, processId string, logmessage string)
row format delimited
fields terminated by ','
lines terminated by '\n'
location '$output';


64.3 Workflow.xml
<workflow-app name="HadoopExamProb64" xmlns="uri:oozie:workflow:0.4">
    <start to="dataValidation" />
    <decision name="dataValidation">
        <switch>
            <case to="dataCopyToHdfs">
				${recordCount gt requiredRecordCount}
			</case>
            <default to="end"/>
        </switch>
    </decision>
    <action name="dataCopyToHdfs">
		<shell xmlns="uri:oozie:shell-action:0.1">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <configuration>
                <property>
                  <name>mapred.job.queue.name</name>
                  <value>${queueName}</value>
                </property>
            </configuration>
            <exec>${shellScriptPath}</exec>
            <file>${shellScriptPath}#${shellScript}</file> <!--Copy the executable to compute node's current working directory -->
		</shell>
		<ok to="generateDataByPig"/>
		<error to="killJob"/>
	</action>
	<action name="generateDataByPig">
	<pig>
		<job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <prepare>
                <delete path="${output}"/>
            </prepare>
            <configuration>
                <property>
                    <name>mapred.job.queue.name</name>
                    <value>${queueName}</value>
                </property>
            </configuration>
            <script>pigfile.script</script>
            <argument>-param</argument>
            <argument>output=${output}</argument>
	</pig>
		<ok to="hive-action"/>
		<error to="killJob"/>
	</action>
	<action name="hive-action">
		<hive xmlns="uri:oozie:hive-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <job-xml>${hive_site}</job-xml>
            <script>${hive_script}</script>
        </hive>
        <ok to="end"/>
        <error to="killJob"/>
    </action>
	<kill name="killJob">
		<message>"Killed job due to error: ${wf:errorMessage(wf:lastErrorNode())}"</message>
	</kill>
	<end name="end" />
		
</workflow-app>

65. import all the tables from mysql to hive using oozie workflow:

65.1 job.properties file:
nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032
queueName=default
oozie.wf.application.path=${nameNode}/HadoopExam/Oozie/workflow7/workflow.xml
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib
hive_site=/HadoopExam/Oozie/workflow7/hive-site.xml

65.2 workflow.xml file:
<workflow-app name="importTable" xmlns="uri:oozie:workflow:0.1">
    <start to="sqoop-action" />
    <action name="sqoop-action">
        <sqoop xmlns="uri:oozie:sqoop-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <configuration>
                <property>
                    <name>mapred.job.queue.name</name>
                    <value>${queueName}</value>
                </property>
            </configuration>
            <command>import --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera --table customers --hive-import --hive-overwrite --hive-table customers_oozie -m 3</command>
			<file>${hive_site}</file>
		</sqoop>
        <ok to="end"/>
        <error to="killJob"/>
    </action>
    <kill name="killJob">
		<message>"Killed job due to error: ${wf:errorMessage(wf:lastErrorNode())}"</message>
	</kill>
	<end name="end"/>
</workflow-app>

66. Fork & Join action for orders and departments tables:[In fork both actions will run parrallely]
66.1 Workflow file:
<workflow-app name="fork-wf" xmlns="uri:oozie:workflow:0.1">
    <start to="forking" />
    <fork name="forking">
        <path start="orders"/>
        <path start="departments"/>
    </fork>
    <action name="orders">
        <sqoop xmlns="uri:oozie:sqoop-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <configuration>
                <property>
                    <name>mapred.job.queue.name</name>
                    <value>${queueName}</value>
                </property>
            </configuration>
            <command>import  --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera --table orders --hive-import --hive-overwrite --hive-table orders_oozie -m 1</command>
			<file>${hive_site}</file>
		</sqoop>
        <ok to="joining"/>
        <error to="killJob"/>
    </action>
    <action name="departments">
        <sqoop xmlns="uri:oozie:sqoop-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <configuration>
                <property>
                    <name>mapred.job.queue.name</name>
                    <value>${queueName}</value>
                </property>
            </configuration>
            <command>import  --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera --table departments --hive-import --hive-overwrite --hive-table departments_oozie -m 1</command>
			<file>${hive_site}</file>
		</sqoop>
        <ok to="joining"/>
        <error to="killJob"/>
    </action>
	<join name="joining" to="end" />
    <kill name="killJob">
		<message>"Killed due to error: ${wf:errorMessage (wf:lastErrorNode())}"</message>
	</kill>
	<end name="end" />
</workflow-app>

66.2 job.properties :
nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032
queueName=default
hdfspath=/HadoopExam/Oozie/fork
oozie.wf.application.path=${nameNode}${hdfspath}/workflow.xml
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib
hive_site=${hdfspath}/hive-site.xml

67.Using oozie, import table categories from mysql using \`category_id\` between 1 to 10:
[NOTE: for the where clause arguments should use instead of command line.]
67.1 workflow
<workflow-app name="sqoopWithWhere" xmlns="uri:oozie:workflow:0.4">
	<start to="categories" />
	<action name="categories">
        <sqoop xmlns="uri:oozie:sqoop-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <configuration>
                <property>
                    <name>mapred.job.queue.name</name>
                    <value>${queueName}</value>
                </property>
            </configuration>
            <arg>import</arg>
			<arg>--connect</arg>
			<arg>jdbc:mysql://quickstart:3306/retail_db</arg>
			<arg>--username</arg>
			<arg>retail_dba</arg>
			<arg>--password</arg>
			<arg>cloudera</arg>
			<arg>--table</arg> 
			<arg>departments</arg>
			<arg>--hive-import</arg>
			<arg>--hive-overwrite</arg>
			<arg>--hive-table</arg>
			<arg>categories_oozie</arg>
			<arg>--where</arg>
			<arg>"category_id between 1 and 5"</arg>
			<arg>-m</arg>
			<arg>1</arg>
			<file>/HadoopExam/Oozie/fork/hive_site.xml</file>
		</sqoop>
        <ok to="end"/>
        <error to="killJob"/>
    </action>
	<kill name="killJob">
		<message>"Killed due to error: ${wf:errorMessage (wf:lastErrorNode())}"</message>
	</kill>
	<end name="end" />
</workflow-app>

67.2 job.properties :
nameNode=hdfs://quickstart.cloudera:8020/HadoopExam/Oozie/
jobTracker=quickstart.cloudera:8032
queueName=default
hdfspath=/HadoopExam/Oozie/fork
oozie.wf.application.path=${nameNode}${hdfspath}/workflow.xml
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib
hive_site=${hdfspath}/hive-site.xml

68.create and Move files from one source to another using oozie and once this task is done email with message:
68.1 Workflow file:
<workflow-app name="fileTransferEmail" xmlns="uri:oozie:workflow:0.4">
    <start to="createContent" />
    <action name="createContent">
        <fs>
			<mkdir path='${nameNode}${hdfspath}/test68'/>
			<touchz path='${nameNode}${hdfspath}/test68/test.log1' />
			<touchz path='${nameNode}${hdfspath}/test68/test.log2' />
		</fs>
		<ok to="moveContent" />
		<error to="killJob" />
	</action>
	<action name="moveContent">
		<fs>
			<mkdir path='${nameNode}/${hdfspath}/test68_1' />
            <move source='${nameNode}/${hdfspath}/test68/*' target='${nameNode}/${hdfspath}/test68_1/'/>
            <chmod path='${nameNode}/${hdfspath}/test68_1' permissions='-rwxrw-rw-' dir-files='true'><recursive/></chmod>
        </fs>
        <ok to="sendEmail"/>
        <error to="killJob"/>
    </action>
	<action name="sendEmail">
		<email xmlns="uri:oozie:email-action:0.1">
            <to>samitamaharjan@gmail.com,samita.maharjan@hotmail.com</to>
            <cc>maharjan.samita01@gmail.com</cc>
            <subject>Data Processing</subject>
            <body>Dear User,
			Your data file has been processed sucessfullt.
			Thanks.
			Samita</body>
        </email>
        <ok to="end"/>
        <error to="killJob"/>
    </action>
    <kill name="killJob">
		<message>"Killed due to error: ${wf:errorMessage(wf:lastErrorNode()}"</message>
	</kill>
	<end name="end" />
</workflow-app>

70. 
Jul  7 22:52:54 quicktechie-n1 pwd: tty (/dev/tty6) main process (1500) killed by TERM signal
Jul  7 22:53:31 quicktechie-n1 root: registered taskstats version 1

70.1 create external hive table:
# create external table hadoopexam_70 (
month_name string, date string, time string, host string, event string, logmessage string
)
partitioned by (node string, year int, month int)
row format SERDE 'org.apache.hadoop.hive.contrib.serde2.RegexSerDe'
with serdeproperties (
'input.regex'='(\\w+)[ ]+(\\d+)[ ]+(\\d+:\\d+:\\d+)[ ]+([^ ]+)[ ]+([^\\:]+):[ ]+(.*)'
)
stored as textfile;

70.2 insert data into hive table:
#alter table hadoopexam_70 add partition (node="hadoopexam", year=2016, month=7)
location '/HadoopExam/Oozie/test70/logs';

#alter table hadoopexam_70 add partition (node="quicktechie", year=2016, month=7)
location '/HadoopExam/Oozie/test70/logs';

#alter table hadoopexam_70 add partition (node="training4exam", year=2016, month=7)
location '/HadoopExam/Oozie/test70/logs';

70.3 hive_script:
use flumedata;
create table new_hadoopexam_70 as
select year, month, date, event, count(*)
from hadoopexam_70
group by year, month, date, event
order by event asc, year, month, date desc;

[PROBLEM (While running count in hive):]
Caused by: java.lang.ClassNotFoundException: Class org.apache.hadoop.hive.contrib.serde2.RegexSerDe not found

[FIX:]
#In local:
export HIVE_AUX_JARS_PATH=/usr/lib/hive/lib/hive-contrib.jar

Or, add the below property to hive-site.xml for oozie workflow:
<property> 
  <name>hive.aux.jars.path</name> 
  <value>/user/oozie/share/lib/hive/hive-contrib.jar</value>
</property>

70.4 workflow file:
<workflow-app name="hive-wf" xmlns="uri:oozie:workflow:0.1">
    <start to="orderBy" />
    <action name="orderBy">
        <hive xmlns="uri:oozie:hive-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <configuration>
                <property>
                    <name>mapred.job.queue.name</name>
                    <value>${queueName}</value>
                </property>
                <property>
            </configuration>
            <script>${hive_script}</script>
			<job-xml>${hive_site}</job-xml>
        </hive>
        <ok to="end"/>
        <error to="errorcleanup"/>
    </action>
    <kill name="errorcleanup">
		<message>"Killed due to error: ${wf:errorMessage (wf:lastErrorNode())}"</message>
	</kill>
	<end name="end" />
</workflow-app>

70.5 job.properties file:
nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032
queueName=default
hdfspath=/HadoopExam/Oozie/test70
oozie.wf.application.path=${nameNode}${hdfspath}/workflow.xml
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib
hive_script=${nameNode}${hdfspath}/hive_script.ql
hive_site=${nameNode}${hdfspath}/hive-site.xml

71. 
71.1 [http:www.HadoopExam.com/Cloudera_Certification/CCPDE575/hadoopexam18_Java.zip]
	save to hdfs with separate lib folder: /HadoopExam/Oozie/test_71/lib/...jar
71.2 job.properties file:
nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032
queueName=default
hdfspath=/HadoopExam/Oozie/test_71
oozie.wf.application.path=${nameNode}${hdfspath}/workflow.xml
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib

dataInputDir=${nameNode}${hdfspath}/data/input
outputDir=${nameNode}${hdfspath}/data/output
earthquakeMinThreshold=1.0

71.3 filter-data.pig file:
A = load '$INPUT' using PigStorage(',') as (a1,a2,a3,a4,a5:float,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15);
B = Filter A by (a5 >= $MINMAG);
store B into '$OUTPUT' using PigStorage(',');

71.4 workflow file:
<workflow-app xmlns="uri:oozie:workflow:0.4" name="test71">
	<global>
		<job-tracker>${jobTracker}</job-tracker>
		<name-node>${nameNode}</name-node>
		<configuration>
			<property>
				<name>mapred.job.queue.name</name>
				<value>${queueName}</value>
			</property>
		</configuration>
	</global>
	
<start to="shell-check-hour" />
	<action name="shell-check-hour">
		<shell xmlns="uri:oozie:shell-action:0.3">
			<exec>/HadoopExam/Oozie/test_71/check-hour.sh</exec>
			<argument>${earthquakeMinThreshold}</argument>
			<file>/HadoopExam/Oozie/test_71/check-hour.sh#check-hour.sh</file>
			<capture-output/>
		</shell>
		<ok to="decide"/>
		<error to="fail" />
	</action>
	
	<decision name="decide">
		<switch>
			<case to="get-data">
				${actionData('shell-check-hour')['isLarger']} <-- actionData(string actionName) used to check the result of action -->
			</case>
			<default to="end" />
		</switch>
	</decision>
	<action name="get-data">
		<java>
			<prepare>
				<delete path="${dataInputDir}" />
				<mkdir path="${dataInputDir}" />
			</prepare>
			<main-class>com.cloudera.earthquake.GetData</main-class>
			<arg>${dataInputDir}</arg>
		</java>
		<ok to="filter-data"/>
		<error to="fail"/>
	</action>
	
	<action name="filter-data">
		<pig>
			<prepare>
				<delete path="$outputDir"/>
			</prepare>
			<script>filter-data.pig</script>
			<param>INPUT=${dataInputDir}</param>
			<param>OUTPUT=${outputDir}</param>
			<param>MINMAG=${wf:actionData('shell-check-hour')['largest']}</param>
		</pig>
		<ok to="end" />
		<error to="fail" />
	</action>
	
	<kill name="fail">
		<message>"Workflow failed, error message[${wf:errorMessage(wf:lastErrorNode())}]"</message>
	</kill>
	
	<end name="end" />
</workflow-app>	

72. Trigger the data daily every 5 mins from 18:15PM., July19,2016 to 11:30 P.M., December 31, 2016.
72.1 job.properties file:
nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032
queueName=default
hdfspath=/HadoopExam/Oozie/test_72

oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib

dataInputDir=${nameNode}${hdfspath}/data/input
outputDir=${nameNode}${hdfspath}/data/output
earthquakeMinThreshold=1.0

oozie.coord.application.path=${nameNode}${hdfspath}
wf_application_path=${nameNode}/HadoopExam/Oozie/test_71

72.2 Coordinator.xml file:
<coordinator-app name="test_72" start="2016-07-19T18:15Z" end="2016-12-31T23:30Z" frequency="5" timezone="UTC" xmlns="uri:oozie:coordinator:0.4">
<action>
<workflow>
	<app-path>${wf_application_path}</app-path>
	<configuration>
	<property>
		<name>nameNode</name>
		<value>${nameNode}</value>
	</property>
	<property>
		<name>jobTracker</name>
		<value>${jobTracker}</value>
	</property>
	</configuration>
</workflow>
</action>
</coordinator-app>

74.
74.1 job.properties file:
nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032
queueName=default
hdfspath=/HadoopExam/Oozie/test_74
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib

oozie.coord.application.path=${nameNode}${hdfspath}/app/coordinator.xml

cordStartTime=2016-08-18T00:00Z
cordEndTime=2016-08-18T01:30Z
timeZoneUsed=UTC

allWorkflowPath={nameNode}${hdfspath}/app/allWorkflows
subWorkflowPath=${nameNode}${hdfspath}/app/workflow.xml
hive_script=${nameNode}${hdfspath}/app/hive_script.ql
hive_site=${nameNode}${hdfspath}/app/hive-site.xml

dirToCheck=${nameNode}${hdfspath}/data/success
dataDir=${nameNode}${hdfspath}/201607/data.log

lineCount=`cat ${dataDir} | wc -l`
minLineCount=1

74.2 coordinator.xml file:
<coordinator-app name="test74" frequency="${coord:minutes(45)}"
	start="${cordStartTime}" end="${cordEndTime}" timezone="${timeZoneUsed}"
	xmlns="uri:oozie:coordinator:0.4">
		<controls>
			<timeout>10</timeout>
			<concurrency>1</concurrency>
			<execution>FIFO</execution>
		</controls>
		<datasets>
			<dataset name="hadoopExamInput" frequency="${coord:minutes(45)}" initial-instance="cordStartTime" timezone="${timeZoneUsed}">
				<uri-template>${dirToCheck}</uri-template>
			</dataset>
		</datasets>
		<input-events>
			<data-in name="HadoopExamDataIn" dataset="hadoopExamInput">
				<instance>${cordStartTime}</instance>
			</data-in>
		</input-events>
		<action>
			<workflow>
				<app-path>${allWorkflowPath}</app-path>
			</workflow>
		</action>
</coordinator-app>


75.
75.1 create a mysql table:
create table hadoopexam22_log
(
month varchar(5), date int(3), time varchar(10), machineId varchar(20), processId varchar(10), logmessage varchar(100)
);

75.2 Pig script to separate all 6 fields of log file data:
log1 = load '$input';
separate_regex =  FOREACH log1 generate FLATTEN(REGEX_EXTRACT_ALL($0, '(\\w+)[ ]+(\\d+)[ ]+(\\d+:\\d+:\\d+)[ ]+([^ ]+)[ ]+([\\w^\\:]+):[ ]+(.*)')) as month, date, time, machineId, processId, logmessage;
store separate_regex into '$output' using PigStorage('\t');

75.3 job1.properties file:
nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032
queueName=default
hdfspath=/HadoopExam/Oozie/test_75
oozie.wf.application.path=${nameNode}${hdfspath}/workflow.xml
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib

requiredRecordCount=1
numberOfRecords=`cat /HadoopExam/Oozie/test_75/log_file.txt | wc -l`
pig_script=${nameNode}${hdfspath}/pig_script.pig
OUTPUT=${nameNode}${hdfspath}/output

75.4 Oozie workflow including decision to check log file contains at least 1 record before starting the process:
<workflow-app name="wf-test-75" xmlns="uri:oozie:workflow:0.4">
    <start to="dataValidation" />
    <decision name="dataValidation">
        <switch>
            <case to="pig-action">
			${numberOfRecords gt requiredRecordCount}
			</case>
            <default to="end"/>
        </switch>
    </decision>
    <action name="pig-action">
        <pig>
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <prepare>
               <delete path="${OUTPUT}"/>
            </prepare>
            <configuration>
                <property>
                    <name>map.job.queue.name</name>
                    <value>${queueName}</value>
                </property>
            </configuration>
            <script>${pig_script}</script>
            <param>output=${OUTPUT}</param>
        </pig>
        <ok to="end"/>
        <error to="killJob"/>
    </action>
	<kill name="killJob">
		<message>"Job killed due to error: ${wf:errorMessage (wf:lastErrorNode())}" </message>
	</kill>
	<end name="end"/>
</workflow-app>

75.5 job2.properties
nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032
queueName=default
hdfspath=/HadoopExam/Oozie/test_75/
wf_application_path=${nameNode}${hdfspath}/cord/workflow.xml
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib
oozie.coord.application.path=${nameNode}${hdfspath}/cord/coordinator.xml

cordStartTime=2016-08-18T00:00Z
cordEndTime=2016-08-18T01:30Z
timeZoneUsed=UTC
requiredRecordCount=1
numberOfRecords=`cat /HadoopExam/Oozie/test_75/output/part* | wc -l`
dirToCheck=${nameNode}${hdfspath}/output

75.6. coordinator.xml
<coordinator-app name="coord-action" frequency="${coord:minutes(45)}"
                    start="${cordStartTime}" end="${cordEndTime}" timezone="${timeZoneUsed}"
                    xmlns="uri:oozie:coordinator:0.4">
	<controls>
		<timeout>10</timeout>
		<concurrency>1</concurrency>
		<execution>FIFO</execution>
	</controls>
		<datasets>
			<dataset name="input_dataset" frequency="${coord:minutes(45)}"
	             initial-instance="${cordStartTime}" timezone="${timeZoneUsed}">
			<uri-template>${dirToCheck}</uri-template>
        </dataset>
    </datasets>
	<input-events>
        <data-in name="datainput" dataset="input_dataset">
			<instance>${cordStartTime}</instance>
        </data-in>
    </input-events>
    <action>
        <workflow>
			<app-path>${wf_application_path}</app-path>
        </workflow>
	</action>
</coordinator-app>

75.7 workflow for coordinator app:
<workflow-app name="sample-wf" xmlns="uri:oozie:workflow:0.4">
    <start to="sqoop-action"/>
    <action name="sqoop-action">
        <sqoop xmlns="uri:oozie:sqoop-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <command>export --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera --table hadoopexam22_log --export-dir /HadoopExam/Oozie/test_75/output --direct --fields-terminated-by "\t" -m 1</command>
        </sqoop>
        <ok to="end"/>
        <error to="killJob"/>
    </action>
    <kill name="killJob">
		<message>"The job killed due to error: ${wf:errorMessage (wf:lastErrorNode())}"</message>
	</kill>
	<end name="end"/>
</workflow-app>

76.
76.1 create hadoopexam23_log table in mysql

76.2 job.properties file:
nameNode=hdfs://quickstart.cloudera:8020
jobTracker=quickstart.cloudera:8032
queueName=default
hdfspath=/HadoopExam/Oozie/test_76/
wf_application_path=${nameNode}${hdfspath}/workflow.xml
oozie.use.system.libpath=true
oozie.libpath=/user/oozie/share/lib
oozie.coord.application.path=${nameNode}${hdfspath}/coordinator.xml

cordStartTime=2016-10-14T18:20Z
cordEndTime=2016-08-18T20:30Z
timeZoneUsed=America/Los_Angeles
dirToCheck=${nameNode}${hdfspath}/output

76.3 coordinator application that runs for every 30 mins; assume data will be created in every 10 mins;
		coordinator should process data in..........
<coordinator-app name="coord-test-76" frequency="${coord:minutes(30)}"
                    start="${cordStartTime}" end="${cordEndTime}" timezone="${timeZoneUsed}"
                    xmlns="uri:oozie:coordinator:0.4">
	<controls>
		<timeout>10</timeout>
		<concurrency>1</concurrency>
		<execution>FIFO</execution>
	</controls>
	<datasets>
		<dataset name="logs_dataset" frequency="${coord:minutes(10)}"
	             initial-instance="${cordStartTime}" timezone="${timeZoneUsed}">
	      <uri-template>${dirToCheck}/${YEAR}-${MONTH}-${DAY}-${HOUR}-${MINUTE}</uri-template>
        </dataset>
    </datasets>
	<input-events>
        <data-in name="logs_input" dataset="logs_dataset">
			<start-instance>${cordStartTime}</start-instance>
			<end-instance>${cordEndTime}</end-instance>
        </data-in>
    </input-events>
    <action>
        <workflow>
			<app-path>${wf_application_path}</app-path>
        </workflow>
	</action>
</coordinator-app>

76.4 workflow for coordinator app:
<workflow-app name="sample-wf" xmlns="uri:oozie:workflow:0.4">
    <start to="sqoop-action"/>
    <action name="sqoop-action">
        <sqoop xmlns="uri:oozie:sqoop-action:0.2">
            <job-tracker>${jobTracker}</job-tracker>
            <name-node>${nameNode}</name-node>
            <command>export --connect jdbc:mysql://quickstart:3306/retail_db --username retail_dba --password cloudera --table hadoopexam23_log --export-dir /HadoopExam/Oozie/test_75/output/*/part* --direct --fields-terminated-by "\t" -m 1</command>
        </sqoop>
        <ok to="cleanup"/>
        <error to="killJob"/>
    </action>
	<action name="cleanup">
		<fs>
			<delete path="${nameNode}${hdfspath}/output/*/part*"/>
		</fs>
		<ok to="end"/>
		<error to="killJob"/>
	</action>
    <kill name="killJob">
		<message>"The job killed due to error: ${wf:errorMessage (wf:lastErrorNode())}"</message>
	</kill>
	<end name="end"/>
</workflow-app>

79. 
79.1 remove reading of the file
tail -n +2 daily_TEMP_2016.csv > daily_temp_2016.temp && mv -f daily_temp_2016.temp 
79.2 create table in hive
create table hourly_temp_2016(
State_Code string, County_Code string, Site_Num string, Parameter_Code string,
POC string, Latitude string, Longitude string, Datum string, Parameter_Name string, Sample_Duration string,
Pollutant_Standard string, Date_Local string, Units_of_Measure string, Event_Type string, Observation_Count string,
Observation_Percent string, Arithmetic_Mean string, 1st_Max_Value string, 1st_Max_Hour string, AQI string,
Method_Code string, Method_Name string, Local_Site_Name string, Address string, State_Name string,
County_Name string, City_Name string, CBSA_Name string, Date_of_Last_Change string
)
row format delimited fields terminated by ','
stored as textfile;
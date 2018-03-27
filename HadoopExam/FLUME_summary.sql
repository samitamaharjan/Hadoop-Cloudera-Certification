to ingest logdata:
	#define source, sink, channel
	agent1.sources=source1
	agent1.sinks=sink1
	agent1.channels=ch1

	#describe source1
	agent1.sources.source1.type=exec
	agent1.sources.source1.command=tail -F /local_logdata_path/

	#describe sink1s
	agent1.sinks.sink1.type=hdfs
	agent1.sinks.sink1.hdfs.path=/HadoopExam/<newfolder_name>
	agent1.sinks.sink1.hdfs.writeFormat=Text
	agent1.sinks.sink1.hdfs.fileType=DataStream

	#describe ch1
	agent1.channels.ch1.type=memory
	agent1.channels.ch1.capacity=1000
	agent1.channels.ch1.transactionCapacity=100

	#bind sources, sink with channel
	agent1.sources.source1.channels=ch1
	agent1.sinks.sink1.channel=ch1

to start flume service:
	flume-ng agent --conf <path_to conf_file-dir> --conf-file <path_to conf_file> --name agent1 -Dflume.root.logger=DEBUG,INFO,console

to use netcat service in port 44444:
	agent1.sources.source1.type=netcat
	agent1.sources.source1.bind=localhost [or, 127.0.0.1]
	agent1.sources.source1.port=44444

to create a new directory in every minute:
	#describe interceptors:
	agent1.sources.source1.interceptors=i1
	agent1.sources.source1.interceptors.i1.type=timestamp
	agent1.sources.source1.interceptors.i1.preserveExisting=true

	agent1.sinks.sink1.hdfs.path=/HadoopExam/flume/%Y/%m/%d/%H/%M

to ingest only male data from the given table:
	agent1.sources.source1.interceptors=i1
	agent1.sources.source1.interceptors.i1.type=regex_filter
	agent1.sources.source1.interceptors.i1.regex=female
	agent1.sources.source1.interceptors.i1.excludeEvents=true

	agent1.sinks.sink1.type=hdfs
	agent1.sinks.sink1.hdfs.path=/user/hive/warehouse/hadoopexam.db/flume_import
	agent1.sinks.sink1.hdfs.writeFormat=Text
	agent1.sinks.sink1.hdfs.fileType=DataStream

	"raju,134000,male,39
	ragini,112000,female,35"

to import data in two different tables according to gender [problem 41]:
	..........
	agent1.sources.source1.batchSize=1

	agent1.sources.source1.interceptors=i1
	agent1.sources.source1.interceptors.i1.type=regex_extractor
	agent1.sources.source1.interceptors.i1.regex=^[\\w]+,[\\d]+,(\\w+),[\\d]+$
	agent1.sources.source1.interceptors.i1.serializers=t1
	agent1.sources.source1.interceptors.i1.serializers.t1.name=gender
	#describe selectors:
	agent1.sources.source1.selector.type=multiplexing
	agent1.sources.source1.selector.header=gender
	agent1.sources.source1.selector.mapping.male=channel1
	agent1.sources.source1.selector.mapping.female=channel2

	agent1.sinks.sink1.type=hdfs
	agent1.sinks.sink1.batchSize=1
	agent1.sinks.sink1.hdfs.path=/user/hive/warehouse/hadoopexam.db/flume_male
	agent1.sinks.sink1.hdfs.writeFormat=Text
	agent1.sinks.sink1.rollInterval=0
	agent1.sink1.sink1.hdfs.fileType=DataStream

to ingest files which is near real time data (not stream of data) ==> Spool
	agent1.sources.source1.type=spooldir
	agent1.sources.source1.spoolDir=/path_to_localdir/

	agent1.sources.source1.selector.type = replicating
	agent1.sources.source1.selector.optional = c2

	agent1.channels.channel1.type=file

	agent1.sinks.sink1.type=hdfs
	agent1.sinks.sink1.hdfs.path=/path_to_hdfsdir/
	agent1.sinks.sink1.hdfs.filePrefix=events
	agent1.sinks.sink1.hdfs.fileSuffix=.log
	agent1.sinks.sink1.hdfs.inUsePrefix=_
	agent1.sinks.sink1.hdfs.fileType=DataStream
	



//UDF to trim spaces and special character in a string
public class RemoveSpace extends UDF {
	
	Text text = new Text();
	
	public Text evaluate(Text str){
		if (str == null) return str;
	
	//trim the string left and right if there if any space
		text.set(StringUtils.strip(str.toString());
		return text;
	}
	
	public Text evaluate(Text str, String specialChar){
		if (str == null) return str;
		
	//trim the string left and right if there is the special character matches	
		text.set(StringUtils.strip(str.toString(), specialChar));
		return text;
	}
	
}

//UDF to add country code extension
public class CountryCOde extends UDF {
	
	Text number = new Text();
	
	public Text evaluate(String phone_number){
		if (phone_number != null){ 		//check if the number is null
		
		//substring(0,2) gives string starts from 0 index to 2 characters. equalsIgnoreCase gives boolean value if +1 is there or not. 
			if (!phone_number.substring(0,2).equalsIgnoreCase("+1"){
				phone_number = phone_number + "1" ;
			}
		}
		
		//set String to Text
		number.set(phone_number);
		
		return number;
		
	}
}

//partitioner class
public class MyPartitioner implements Partitioner <Text, IntWritable> {
	public void configure(JobConf conf){
		
	}
	public int getPartition(Text key, IntWritable value, int setNumRedTasks){
		String s = key.toString();
		if (s.length() == 1) {return 0;}
		if (s.length() == 2) {return 1;}
		if (s.length() == 3) {return 2;}
		else{return 3;}
		
	}
}
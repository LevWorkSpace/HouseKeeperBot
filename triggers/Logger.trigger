trigger Logger on LogEvent__e (after insert) {
    
    List<Log__c> logs = new List<Log__c>();
    for (LogEvent__e e : Trigger.new) {
        logs.add((Log__c)JSON.deserialize(e.JsonLog__c, Log__c.class));
    }
    insert logs;
}
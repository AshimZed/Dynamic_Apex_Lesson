public class FeedbackLogHandler {

    // Class to handle inputs from the flow
    public class FeedbackLogHandlerInput {

        @InvocableVariable(label='Record ID')
        public Id recordId;

        @InvocableVariable(label='User ID')
        public Id userId;

        @InvocableVariable(label='Feedback Text')
        public String feedbackText;

    }
    
    // Creates comprehensive Feedback Log object 
    // by dynamically retrieving all object and record information to include in the log
    @InvocableMethod(label='Create Feedback Log')
    public static void createFeedbackLog(List<FeedbackLogHandlerInput> inputs) {
        
        List<Feedback_Log__c> logsToInsert = new List<Feedback_Log__c>(); // List of logs that we will insert at the end

        // Loop through the inputs
        for (FeedbackLogHandlerInput input : inputs) {

            // Create a new Feedback Log
            Feedback_Log__c feedbackLog = new Feedback_Log__c();

            // Assign the feedback text
            feedbackLog.Feedback_Message__c = input.feedbackText;

            // Update the submitted by field using the User ID; this will be assigned as whoever initiated the flow
            feedbackLog.Submitted_By__c = input.userId;

            // Determine object type
            Schema.SObjectType objectType = ObjectTypeHelper.getSObjectTypeFromId(input.recordId);

            // Create and assign the feedback name using the Object Name, the Record Id, and the Date
            String name = objectType.getDescribe().getLabel() + ' -- ' + datetime.now().format() + ' -- ' + input.recordId;
            feedbackLog.Name = name;

            // Get a map of all the fields on the object
            Map<String, Schema.SObjectField> fieldsMap = objectType.getDescribe().fields.getMap();

            // Turn the fields in a string for dynamic query
            List<String> fieldNames = new List<String>(fieldsMap.keySet());
            String queryFields = String.join(fieldNames, ',');

            // Build dynamic query
            String query = 'SELECT ' + queryFields 
                        + ' FROM ' + objectType.getDescribe().getName()
                        + ' WHERE Id=\'' + input.recordId + '\'';

            // Initialize string for dynamic Decription field
            String description = 'Feedback gathered on ' + objectType.getDescribe().getLabel() + ' object;\tRecord ID: ' + input.recordID +'\n';

            // Use implicit batching and dynamic query to build description field
            for (SObject obj : Database.query(query)) {
                for (String field : fieldNames) {
                    description += 'Field: ' + field + '\tValue: ' + obj.get(field) + '\n';
                }
            }

            // Assign description to the feedback log
            feedbackLog.Event_Description__c = description;

            // Add our created log to the list of logs to update
            logsToInsert.add(feedbackLog);
        }

        // Check if there are logs to insert, then insert the logs
        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
        
    }
}
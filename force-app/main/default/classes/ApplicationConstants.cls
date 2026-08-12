public with sharing class ApplicationConstants {

    public static final String SOURCE_COMMUNITY = 'Community';
    public static final String SOURCE_WEBHOOK = 'Webhook';
    public static final String RECORD_TYPE_LEAD = 'Lead';
    public static final String RECORD_TYPE_OPPORTUNITY = 'Opportunity';
    public static final String OPPORTUNITY_STAGE = 'Prospecting';
    public static final String OPPORTUNITY_NAME_SUFFIX = ' - New Application';
    public static final Integer OPPORTUNITY_CLOSE_DAYS = 30;
    public static final String SUCCESS_MESSAGE = 'Application processed successfully';

    public static final Set<String> VALID_SOURCES = new Set<String>{
        SOURCE_COMMUNITY,
        SOURCE_WEBHOOK
    };
}

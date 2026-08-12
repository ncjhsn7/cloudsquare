@RestResource(urlMapping='/external/applications')
global without sharing class ApplicationWebhook {

    @HttpPost
    global static WebhookResponse handlePost() {
        try {
            WebhookRequest payload = (WebhookRequest) JSON.deserialize(
                RestContext.request.requestBody.toString(),
                WebhookRequest.class
            );
            ApplicationResult result = ApplicationProcessingService.processApplication(payload.toApplication());
            return new WebhookResponse(result.success, result.recordType, result.recordId, result.message);
        } catch (Exception e) {
            setStatusCode(400);
            return new WebhookResponse(false, null, null, e.getMessage());
        }
    }

    private static void setStatusCode(Integer statusCode) {
        if (RestContext.response != null) {
            RestContext.response.statusCode = statusCode;
        }
    }

    global class WebhookResponse {
        global Boolean success;
        global String recordType;
        global String recordId;
        global String message;

        global WebhookResponse(Boolean success, String recordType, String recordId, String message) {
            this.success = success;
            this.recordType = recordType;
            this.recordId = recordId;
            this.message = message;
        }
    }

    public class WebhookRequest {
        public String companyName;
        public String federalTaxId;
        public WebhookContact contact;
        public Decimal annualRevenue;

        public ApplicationDTO toApplication() {
            ApplicationDTO app = new ApplicationDTO();
            app.companyName = companyName;
            app.federalTaxId = federalTaxId;
            app.annualRevenue = annualRevenue;
            app.source = ApplicationConstants.SOURCE_WEBHOOK;
            if (contact != null) {
                app.firstName = contact.firstName;
                app.lastName = contact.lastName;
                app.email = contact.email;
                app.phone = contact.phone;
            }
            return app;
        }
    }

    public class WebhookContact {
        public String firstName;
        public String lastName;
        public String email;
        public String phone;
    }
}

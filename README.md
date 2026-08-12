# Partner Application Intake — Salesforce Case Study

Accepts partner applications from two public channels — an Experience Cloud form (LWC) and a REST webhook — and routes both through a single Apex service that creates an **Opportunity** (when a matching Account exists) or a **Lead** (when it does not).

## Architecture

The solution follows a layered separation of concerns:

| Layer | Class | Responsibility |
|---|---|---|
| Presentation | `applicationForm` (LWC) | Public form, client-side validation, loading/success/error states |
| Boundary (UI) | `ApplicationFormController` | `@AuraEnabled` entry point, stamps source = `Community` |
| Boundary (API) | `ApplicationWebhook` | `@RestResource` at `/external/applications`, parses JSON, stamps source = `Webhook` |
| Service | `ApplicationProcessingService` | Validation, account matching, record creation, bulkified |
| Domain | `LeadsDomain`, `OpportunitiesDomain` | Record construction rules |
| Selector | `AccountsSelector` | All Account SOQL |
| Data contracts | `ApplicationDTO`, `ApplicationResult`, `ApplicationConstants`, `ApplicationException` | Input/output wrappers, shared constants, typed errors |

Both channels build an `ApplicationDTO` and call `ApplicationProcessingService.processApplication`, guaranteeing identical business logic.

### Matching rules

1. If `federalTaxId` is provided → match Account by `Federal_Tax_Id__c` only.
2. If `federalTaxId` is blank → match Account by exact `Name`.
3. Match found → Opportunity (`<Company> - New Application`, stage `Prospecting`, close date today + 30, `Amount` = annual revenue).
4. No match → Lead (contact data, `Company`, `Federal_Tax_Id__c`, `AnnualRevenue`).
5. `Application_Source__c` is always set server-side (`Community` or `Webhook`) — clients cannot spoof it.

## Deploy

All metadata lives in the `deploy` folder (Metadata API format with `package.xml`); `deploy.zip` is the same content ready for Workbench.

### Option A — Salesforce CLI

```bash
sf project deploy start --metadata-dir deploy --target-org <your-sandbox-alias> --test-level RunSpecifiedTests --tests ApplicationProcessingServiceTest --tests ApplicationFormControllerTest --tests ApplicationWebhookTest
```

### Option B — Workbench

1. Log in to Workbench against the sandbox.
2. Migration → Deploy → upload `deploy.zip` → check *Rollback on Error* and *Run Specified Tests* (the three test classes above) → Deploy.

## Post-deploy setup (Experience Cloud)

1. **Create/choose a site**: Setup → Digital Experiences → All Sites → New. Activate it.
2. **Place the form**: open Experience Builder → drag **Application Form** onto a public page → Publish.
3. **Enable public access**: Experience Builder → Settings → General → check *Public can access the site*.
4. **Guest user profile** (site → Administration → Pages → Go to Force.com → Public Access Settings):
   - Object permissions: Lead **Create**, Opportunity **Create**, Account **Read**.
   - Field-level security: editable on `Lead.Federal_Tax_Id__c`, `Lead.Application_Source__c`, `Opportunity.Application_Source__c`; readable on `Account.Federal_Tax_Id__c`.
   - Enabled Apex Classes: add `ApplicationFormController` and `ApplicationWebhook`.
5. **Sharing**: with *Secure guest user record access* enabled, guest-created records are assigned to the default owner configured for the site (Administration → Preferences).

## Webhook usage

Endpoint (public, on the site's root domain — do **not** include the site path):

```
POST https://<your-site-domain>/services/apexrest/external/applications
Content-Type: application/json
```

On Enhanced Domains (`*.my.site.com`), Apex REST is served from the domain root, not under `/<site-path>/`. Hitting `/<site-path>/services/apexrest/...` returns HTTP 501 "URL No Longer Exists" — only the community pages live under the site path.

Example:

```bash
curl -X POST "https://yourcompany.my.site.com/services/apexrest/external/applications" -H "Content-Type: application/json" -d "{\"companyName\":\"Acme Corp\",\"federalTaxId\":\"BG123456789\",\"contact\":{\"firstName\":\"Ivan\",\"lastName\":\"Ivanov\",\"email\":\"ivan@example.com\",\"phone\":\"+359888123456\"},\"annualRevenue\":500000}"
```

Success response:

```json
{ "success": true, "recordType": "Opportunity", "recordId": "006XXXXXXXXXXXX", "message": "Application processed successfully" }
```

Errors return `{ "success": false, "message": "<error>" }` with HTTP 400.

## Tests

```bash
sf apex run test --tests ApplicationProcessingServiceTest --tests ApplicationFormControllerTest --tests ApplicationWebhookTest --result-format human --code-coverage --target-org <your-sandbox-alias>
```

Covered scenarios: Lead path (no match), Opportunity path (Tax ID match), Opportunity path (Name match with blank Tax ID), Tax ID mismatch not falling back to Name, `Application_Source__c` per channel (Community vs Webhook), validation errors, null input, malformed webhook JSON, missing webhook fields. Coverage is well above the 75–80% target.

## Assumptions

- `federalTaxId` is optional on the form; the Name-match path requires it to be blank, per the spec.
- `companyName`, `firstName`, `lastName`, `email` and `phone` are required server-side; `annualRevenue` is optional.
- `annualRevenue` maps to `Lead.AnnualRevenue` and `Opportunity.Amount`.
- If the Tax ID is provided but matches no Account, a Lead is created (no fallback to Name matching), per the spec wording "If blank → match by Name".
- When multiple Accounts share the same Tax ID or Name, the first match is used.
- `ApplicationProcessingService` runs `without sharing` so the guest user can match against existing Accounts; object and field permissions still apply and are granted explicitly to the guest profile.
- `Account.Federal_Tax_Id__c` is an External ID (indexed) to keep the matching query selective.
- The webhook is anonymous by design (public site endpoint), as stated in the case study; in production it should be protected (e.g., HMAC signature or a Connected App).
- No trigger logic was required; records are created only through the service.

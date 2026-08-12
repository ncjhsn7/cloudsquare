import { LightningElement } from 'lwc';
import submitApplication from '@salesforce/apex/ApplicationFormController.submitApplication';

export default class ApplicationForm extends LightningElement {
    isLoading = false;
    isSuccess = false;
    resultMessage;

    formData = {
        companyName: '',
        federalTaxId: '',
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        annualRevenue: null
    };

    get messageClass() {
        return this.isSuccess
            ? 'slds-m-top_medium slds-text-color_success'
            : 'slds-m-top_medium slds-text-color_error';
    }

    handleChange(event) {
        const { name, value } = event.target;
        this.formData = {
            ...this.formData,
            [name]: name === 'annualRevenue' ? (value === '' ? null : Number(value)) : value
        };
    }

    async handleSubmit() {
        this.resultMessage = null;
        if (!this.validateForm()) {
            return;
        }
        this.isLoading = true;
        try {
            const result = await submitApplication({ input: this.formData });
            this.isSuccess = result.success;
            this.resultMessage = result.success
                ? `${result.message}. Record type: ${result.recordType}. Record Id: ${result.recordId}`
                : result.message;
            if (result.success) {
                this.resetForm();
            }
        } catch (error) {
            this.isSuccess = false;
            this.resultMessage = error?.body?.message || 'An unexpected error occurred. Please try again.';
        } finally {
            this.isLoading = false;
        }
    }

    validateForm() {
        return [...this.template.querySelectorAll('lightning-input')].reduce(
            (validSoFar, input) => input.reportValidity() && validSoFar,
            true
        );
    }

    resetForm() {
        this.formData = {
            companyName: '',
            federalTaxId: '',
            firstName: '',
            lastName: '',
            email: '',
            phone: '',
            annualRevenue: null
        };
    }
}

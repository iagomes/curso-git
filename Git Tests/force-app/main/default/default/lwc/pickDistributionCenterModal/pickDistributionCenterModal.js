import { LightningElement, api, track, wire } from "lwc";
export default class PickDistributionCenterModal extends LightningElement {
  @api distributionCenterOptions;

  @api values = [];

  get options() {
    if (this.distributionCenterOptions) {
      const values = Object.keys(this.distributionCenterOptions);
      const _options = values.map(key => ({
        value: key,
        label: this.distributionCenterOptions[key]
      }));

      return _options;
    }

    return [];
  }

  handleChangeOptions(event) {
    this.selectedOptions = event.detail.value;
  }

  @track isModalOpen = false;

  openModal() {
    this.isModalOpen = true;
  }

  closeModal() {
    this.isModalOpen = false;
  }

  submitDetails() {
    const customEvent = new CustomEvent("select", {
      detail: {
        selectedOptions: this.selectedOptions || []
      }
    });

    this.dispatchEvent(customEvent);

    this.isModalOpen = false;
  }
}

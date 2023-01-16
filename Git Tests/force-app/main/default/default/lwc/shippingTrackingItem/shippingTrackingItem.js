import { LightningElement, api } from 'lwc';

export default class ShippingTrackingItem extends LightningElement {
  @api statusData = undefined;
  @api deliveryUrl;

  get mainsStatusClassName() {
    if (this.statusData.type === 'completed') {
      return 'completed slds-timeline__item_expandable';
    }

    if (this.statusData.type === 'error') {
      return 'error slds-timeline__item_expandable';
    }

    return 'slds-timeline__item_expandable';
  }

  get completed() {
    return this.statusData.type === 'completed'
  }

  get error() {
    return this.statusData.type === 'error'
  }

  get onHold() {
    return this.statusData.type === 'onHold'
  }

  handleClickItem() {
    console.log(this.deliveryUrl.data);
    if (this.deliveryUrl.data)
      window.open(this.deliveryUrl.data, '_blank');
  }
}

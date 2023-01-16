import { api, LightningElement, track, wire } from 'lwc';
import getDeliveryHistory from '@salesforce/apex/ShippingTrackingController.getDeliveryHistory';
import getDeliveryURL from '@salesforce/apex/ShippingTrackingController.getDeliveryURL';

export default class ShippingTracking extends LightningElement {
  @api recordId;

  @wire(getDeliveryHistory, { recordId: '$recordId' })
  statusHistory;
  @wire(getDeliveryURL, { recordId: '$recordId' })
  deliveryURL;

  handleClick() {
    window.open(this.deliveryURL.data, '_blank');
  }
}

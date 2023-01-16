({
	doInit: function (component, event, helper) {
		var urlEvent = $A.get("e.force:navigateToURL");
		urlEvent.setParams({
		  "url": "/lightning/n/Upload_de_Contratos"
		});
		urlEvent.fire();
	}
})
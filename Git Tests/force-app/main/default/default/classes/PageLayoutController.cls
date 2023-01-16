/**
 * @description       : 
 * @author            : Raphael Soares
 * @author username   : raphael.soares@apllos.com
 * @linkedin          : https://www.linkedin.com/in/raphaelsoares95/
 * @company           : Apllos Solutions
 * @last modified on  : 17-08-2021
 * @last modified by  : raphael.soares@apllos.com
**/
public without sharing class PageLayoutController {
 //(cacheable=true)
    @AuraEnabled
    public static StandardResponse getLayoutByName(String layoutName) {

        System.debug('layoutName ::: ' +layoutName);

        StandardResponse response = new StandardResponse();

        if(String.isNotEmpty(layoutName)) {

            List<String> layoutNames = new List<String>{layoutName};
                
            List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(
                Metadata.MetadataType.Layout,
                layoutNames
            );  

            if(layouts.size() > 0) {
                System.debug('layouts:::\n' + JSON.serializePRetty(layouts));
                response.setData('layouts', JSON.serialize(layouts));
            } else {
                response.addError('Layout ('+layoutName+') não encontrado. Contacte o Administrador'); 
            }
        } else {
            response.addError('Layout ('+layoutName+') não encontrado. Contacte o Administrador');
        }
        return response;
    }
}
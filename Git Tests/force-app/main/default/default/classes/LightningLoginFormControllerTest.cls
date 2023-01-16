@IsTest(SeeAllData = true)
public with sharing class LightningLoginFormControllerTest {

 @IsTest
 static void LightningLoginFormControllerInstantiation() {
  LightningLoginFormController controller = new LightningLoginFormController();
  System.assertNotEquals(controller, null);
 }

 @IsTest
 static void testIsUsernamePasswordEnabled() {
  System.assertEquals(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
 }

 @IsTest
 static void testIsSelfRegistrationEnabled() {
  System.assertEquals(false, LightningLoginFormController.getIsSelfRegistrationEnabled());
 }

 @IsTest
 static void testGetSelfRegistrationURL() {
  System.assertEquals(null, LightningLoginFormController.getSelfRegistrationUrl());
 }

 @IsTest
 static void testAuthConfig() {
  Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
  System.assertNotEquals(null, authConfig);
 }

 @IsTest
 static void testLogin(){
     //System.debug('Teste login: ' + LightningLoginFormController.login('username', 'password', 'startUrl'));
     System.assertEquals(null, LightningLoginFormController.login('username', 'password', 'startUrl'));
 }

 @IsTest
 static void testGetForgotPasswordUrl(){
     System.assertEquals(null, LightningLoginFormController.getForgotPasswordUrl());
     System.debug('getForgotPasswordUrl: ' + LightningLoginFormController.getForgotPasswordUrl());
 }

 @IsTest
 static void testSetExperienceId(){
     //System.assertEquals(null, LightningLoginFormController.setExperienceId('testExpId'));
     System.debug('setExperienceId: ' + LightningLoginFormController.setExperienceId('testExpId'));
 }
}
@isTest
public class Test_DataFactory 
{
    public static User getAdminUser()
    {
        return [Select id, Name, Alias from User where alias = 'AUser' LIMIT 1];
    }

    public static Group getPersonalQueue1()
    {
        return [Select id, Name from Group where name = 'Personal queue 1' LIMIT 1];
    }

    public static Queue_metadata__mdt getQueueMetadata( Id userId )
    {
        return [Select id, User__c, Queue__c, Queue_others__c from Queue_metadata__mdt where User__c = :userId LIMIT 1];
    }

    /* 
    **  Cuando el método recibe 1, se incluye como propietario un Usuario que no tiene Cola asignada en el metadato.
    **  Cuando el método recibe 2, se incluye como propietario una Cola.
    **  Cuando el método recibe un valor distinto, el propietario es un Usuario con una Cola asignada en el metadato (admin)
    */
    public static List<Case> gen_Cases( Integer ammount, Integer currentUser )
    {
        //Evaluates the user to assign the ownership of the case
        String caseOwnerId;

        if      (currentUser == 1)  caseOwnerId = [Select id, Alias from User where alias = 'autocase'].id;
        else if (currentUser == 2)  caseOwnerId = [Select id, Name from Group where name = 'USA Unknown'].id;
        else                        caseOwnerId = Test_DataFactory.getAdminUser().Id;

        List<Account> aList     =   gen_Account(ammount);

        //Create the case
        List<Case> caseList = new List<Case>();
        for (Integer i = 0; i < ammount; i++)
        {
            caseList.add
            (
                new Case
                (
                    Subject     =   'Case ' + i, 
                    Status      =   'Open',
                    OwnerId     =   caseOwnerId,
                    AccountId   =   aList.get(i).Id
                )
            );
        } 

        insert caseList; 

        return caseList;
    }

    public static List<Account> gen_Account (Integer amount)
    {
        List<Account> acList   =   new List<Account>();

        for (Integer i = 0; i < amount; i++)
        {
            acList.add
            (
                new Account
                (
                    Name                =   'Account ' + i,
                    RecordTypeId        =   Schema.SObjectType.Account.getRecordTypeInfosByName().get('USA Business Account').getRecordTypeId(),
                    BillingCountryCode  =   'US',
                    BillingPostalCode   =   '07200',
                    BillingCity         =   'Ramsey'
                )
            );
        }

        insert acList;

        return acList;
    }


    /* 
    **  Creates the Elements, but they aren't inserted
    **  Cuando el método recibe 1, genera Tasks
    **  Cuando el método recibe 2, genera Events
    */
    public static List<sObject> gen_Activities( Integer amount, Integer mode, Boolean notify )
    {
        List<sObject> retList   =   new List<sObject>();
        
        if ( mode != 1 && mode != 2 ) throw new NullPointerException();
        sObject element;

        for (Integer i = 0; i < amount; i++)
        {
            if ( mode == 1 )
            {   // Generate a Task
                retList.add
                (
                    new Task
                    (
                        Subject                     =   'Call the Customer back',
                        Status                      =   'Open',
                        Priority                    =   'Normal',
                        // Notitication_Date_Time__c   =   System.now().addYears(1),
                        // Notify_Owner__c             =   notify,
                        IsRecurrence                =   false
                    )
                );
            }
            else
            {   // Generate an Event
                retList.add
                (
                    new Event
                    (
                        Subject                     =   'Meeting with the technician',
                        Notitication_Date_Time__c   =   System.now().addYears(1),
                        StartDateTime               =   System.now().addYears(1).addDays(-1),
                        EndDateTime                 =   System.now().addYears(1),
                        Notify_Owner__c             =   notify,
                        IsRecurrence                =   false
                    )
                );
            }
        }

        return retList; 
    }

    public static List<SObject> gen_Acti_Rel2_Cases ( List<Case> cList, Integer amount, Integer mode, Boolean notify)
    {
        if ( amount != cList.size() ) throw new NullPointerException();
        
        List<SObject>   actiList    =   gen_Activities(amount, mode, notify);
        
        Integer i = 0;

        for (sObject a : actiList)
        {
            a.put('WhatId', cList.get(i).Id);
            i++;
        }

        //insert actiList;

        return actiList;
    }


    public static List<EmailMessage> gen_Emails( Integer ammount, List<Case> testCases, Boolean incoming )
    {
        //Create the case
        List<EmailMessage> emailList    =   new List<EmailMessage>();
        String 	sBody                   =	'<div dir="ltr"><div class="gmail_quote"><br> <div style="background-color:#ffffff"><!--#[{"email":"fakeemail@mymail.com","nombre":"John Smith","idioma":"1","localizador":"KKKKX"}]#--><center> <table cellpadding="0" cellspacing="0" border="0" width="630"> <tbody><tr> <td><table cellspacing="0" cellpadding="0" border="0" width="100%"> <tbody><tr> <td><img src="http://hoteles.grandvalira.com/App_Themes/gvh/img/mail/gv-mail-cabecera.jpg" alt="Grandvalira" width="630" height="162"></td> </tr> <tr> <td><table cellspacing="0" cellpadding="0" border="0" width="100%"> <tbody><tr> <td><table width="630" border="0" align="center" cellpadding="2" cellspacing="0" bgcolor="#005F96"> <tbody><tr> <td align="center" valign="top"><table cellspacing="0" cellpadding="0" border="0" width="100%" bgcolor="#FFFFFF"> <tbody><tr> <td align="left" style="width:10px"> </td> <td align="left" valign="top"><table cellspacing="10" cellpadding="0" border="0" width="100%" bgcolor="#FFFFFF"> <tbody><tr> <td><h1><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" color="#00ADD8"> <p>Bono Reserva</p> </font></h1></td> </tr> <tr> <td><p><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2"> Estimado/a David,</font></p> <p align="justify"><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2">En el documento adjunto a éste correo, en formato pdf, encontrará el bono a presentar en el establecimiento/taquilla a su llegada.</font></p> <p align="justify"><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2">Recogida en la estación, en las taquillas preferentes de venta online.</font><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2">	</font></p></td> </tr> <tr> <td><table width="95%" cellpadding="4" cellspacing="1" border="0" align="center"> <tbody><tr> <td bgcolor="#FFFFFF" width="150" valign="top"><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2">Localizador: </font></td> <td bgcolor="#FFFFFF"><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2"><b>M6W29X</b></font></td> </tr> <tr> <td bgcolor="#FFFFFF" valign="top"><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2">Cliente:</font></td> <td bgcolor="#FFFFFF"><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2"><b>David</b></font></td> </tr> </tbody></table></td> </tr> <tr> <td><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2"> <em></em></font></td> </tr> <tr> <td colspan="2" style="height:6px"><div align="justify"><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2"> <span align="center">Recuerde que si tiene que acceder a su cuenta, puede hacerlo en <a href="http://hoteles.grandvalira.com" style="color:#00add8" target="_blank">http://hoteles.grandvalira.com</a> con sus datos de identificación. </span></font></div></td> </tr> <tr> <td colspan="2" style="height:6px"><p><font size="2" face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif">Quedando a su disposición, reciba un cordial saludo.<br> </font></p></td> </tr> <tr> <td colspan="2" align="center" style="height:6px"><font size="2" face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif">Gracias por elegir el sistema de reservas on-line de Grandvalira para reservar su estancia</font></td> </tr> <tr> <td colspan="2" align="center" style="height:6px"><font size="1" face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif"><a href="http://www.adobe.com" style="color:#000000" target="_blank">Descargue aquí el software gratuito Adobe Acrobat Reader para visualizar nuestros documentos adjuntos.</a></font></td> </tr> </tbody></table></td> <td align="left" style="width:10px"> </td> </tr> </tbody></table></td> </tr> </tbody></table></td> </tr> <tr> <td><table width="630" border="0" cellspacing="0" cellpadding="0"> <tbody><tr> <td height="20" bgcolor="#058CC2"> </td> </tr> <tr> <td height="40" bgcolor="#005F96"><table cellspacing="0" cellpadding="0" border="0" width="100%"> <tbody><tr> <td align="left" style="width:20px;height:32px"> </td> <td><font face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2" color="#FFFFFF"> Tel: +376 891 800 · <a href="https://www.grandvalira.com/contacta-con-nosotros" style="color:#ffffff" target="_blank">Contacta con nosotros</a></font></td> <td align="right"><font color="#FFFFFF" face="Gotham, Helvetica Neue, Helvetica, Arial, sans-serif" size="2">© 2016 - GRANDVALIRA </font></td> <td align="left"> </td> </tr> </tbody></table></td> </tr> <tr> <td height="20" bgcolor="#058CC2"> </td> </tr> </tbody></table></td> </tr> <tr> <td><center> <font color="#FFFFFF"><a href="http://hoteles.grandvalira.com" style="color:#ffffff" target="_blank">http://hoteles.grandvalira.com</a><br> ID:234</font> </center></td> </tr> </tbody></table></td> </tr> </tbody></table></td> </tr> </tbody></table></center> </div> </div><br></div>';      
        
        for (Integer i = 0; i < ammount; i++)
        {
            emailList.add
            (
                new EmailMessage
                (             
                    ParentID 	=   testCases[i].Id,
                    Incoming	=   incoming,
                    MessageDate =   datetime.now(),
                    Subject 	=   'Test EmailMessage ' + i,  
                    ToAddress 	=   'porcelanosainbox@gmail.com',
                    HtmlBody 	=   sBody,
                    FromName 	=   Userinfo.getName(),
                    FromAddress =   'fakeemail' + Math.round(Math.random() * Math.random()) + '@mymail.com'
                )
            );
        }
        return emailList;
    }

}
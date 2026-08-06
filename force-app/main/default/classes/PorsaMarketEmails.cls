/**
 * @author       Ivan Losilla
 * @since        April 2025
 * @group        Porsamarket
 * @description  PorsaMarket emails class
 * @test PorsaMarketEmailsTest
 */
public class PorsaMarketEmails {
    public static String prepareBody(List<PorsaMarket.PorsaMarketResult> results, String lang, Boolean isTest) {
        String htmlContent = '<html><head><style>';
        htmlContent += 'body { font-family: Arial, sans-serif; font-size: 12px; }'; // 🔹 Fuente más pequeña
        htmlContent += 'table { width: 100%; border-collapse: collapse; border: 1px solid black; }'; // 🔹 Bordes mejorados
        htmlContent += 'th, td { border: 1px solid black; padding: 4px; text-align: left; font-size: 12px; }'; // 🔹 Bordes y tamaño de fuente
        htmlContent += 'th { background-color: #f2f2f2; }'; // 🔹 Fondo gris para encabezados
        htmlContent += '.title { width: 150px; }'; // 🔹 ancho titulo
        htmlContent += 'a { color: blue; text-decoration: underline; font-size: 12px; }'; // 🔹 Enlaces azules y subrayados
        htmlContent += '</style></head><body>';
        //htmlContent += '<h1 style="font-size: 16px;">Reporte de resultados Porsamarket - Salesforce</h1>'; // 🔹 Título más grande
        if (isTest == true ) {
            htmlContent += '<b>##SENTEMAIL##</b>'; // 🔹 Título más grande
        }
        if (lang == 'fr') {
            htmlContent += '<p>Bonjour,<p>' +
                'Je viens de vous attribuer une nouvelle piste. Une chance de vente est maintenant devant vous!' +
                '<br/><br/>' +
                'La piste peut consister en (i) une nouvelle opportunité, (ii) un nouveau compte ou (iii) une opportunité existante synchronisée. ' +
                'Dans les deux premiers cas, l\'objet est déjà créé à votre nom dans Salesforce. S\'il s\'agit d\'une synchronisation, l\'opportunité est liée au permis de construire afin qu\'à l\'avenir nous puissions vous envoyer des informations pertinentes.' +
                '<br/><br/>' +
                'Voici quelques bonnes pratiques qui peuvent vous aider à tirer le meilleur parti de ce défi:' +
                '<br/>' +
                '<ul><li>Lisez attentivement toutes les informations disponibles</li>' +
                '<li>Analyser nos points forts pour offrir les bonnes solutions au client</li>' +
                '<li>Les clients attendent de Porcelanosa le plus haut niveau de diligence. Notre mission est de rendre leur prise de décision aussi facile que possible</li>' +
                '<li>Ne tardez pas à passer à l\'action au-delà du temps de préparation nécessaire</li>' +
                '<li>N\'oubliez pas qu\'une rencontre en face à face est le meilleur moyen d\'établir un contact. Si ce n\'est pas facile, identifiez des contacts communs qui peuvent vous aide</li>' +
                '<li>N\'oubliez pas que notre catalogue est très vaste et ne se limite pas uniquement à la céramique. <u>Les meubles de bain sont souvent un moyen plus facile d\'entrer dans un projet</u></li>' +
                '</ul>' +
                '<br/>' +
                '<b>S\'il vous plaît, répondez-moi avec votre plan d\'action</b><br/>' +
                '<br/>' +
                'Si vous avez des questions ou besoin d\'aide, n\'hésitez pas à les porter à l\'attention de vos managers. Ensemble, nous sommes meilleurs' +
                '<br/>' +
                '<br/>' +
                '###TABLE###' +
                '<br/>' +
                '<p>Salutations<p>';
        } else {
             htmlContent += '<p>Hello,<p>' +
             'I\'ve just assigned you a new lead. A sales opportunity is now in front of you!' +
             '<br/><br/>' +
             'The lead may consist of (i) a new opportunity, (ii) a new account, or (iii) a synchronized existing opportunity. ' +
             'In the first two cases, the object has already been created in your name in Salesforce. If it\'s a synchronization, the opportunity is linked to the building permit so that we can send you relevant information in the future.' +
             '<br/><br/>' +
             'Here are some best practices that can help you make the most of this challenge:' +
             '<br/>' +
             '<ul><li>Read all the available information carefully</li>' +
             '<li>Analyze our strengths to offer the right solutions to the client</li>' +
             '<li>Clients expect the highest level of diligence from Porcelanosa. Our mission is to make their decision-making as easy as possible</li>' +
             '<li>Don\'t delay taking action beyond the necessary preparation time</li>' +
             '<li>Remember that face-to-face meetings are the best way to establish contact. If that\'s not easy, identify mutual contacts who can help you</li>' +
             '<li>Don\'t forget that our catalog is very broad and not limited to ceramics. <u>Bathroom furniture is often an easier entry point into a project</u></li>' +
             '</ul>' +
             '<br/>' +
             '<b>Please reply with your action plan</b><br/>' +
             '<br/>' +
             'If you have any questions or need help, don\'t hesitate to bring them to your managers\' attention. Together, we are better' +
             '<br/>' +
             '<br/>' +
             '###TABLE###' +
             '<br/>' +
             '<p>Best regards<p>';
        }
        htmlContent += '<br/>';

        String table = '';

        if (results.size() > 0) {
            for (PorsaMarket.PorsaMarketResult res : results) {
                table += '<table>';
                if (lang == 'fr') {
                    table += '<tr><th class=\'title\'>Étiquette</th><th>Valeur</th></tr>';
                    if (res.obj == 'ACCOUNT') {
                        table += '<tr><th class=\'title\'>Action</th><td>' + res.action + '</td></tr>';
                        table += '<tr><th class=\'title\'>Objet</th><td>Compte</td></tr>';
                        table += '<tr><th class=\'title\'>Nom</th><td><a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + res.sfId + '" target="_blank">' + res.name + '</a></td></tr>';
                        table += '<tr><th class=\'title\'>Rue</th><td>' + res.accountData.BillingStreet + '</td></tr>';
                        table += '<tr><th class=\'title\'>Code Postal</th><td>' + res.accountData.BillingPostalCode + '</td></tr>';
                        table += '<tr><th class=\'title\'>Ville</th><td>' + res.accountData.BillingCity + '</td></tr>';
                        table += '<tr><th class=\'title\'>SIRET</th><td>' + res.accountData.Vat_number__c + '</td></tr>';
                        if (res.action == 'CREATE') {
                            table += '<tr><th class=\'title\'><b>Important</b></th><td> <b>Veuillez réattribuer le nouveau compte si nécessaire</b></td></tr>';
                        }
                    }
                    if (res.obj == 'OPPORTUNITY') {
                        table += '<tr><th class=\'title\'>Action</th><td>' + res.action + '</td></tr>';
                        table += '<tr><th class=\'title\'>Objet</th><td>Opportunité</td></tr>';
                        if (res.opportunityData != null && res.opportunityData.account.name != null) {
                            table += '<tr><th class=\'title\'>Nom Compte</th><td><a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + res.opportunityData.accountId + '" target="_blank">' + res.opportunityData.account.name + '</a></td></tr>';
                        }
                        table += '<tr><th class=\'title\'>Nom</th><td><a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + res.sfId + '" target="_blank">' + res.name + '</a></td></tr>';
                        table += '<tr><th class=\'title\'>Rue</th><td>' + res.opportunityData.Address__c + '</td></tr>';
                        table += '<tr><th class=\'title\'>Code Postal</th><td>' + res.opportunityData.Postcode__c + '</td></tr>';
                        table += '<tr><th class=\'title\'>Ville</th><td>' + res.opportunityData.City__c + '</td></tr>';
                        table += '<tr><th class=\'title\'>Montant</th><td>' + res.opportunityData.Amount_custom__c + '</td></tr>';
                        if (res.opportunityData != null && String.isBlank(res.opportunityData.Product_Categories__c) == false) {
                            List<String> productsList = res.opportunityData.Product_Categories__c.split(';');
                            table += '<tr><th class=\'title\'>Produits</th><td>' + String.join(productsList, ',') + '</td></tr>';
                        }
                    }
                } else {
                    table += '<tr><th class=\'title\'>Label</th><th>Value</th></tr>';
                    if (res.obj == 'ACCOUNT') {
                        table += '<tr><th class=\'title\'>Action</th><td>' + res.action + '</td></tr>';
                        table += '<tr><th class=\'title\'>Object</th><td>Account</td></tr>';
                        table += '<tr><th class=\'title\'>Name</th><td><a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + res.sfId + '" target="_blank">' + res.name + '</a></td></tr>';
                        table += '<tr><th class=\'title\'>Street</th><td>' + res.accountData.BillingStreet + '</td></tr>';
                        table += '<tr><th class=\'title\'>Postal code</th><td>' + res.accountData.BillingPostalCode + '</td></tr>';
                        table += '<tr><th class=\'title\'>City</th><td>' + res.accountData.BillingCity + '</td></tr>';
                        table += '<tr><th class=\'title\'>Company code</th><td>' + res.accountData.Vat_number__c + '</td></tr>';
                        if (res.action == 'CREATE') {
                            table += '<tr><th class=\'title\'><b>Important</b></th><td> <b>Please reassign the new Account if needed</b></td></tr>';
                        }
                    }
                    if (res.obj == 'OPPORTUNITY') {
                        table += '<tr><th class=\'title\'>Action</th><td>' + res.action + '</td></tr>';
                        table += '<tr><th class=\'title\'>Object</th><td>Opportunity</td></tr>';
                        if (res.opportunityData != null && res.opportunityData.account.name != null) {
                            table += '<tr><th class=\'title\'>Account Name</th><td><a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + res.opportunityData.accountId + '" target="_blank">' + res.opportunityData.account.name + '</a></td></tr>';
                        }
                        table += '<tr><th class=\'title\'>Name</th><td><a href="' + URL.getOrgDomainURL().toExternalForm() + '/' + res.sfId + '" target="_blank">' + res.name + '</a></td></tr>';
                        table += '<tr><th class=\'title\'>Street</th><td>' + res.opportunityData.Address__c + '</td></tr>';
                        table += '<tr><th class=\'title\'>Postal code</th><td>' + res.opportunityData.Postcode__c + '</td></tr>';
                        table += '<tr><th class=\'title\'>City</th><td>' + res.opportunityData.City__c + '</td></tr>';
                        table += '<tr><th class=\'title\'>Amount</th><td>' + res.opportunityData.Amount_custom__c + '</td></tr>';
                        if (res.opportunityData != null && String.isBlank(res.opportunityData.Product_Categories__c) == false) {
                            List<String> productsList = res.opportunityData.Product_Categories__c.split(';');
                            table += '<tr><th class=\'title\'>Products</th><td>' + String.join(productsList, ',') + '</td></tr>';
                        }
                    }
                }
                table += '</table><br/>';
            }

            htmlContent = htmlContent.replace('###TABLE###', table);
            htmlContent += '</body></html>';
        }

        return htmlContent;
    }

    public static void sendEmailFileError(Map<String, String> duplicateLines) {
        if (duplicateLines.size() > 0) {
            List<OrgWideEmailAddress> owea = [select Id from OrgWideEmailAddress where Address = 'salesforce@porcelanosagrupo.com'];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            if ( owea.size() > 0 ) {
                mail.setOrgWideEmailAddressId(owea.get(0).Id);
            }

            mail.setUseSignature(false);
            mail.setToAddresses(new List<String>{'javier.cortes@porcelanosagrupo.com', 'salesforce@porcelanosagrupo.com'});
            mail.setSubject('PORSAMARKET ERROR: Error en fichero');
            
            String htmlContent = '<html><head><style>';
            htmlContent += 'body { font-family: Arial, sans-serif; font-size: 12px; }'; // 🔹 Fuente más pequeña
            htmlContent += 'table { width: 100%; border-collapse: collapse; border: 1px solid black; }'; // 🔹 Bordes mejorados
            htmlContent += 'th, td { border: 1px solid black; padding: 4px; text-align: left; font-size: 12px; }'; // 🔹 Bordes y tamaño de fuente
            htmlContent += 'th { background-color: #f2f2f2; }'; // 🔹 Fondo gris para encabezados
            htmlContent += 'a { color: blue; text-decoration: underline; font-size: 12px; }'; // 🔹 Enlaces azules y subrayados
            htmlContent += '</style></head><body>';
            htmlContent += '<h2>Registros no procesados por error en archivo</h2><br/>';
            htmlContent += '<ul>';
            for (String elem : duplicateLines.keySet()) {
                htmlContent += '<li>' + duplicateLines.get(elem) + ': ' + elem + '</li>'; 
            }

            htmlContent += '</ul>';
            htmlContent += '</body></html>';
            mail.setHtmlBody(htmlContent);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        }
    }

    public static String prepareBodyCustomData(PorsaMarketCustom customdata, Boolean isTest) {
        String htmlContent = '<html><head><style>';
        htmlContent += 'body { font-family: Arial, sans-serif; font-size: 12px; }'; // 🔹 Fuente más pequeña
        htmlContent += 'table { width: 100%; border-collapse: collapse; border: 1px solid black; }'; // 🔹 Bordes mejorados
        htmlContent += 'th, td { border: 1px solid black; padding: 4px; text-align: left; font-size: 12px; }'; // 🔹 Bordes y tamaño de fuente
        htmlContent += 'th { background-color: #f2f2f2; }'; // 🔹 Fondo gris para encabezados
        htmlContent += '.title { width: 150px; }'; // 🔹 ancho titulo
        htmlContent += 'a { color: blue; text-decoration: underline; font-size: 12px; }'; // 🔹 Enlaces azules y subrayados
        htmlContent += '</style></head><body>';
        //htmlContent += '<h1 style="font-size: 16px;">Reporte de resultados Porsamarket - Salesforce</h1>'; // 🔹 Título más grande
        if (isTest == true ) {
            htmlContent += '<b>##SENTEMAIL##</b>'; // 🔹 Título más grande
        }

        /*htmlContent += '<p>Hello,<p>' +
        'I\'ve just assigned you a new lead. A sales opportunity is now in front of you!' +
        '<br/><br/>' +
        'The lead may consist of a new project and a new account. ' +
        '<br/><br/>' +
        'Here are some best practices that can help you make the most of this challenge:' +
        '<br/>' +
        '<ul><li>Read all the available information carefully</li>' +
        '<li>Analyze our strengths to offer the right solutions to the client</li>' +
        '<li>Clients expect the highest level of diligence from Porcelanosa. Our mission is to make their decision-making as easy as possible</li>' +
        '<li>Don\'t delay taking action beyond the necessary preparation time</li>' +
        '<li>Remember that face-to-face meetings are the best way to establish contact. If that\'s not easy, identify mutual contacts who can help you</li>' +
        '<li>Don\'t forget that our catalog is very broad and not limited to ceramics. <u>Bathroom furniture is often an easier entry point into a project</u></li>' +
        '</ul>' +
        '<br/>' +
        'If you have any questions or need help, don\'t hesitate to bring them to your managers\' attention. Together, we are better' +
        '<br/>' +
        '<br/>' +
        '###TABLE###' +
        '<br/>' +
        '<p>Best regards<p>';
        htmlContent += '<br/>';

        String table = '';
        table += '<table>';
        table += '<tr><th class=\'title\'>Label</th><th>Value</th></tr>';
        table += '<tr><th class=\'title\'>Object</th><td>Account</td></tr>';
        table += '<tr><th class=\'title\'>Account Id</th><td>' + customdata.accountId + '</td></tr>';
        table += '<tr><th class=\'title\'>Name</th><td>' + customdata.dataAccount.name + '</td></tr>';
        table += '<tr><th class=\'title\'>Street</th><td>' + customdata.dataAccount.BillingStreet + '</td></tr>';
        table += '<tr><th class=\'title\'>Postal code</th><td>' + customdata.dataAccount.BillingPostalCode + '</td></tr>';
        table += '<tr><th class=\'title\'>City</th><td>' + customdata.dataAccount.BillingCity + '</td></tr>';
        table += '<tr><th class=\'title\'>Company code</th><td>' + customdata.dataAccount.Vat_number__c + '</td></tr>';
        table += '</table><br/>';

        table += '<table>';
        table += '<tr><th class=\'title\'>Label</th><th>Value</th></tr>';
        table += '<tr><th class=\'title\'>Object</th><td>Opportunity</td></tr>';
        table += '<tr><th class=\'title\'>Project Id</th><td>' + customdata.projectId + '</td></tr>';
        table += '<tr><th class=\'title\'>Name</th><td>' + customdata.dataProject.name + '</td></tr>';
        table += '<tr><th class=\'title\'>Street</th><td>' + customdata.dataProject.Address__c + '</td></tr>';
        table += '<tr><th class=\'title\'>Postal code</th><td>' + customdata.dataProject.Postcode__c + '</td></tr>';
        table += '<tr><th class=\'title\'>City</th><td>' + customdata.dataProject.City__c + '</td></tr>';
        table += '<tr><th class=\'title\'>Amount</th><td>' + customdata.dataProject.Amount_custom__c + '</td></tr>';
        table += '</table><br/>';*/

        htmlContent += '<p>Ciao,<p>' +
        'Ti ho appena assegnato un nuovo lead. Un\'opportunità di vendita è ora davanti a te!' +
        '<br/><br/>' +
        'Il lead può comprendere un nuovo progetto e un nuovo account. ' +
        '<br/><br/>' +
        'Ecco alcune buone pratiche che possono aiutarti a sfruttare al meglio questa opportunità:' +
        '<br/>' +
        '<ul><li>Leggi attentamente tutte le informazioni disponibili</li>' +
        '<li>Analizza i nostri punti di forza per offrire al cliente le soluzioni più adeguate</li>' +
        '<li>I clienti si aspettano il massimo livello di attenzione da Porcelanosa. La nostra missione è rendere il loro processo decisionale il più semplice possibile</li>' +
        '<li>Non rimandare l\'azione oltre il tempo necessario per la preparazione</li>' +
        '<li>Ricorda che gli incontri di persona sono il modo migliore per stabilire un contatto. Se non è facile, identifica contatti comuni che possano aiutarti</li>' +
        '<li>Non dimenticare che il nostro catalogo è molto ampio e non si limita alla ceramica. <u>I mobili da bagno sono spesso un punto di ingresso più semplice in un progetto</u></li>' +
        '</ul>' +
        '<br/>' +
        'Se hai domande o hai bisogno di aiuto, non esitare a parlarne con i tuoi responsabili. Insieme, siamo più forti.' +
        '<br/>' +
        '<br/>' +
        '<b>In allegato puoi trovare tutte le informazioni relative al cliente e al progetto.</b>' +
        '<br/><br/>' +
        '###TABLE###' +
        '<br/>' +
        '<p>Cordiali saluti<p>';
        htmlContent += '<br/>';

        String table = '';
        table += '<table>';
        table += '<tr><th class=\'title\'>Etichetta</th><th>Valore</th></tr>';
        table += '<tr><th class=\'title\'>Oggetto</th><td>Account</td></tr>';
        table += '<tr><th class=\'title\'>ID Account</th><td>' + customdata.accountId + '</td></tr>';
        table += '<tr><th class=\'title\'>Nome</th><td>' + customdata.dataAccount.name + '</td></tr>';
        table += '<tr><th class=\'title\'>Via</th><td>' + customdata.dataAccount.BillingStreet + '</td></tr>';
        table += '<tr><th class=\'title\'>CAP</th><td>' + customdata.dataAccount.BillingPostalCode + '</td></tr>';
        table += '<tr><th class=\'title\'>Città</th><td>' + customdata.dataAccount.BillingCity + '</td></tr>';
        table += '<tr><th class=\'title\'>Partita IVA</th><td>' + customdata.dataAccount.Vat_number__c + '</td></tr>';
        table += '</table><br/>';

        table += '<table>';
        table += '<tr><th class=\'title\'>Etichetta</th><th>Valore</th></tr>';
        table += '<tr><th class=\'title\'>Oggetto</th><td>Opportunità</td></tr>';
        table += '<tr><th class=\'title\'>ID Progetto</th><td>' + customdata.projectId + '</td></tr>';
        table += '<tr><th class=\'title\'>Nome</th><td>' + customdata.dataProject.name + '</td></tr>';
        table += '<tr><th class=\'title\'>Via</th><td>' + customdata.dataProject.Address__c + '</td></tr>';
        table += '<tr><th class=\'title\'>CAP</th><td>' + customdata.dataProject.Postcode__c + '</td></tr>';
        table += '<tr><th class=\'title\'>Città</th><td>' + customdata.dataProject.City__c + '</td></tr>';
        table += '<tr><th class=\'title\'>Importo</th><td>' + customdata.dataProject.Amount_custom__c + '</td></tr>';
        table += '</table><br/>';

        htmlContent = htmlContent.replace('###TABLE###', table);
        htmlContent += '</body></html>';

        return htmlContent;
    }
}
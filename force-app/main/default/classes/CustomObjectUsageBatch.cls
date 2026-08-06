global class CustomObjectUsageBatch implements Database.Batchable<String>, Database.Stateful {

    public String emailTo;
    public String sortOrder;

    global CustomObjectUsageBatch(String emailTo, String sortOrder) {
        this.emailTo = emailTo;
        this.sortOrder = sortOrder;
    }

    public class ObjectStats {
        public String objectName;
        public Date oldestDate;
        public Integer last30Days = 0;
        public Integer last3Months = 0;
        public Integer last12Months = 0;
        public Integer total = 0;
    }

    public class ComparatorAlpha implements Comparator<ObjectStats> {
        public Integer compare(ObjectStats a, ObjectStats b) {
            return a.objectName.toLowerCase().compareTo(b.objectName.toLowerCase());
        }
    }

    public class ComparatorLow30 implements Comparator<ObjectStats> {
        public Integer compare(ObjectStats a, ObjectStats b) {
            return a.last30Days - b.last30Days;
        }
    }

    public class StringIterable implements Iterable<String> {
        private List<String> items;

        public StringIterable(List<String> input) {
            this.items = input;
        }

        public Iterator<String> iterator() {
            return items.iterator();
        }
    }

    private List<ObjectStats> results = new List<ObjectStats>();

    global Iterable<String> start(Database.BatchableContext bc) {
        List<String> customObjects = new List<String>();

        for (String sObjName : Schema.getGlobalDescribe().keySet()) {
            if (
                sObjName.endsWith('__c') &&
                !sObjName.startsWith('copado_') &&
                !sObjName.startsWith('copadoconnect_') &&
                !sObjName.startsWith('dfsle_') &&
                !sObjName.startsWith('et4ae5_') &&
                !sObjName.startsWith('gmpkg_') &&
                !sObjName.startsWith('talkdesk_')
            ) {
                customObjects.add(sObjName);
            }
        }

        // ⚠️ En modo test: solo devolver un objeto para evitar múltiples ejecuciones
        if (Test.isRunningTest() && customObjects.size() > 1) {
            customObjects = new List<String>{ customObjects[0] };
        }

        return new StringIterable(customObjects);
    }

    global void execute(Database.BatchableContext bc, List<String> scope) {
        Date today = Date.today();
        Date d30 = today.addDays(-30);
        Date d90 = today.addDays(-90);
        Date d365 = today.addDays(-365);

        for (String sObjectName : scope) {
            try {
                ObjectStats stats = new ObjectStats();
                stats.objectName = sObjectName;

                String queryOldest = 'SELECT CreatedDate FROM ' + sObjectName + ' ORDER BY CreatedDate ASC LIMIT 1';
                String query30 = 'SELECT COUNT() FROM ' + sObjectName + ' WHERE CreatedDate >= :d30';
                String query90 = 'SELECT COUNT() FROM ' + sObjectName + ' WHERE CreatedDate >= :d90';
                String query365 = 'SELECT COUNT() FROM ' + sObjectName + ' WHERE CreatedDate >= :d365';
                String queryTotal = 'SELECT COUNT() FROM ' + sObjectName;

                List<SObject> oldestRecord = Database.query(queryOldest);
                if (!oldestRecord.isEmpty()) {
                    stats.oldestDate = ((Datetime)oldestRecord[0].get('CreatedDate')).date();
                }

                stats.last30Days = Database.countQuery(query30);
                stats.last3Months = Database.countQuery(query90);
                stats.last12Months = Database.countQuery(query365);
                stats.total = Database.countQuery(queryTotal);

                results.add(stats);
            } catch (Exception ex) {
                System.debug('Error con objeto ' + sObjectName + ': ' + ex.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        if (sortOrder == 'alpha') {
            results.sort(new ComparatorAlpha());
        } else if (sortOrder == 'low30') {
            results.sort(new ComparatorLow30());
        } else if (sortOrder == 'noRecent90') {
            List<ObjectStats> filtered = new List<ObjectStats>();
            for (ObjectStats os : results) {
                if (os.last3Months == 0) {
                    filtered.add(os);
                }
            }
            results = filtered;
            results.sort(new ComparatorAlpha());
        }

        String html = '<html><body>';
        html += '<h2>Resumen de objetos custom</h2>';
        html += '<p>Orden: ' + sortOrder + '</p>';
        html += '<table border="1" cellpadding="5" cellspacing="0">';
        html += '<tr><th>Objeto</th><th>Fecha primer registro</th><th>Últimos 30 días</th><th>Últimos 3 meses</th><th>Último año</th><th>Total</th></tr>';

        for (ObjectStats os : results) {
            html += '<tr>';
            html += '<td>' + os.objectName + '</td>';
            html += '<td>' + (os.oldestDate != null ? os.oldestDate.format() : '-') + '</td>';
            html += '<td>' + os.last30Days + '</td>';
            html += '<td>' + os.last3Months + '</td>';
            html += '<td>' + os.last12Months + '</td>';
            html += '<td>' + os.total + '</td>';
            html += '</tr>';
        }

        html += '</table></body></html>';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] { emailTo });
        mail.setSubject('Informe de objetos custom - ' + Date.today().format());
        mail.setHtmlBody(html);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}
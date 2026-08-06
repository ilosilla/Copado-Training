@SuppressWarnings('PMD.ExcessiveParameterList, PMD.EmptyCatchBlock')
/**
 * ------------------------------------------------------------
 *  CLASS: SystemAlertService
 * ------------------------------------------------------------
 *  Author:      Ramón Prades
 *  Date:        January 2026
 *  Layer:       System / Framework
 *
 *  Description:
 *  ------------
 *  Ejecución de las alertas de sistema (SystemAlert = recopilación de info;
 *  este servicio = ejecución). Entrega por email, con dedup controlado.
 *
 *  Desacoplada del rollback vía el bus de eventos de sistema (SystemEvent__e,
 *  Publish Immediately): notify() convierte la alerta en un payload serializable
 *  y publica el evento; el subscriber (SystemEventTrigger → SystemEventDispatcher)
 *  instancia esta clase y llama a handle(), que entrega en su propia transacción
 *  (que hace commit). Así la alerta sale aunque la transacción del publicador
 *  reviente — que es justo cuando más interesa.
 *
 *  La firma pública notify(SystemAlert) no cambia: los callers actuales siguen
 *  funcionando. Fail-safe by design: nunca lanza excepciones al caller.
 *
 *  Ver nota de diseño: "DEV - Platform Events para eventos de sistema".
 * ------------------------------------------------------------
 * Test with SystemAlertTest.cls
 * ------------------------------------------------------------
 */
public without sharing class SystemAlertService extends SystemEventAbstractHandler {

    private static final String ORG_WIDE_SENDER_EMAIL = 'salesforce@porcelanosagrupo.com';
    private static final String SETTINGS_KEY = 'SYS_ALERT_SERVICE';
    private static final String CACHE_PARTITION = 'SystemAlertService';
    private static final Integer DEDUP_TTL_SECONDS = 1800; // 30 minutes
    private static final String HANDLER_NAME = 'SystemAlertService';

    /**
     * Payload serializable que viaja en el SystemEvent__e. Solo los campos que
     * usa la entrega. La SystemAlert no se serializa directa (su Exception no hace
     * round-trip en JSON): la excepción viaja descompuesta en strings. El usuario
     * se captura al publicar, porque handle() corre como Automated Process.
     */
    public class AlertPayload {
        public String source;
        public String severity;
        public String exceptionType;
        public String exceptionMessage;
        public String stackTrace;
        public String contextJson;   // JSON del Map: JSON.deserialize tipado no soporta Map<String,Object>
        public List<String> hints;
        public String dedupKey;
        public String userName;
        public String userType;
    }

    /* =========================================================
     * PUBLIC API — EMIT (publica el evento)
     * ========================================================= */

    public static void notify(SystemAlert alert) {
        try {
            AlertPayload p = new AlertPayload();
            p.source   = alert.source;
            p.severity = alert.severity != null ? alert.severity.name() : null;
            if (alert.alertException != null) {
                p.exceptionType    = alert.alertException.getTypeName();
                p.exceptionMessage = alert.alertException.getMessage();
                p.stackTrace       = alert.alertException.getStackTraceString();
            }
            p.contextJson = alert.context != null ? JSON.serialize(alert.context) : null;
            p.hints       = alert.hints;
            p.dedupKey = alert.dedupKey;
            p.userName = UserInfo.getUserName();
            p.userType = UserInfo.getUserType();

            SystemEvent__e evt = new SystemEvent__e();
            evt.Handler__c  = HANDLER_NAME;
            evt.Payload__c  = JSON.serialize(p);
            evt.Severity__c = p.severity;
            evt.Summary__c  = buildSummary(p);
            EventBus.publish(evt);

        } catch (Exception ignore) {
            // Fail-safe by design: las alertas nunca rompen el flujo de negocio.
        }
    }

    private static String buildSummary(AlertPayload p) {
        String source = String.isNotBlank(p.source) ? p.source : 'System alert';
        return String.isNotBlank(p.userName) ? source + ' — user ' + p.userName : source;
    }

    /* =========================================================
     * SUBSCRIBER — HANDLE (bus de eventos de sistema)
     * ========================================================= */

    public override void handle(SystemEvent__e evt) {
        AlertPayload p = (AlertPayload) JSON.deserialize(evt.Payload__c, AlertPayload.class);
        deliver(p);
    }

    /* =========================================================
     * DELIVERY (síncrono; corre en el subscriber, que hace commit)
     * ========================================================= */

    private static void deliver(AlertPayload p) {
        try {
            String dedupKey =
                !String.isBlank(p.dedupKey)
                    ? p.dedupKey
                    : buildDedupKey(p.source, p.severity, p.exceptionType, p.exceptionMessage);

            if (isDuplicate(dedupKey)) {
                return;
            }
            markAsSent(dedupKey);

            List<String> recipients = resolveRecipients(p.severity);
            if (recipients.isEmpty()) {
                return;
            }

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(recipients);
            mail.setSubject(buildSubject(p.source, p.severity));
            mail.setHtmlBody(buildHtmlBody(p));

            Id oweaId = resolveOrgWideEmailId();
            if (oweaId != null) {
                mail.setOrgWideEmailAddressId(oweaId);
            }

            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });

        } catch (Exception ignore) {
            // Silent by design
        }
    }

    /* =========================================================
     * EMAIL BODY
     * ========================================================= */

    private static String buildHtmlBody(AlertPayload p) {
        String html = '<html><body style="font-family:Arial;font-size:13px;">';

        html += '<h2 style="color:#b00020;">System Alert</h2>';
        html += '<p><b>Source:</b> ' + p.source + '</p>';

        html += '<h3>Execution Context</h3><ul>';
        html += '<li><b>User:</b> ' + p.userName + '</li>';
        html += '<li><b>User Type:</b> ' + p.userType + '</li>';
        html += '<li><b>Timestamp:</b> ' + System.now() + '</li>';
        html += '</ul>';

        if (!String.isBlank(p.exceptionType) || !String.isBlank(p.exceptionMessage)) {
            html += '<h3>Exception</h3>';
            html += '<pre style="background:#f4f4f4;padding:10px;">';
            html += p.exceptionType + '\n' + p.exceptionMessage;
            if (!String.isBlank(p.stackTrace)) {
                html += '\n\n' + p.stackTrace;
            }
            html += '</pre>';
        }

        Map<String, Object> context = String.isBlank(p.contextJson)
            ? null
            : (Map<String, Object>) JSON.deserializeUntyped(p.contextJson);
        if (context != null && !context.isEmpty()) {
            html += '<h3>Context</h3><ul>';
            for (String key : context.keySet()) {
                html += '<li><b>' + key + ':</b> ' + context.get(key) + '</li>';
            }
            html += '</ul>';
        }

        if (p.hints != null && !p.hints.isEmpty()) {
            html += '<h3>Investigation Hints</h3><ul>';
            for (String h : p.hints) {
                html += '<li>' + h + '</li>';
            }
            html += '</ul>';
        }

        html += '<hr style="margin-top:20px;"/>';
        html += '<p style="font-size:11px;color:#777;">';
        html += 'Additional alerts of the same type may have occurred but were ';
        html += 'suppressed by the deduplication policy.';
        html += '</p>';
        html += '<p style="font-size:11px;color:#666;">Salesforce automatic alert</p>';
        html += '</body></html>';

        return html;
    }

    /* =========================================================
     * DEDUP
     * ========================================================= */

    private static String buildDedupKey(
        String source,
        String severity,
        String exceptionType,
        String exceptionMessage
    ) {
        String base =
            source + '|' +
            severity + '|' +
            exceptionType + '|' +
            normalize(exceptionMessage);

        return EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256', Blob.valueOf(base))
        );
    }

    private static String normalize(String input) {
        if (String.isBlank(input)) {
            return '';
        }
        String s = input.toLowerCase();
        s = s.replaceAll('[0-9]+', '#');
        return s.length() > 200 ? s.substring(0, 200) : s;
    }

    private static Boolean isDuplicate(String key) {
        try {
            Cache.OrgPartition p = Cache.Org.getPartition(CACHE_PARTITION);
            return p != null && p.get(key) != null;
        } catch (Exception e) {
            return false; // fail-open
        }
    }

    private static void markAsSent(String key) {
        try {
            Cache.OrgPartition p = Cache.Org.getPartition(CACHE_PARTITION);
            if (p != null) {
                p.put(key, true, DEDUP_TTL_SECONDS);
            }
        } catch (Exception ignore) {}
    }

    /* =========================================================
     * CONFIG
     * ========================================================= */

    private static List<String> resolveRecipients(String severity) {
        List<String> levels = new List<String>{ 'HIGH', 'MEDIUM', 'LOW' };
        Integer start = levels.indexOf(severity);
        if (start < 0) {
            start = 0;
        }

        for (Integer i = start; i < levels.size(); i++) {
            List<PorcelanosaSetting__c> cfg = [
                SELECT Value1__c
                FROM PorcelanosaSetting__c
                WHERE Key__c = :SETTINGS_KEY
                AND SubKey__c = :levels[i]
                LIMIT 1
            ];

            if (!cfg.isEmpty() && !String.isBlank(cfg[0].Value1__c)) {
                return cfg[0].Value1__c.replace(' ', '').split(',');
            }
        }
        return new List<String>{ 'rprades@porcelanosagrupo.com' };
    }

    private static Id resolveOrgWideEmailId() {
        try {
            return [
                SELECT Id
                FROM OrgWideEmailAddress
                WHERE Address = :ORG_WIDE_SENDER_EMAIL
                LIMIT 1
            ].Id;
        } catch (Exception e) {
            return null;
        }
    }

    private static String buildSubject(String source, String severity) {
        return '[ALERT][' + severity + '] ' + source;
    }
}
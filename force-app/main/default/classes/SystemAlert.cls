/****
 * ------------------------------------------------------------
 *  CLASS: SystemAlert
 * ------------------------------------------------------------
 *  Author:      Ramón Prades
 *  Date:        January 2026
 *  Layer:       System / Framework
 *
 *  Description:
 *  ------------
 *  Domain object representing a system alert that requires
 *  human attention.
 *
 *  A SystemAlert can represent:
 *   - Technical incidents (exceptions, integration failures)
 *   - Business incidents (pricing mismatch, credit issues)
 *   - Relevant system conditions that must be reviewed
 *
 *  This class is intentionally expressive and safe to use
 *  from both technical and business code paths.
 *
 *  Delivery responsibilities (email, deduplication, async)
 *  are delegated to SystemAlertService.
 * 
 *  Usage Example:
 *  --------------
 *  SystemAlert alert = new SystemAlert('OrderProcessing', SystemAlert.Severity.HIGH)
 *      .withContext(new Map<String, Object>{'orderId' => 12345, 'userId' => 'abc123'})
 *      .withHints(new List<String>{'Check payment gateway', 'Verify inventory levels'})
 *      .withDedupKey('Order_12345_PaymentIssue');
 *  SystemAlertService.send(alert);
 * ------------------------------------------------------------
 */
public class SystemAlert {

    public enum Severity {
        HIGH,
        MEDIUM,
        LOW
    }

    /* =========================================================
     * CORE ATTRIBUTES
     * ========================================================= */

    // Logical source of the alert (application, process, module)
    public String source;

    // Severity level (e.g. HIGH, MEDIUM, LOW)
    public Severity severity;

    /* =========================================================
     * OPTIONAL ATTRIBUTES
     * ========================================================= */

    // Optional technical exception (for technical alerts)
    public Exception alertException;

    // Additional contextual information
    public Map<String, Object> context;

    // Diagnostic or investigation hints
    public List<String> hints;

    // Explicit deduplication key (recommended for business alerts)
    public String dedupKey;

    /* =========================================================
     * CONSTRUCTOR
     * ========================================================= */

    public SystemAlert(String source, Severity severity) {
        this.source = source;
        this.severity = severity;
    }

    /* =========================================================
     * FLUENT SETTERS
     * ========================================================= */

    public SystemAlert withException(Exception ex) {
        this.alertException = ex;
        return this;
    }

    public SystemAlert withContext(Map<String, Object> context) {
        this.context = context;
        return this;
    }

    public SystemAlert withHints(List<String> hints) {
        this.hints = hints;
        return this;
    }

    public SystemAlert withDedupKey(String dedupKey) {
        this.dedupKey = dedupKey;
        return this;
    }

    /* =========================================================
     * EMIT — cierre del fluent
     * ========================================================= */

    /**
     * Publica la alerta en el bus de eventos de sistema. Cierre natural del builder:
     *   new SystemAlert(...).withException(ex).withContext(ctx).withHints(h).notify();
     * Delega en SystemAlertService, que convierte y publica el SystemEvent__e.
     */
    public void notify() {
        SystemAlertService.notify(this);
    }
}
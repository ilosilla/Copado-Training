/**
 * Author: Ivan Losilla
 * Date: 25-05-2020
 * Description: 
 *      Class in charge of knowing and setting the last date (because of modification or creation) of any object
 *      related to an Opportunity and all objects related to this
 * 
 * Related Objects:
 *     * Opportunities
 *         - Team Members
 *         - Actors
 *         - Events
 *         - Tasks
 *         - Files
 * 
 * Use examples:-------------------
 *  OpportunityActivity oppAc = new OpportunityActivity('0069E00000FAiUTQA1'): //Get opportunity
 *  DateTime aux = oppAc.getOpportunityLastActivityDate(); returns the last ActivityDate
 *  oppAc.setOpportunityLastActivityDate(); sets the field Last_Activity_Date__c with the date returned by getOpportunityLastActivityDate
 *  oppAc.setOpportunityLastActivityDate(System.now()); sets the field Last_Activity_Date__c with the passed as parameter
 */
/**
* @date September 2021
* @group Opportunity
* @deprecated  We don't use this one
*/
public class OpportunityActivity {}
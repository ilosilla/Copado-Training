/**
* @author Ivan Losilla Perez
* @date 10-2020
*
* @group Mail
* @group-content ../../ApexDocContent/MailHtml.htm
*
* @description Class wich creates the HTML of the body of the emails
*/
public class MailHtml {
    /**
    * @description Creates a Html table given headers, name of the fields and a list of objects 
    * @param List<String> headers Text of the headers of the table
    * @param List<String> fieldNames Name of the fields to print on each cell
    * @param List<sObject> dataList List of objects, each of them is going to be a row
    * @return Html of the table
    *
    * @example 
    * List<String> headersTable = new List<String>{'User Id','Name','Email Address'};
    * List<String> fieldsTable = new List<String>{'Id','Name','Email'};
    * List<User> listUsers = [SELECT Id, Name, Email FROM User];
    * String tableHtml = MailHtml.createTableFields(headersTable, fieldsTable, listUsers);
    */
    public static String createTableFields(List<String> headers, List<String> fieldNames, List<sObject> dataList) {
        String htmlTable =  '<table>';

        htmlTable += '<tr>';
        for (String columnHeader : headers) {
            htmlTable += '<th>' +
            columnHeader +
            '</th>';
        }
        htmlTable += '</tr>';
        
        for (sObject row : dataList) {
            htmlTable += '<tr>';
            for (String columnValue : fieldNames) {
                htmlTable += '<td>' +
                MailUtils.getSobjectField(row,columnValue) +
                '</td>';
            }
            htmlTable += '</tr>';
        }

        htmlTable +=  '</table>';

        return htmlTable;
    }

    /**
    * @description Creates a Html table given headers and the exact value of each cell 
    * @param List<String> headers Text of the headers of the table
    * @param List<List<String>> rows List of the "rows" we eant to print on the Table
    * @return Html of the table
    *
    * @example 
    * List<String> headersTable = new List<String>{'Name','Surname','DNI', 'Phone'};
    * List<String> rowOne = new List<String>{'Ivan', 'Losilla', '11111111X', '667 233 443'};
    * List<String> rowTwo = new List<String>{'Ramón', 'Prades', '22222222T', '667 233 443'};
    * List<List<String>> rowsTable = new List<String>{rowOne, rowTwo};
    * String tableHtml = MailHtml.createTableFields(headersTable, rowsTable);
    */
    public static String createTableValues(List<String> headers, List<List<String>> rows) {
        String htmlTable =  '<table>';

        htmlTable += '<tr>';
        for (String columnHeader : headers) {
            htmlTable += '<th>' +
            columnHeader +
            '</th>';
        }
        htmlTable += '</tr>';
        
        if (rows.size() == 0) {
            htmlTable += '<tr>';
            htmlTable += '<td colspan="' + headers.size() + '"> There is no data to show </td>';
            htmlTable += '</tr>';
        } else {
            
            for (integer i = 0; i < rows.size(); i++) {
                htmlTable += '<tr>';
                for (String value : rows[i]) {
                    htmlTable += '<td>';
                    htmlTable += value;
                    htmlTable += '</td>';
                }
                htmlTable += '</tr>';
            }
        }

        htmlTable +=  '</table>';

        return htmlTable;
    }

    public static String createTitle(String text) {
        return '<table>' +
                '<tr><th>' + text + '</th></tr>' +
            '</table>';
        }
        
    public static String createHeader(String text) {
        return '<p>' +
                    text +
                '</p><br/>';
            
    }
}
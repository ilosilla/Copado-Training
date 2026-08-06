/**
* @author Ivan Losilla Perez
* @date 10-2020
*
* @group Mail
* @group-content ../../ApexDocContent/MailStyles.htm
*
* @description Class that manage the different styles given to the emails
*/
public class MailStyles {

    /**
    * @description Html of the style used for internal Mails
    * @param void
    * @return Html with the Style part of the body
    *
    * @example 
    * String styleHtml = MailStyles.internalStyle();
    */
    public static String internalStyle() {
        return '<style>' +
                'th{' +
                    'background: #1F3864;' +
                    'font-weight: bold;' +
                    'border: 1px solid black;' +
                    'color: white;' +
                    'text-align: center;' +
            		'font-size: 13px;' +
                '}' +
            	'td{' +
                    'font-size: 12px;' +
                    'text-align: left;' +
            		'border: 1px solid black;' +
            		'padding: 0px!important;' +
            		'text-align: center;' +
                '}' +
            	'table{' +
                    'width: 100%;' +
                    'margin: 15px auto;' +
            		'text-align: center;' +
                    'border-collapse: collapse;' +
                '}' +
            	'.gray{' +
                    'background: #C4C3C3;' +
                '}' +
                'p{' +
                    'margin: 2px;' +
                '}' +
            '</style>';
    }
}
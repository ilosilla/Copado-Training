/**
* @author 		Ramón Prades
* @date 		March 2022
* @group 		API
* @description 	Data transfer object to receive files over a rest api
*/
global class OAttachmentDTO {
    global String fileName;
    global String title;
    global String parentId;
    global String content;
    global Boolean encoded = true; // False if text
}
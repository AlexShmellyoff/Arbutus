public class RemoveHTMLTags {

    @InvocableMethod(label='Remove HTML Tags')
    public static List<String> removeHtmlTags(List<String> richTextList) {
        //String richText = richTextList[0];
        
        // plainText List that will be returned by the method
        List<String> plainTextList = new List<String>();
        
        // Loop through list
        // Necessary to avoid number of results does not match interviews error
        for (string s : richTextList) {
        
            // replace Tags with uncommon characters
            s = s.replaceAll('<(?:/(?:p|li|div|h\\d|tr|dt|blockquote)|(?:p)/)>', '$0~~~');
        
            // Use the stripHtmlTags function to remove the HTML tags
            s = s.stripHtmlTags();
        
            // Add linebreaks back
            s = s.replaceAll('~~~', '\n');
        
            // Add the updated richText string to the list of plain text that will be returned
            plainTextList.add(s);
        }
        return plainTextList;
    }
}
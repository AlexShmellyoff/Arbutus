@isTest
public with sharing class RemoveHtmlMarkupTest {
    
    @isTest
    static  void stripHtmlTagsTest() {
        String htmlText = '<p>This is a <strong>test</strong> string with <a href="http://example.com">HTML</a> tags.</p>';
        String expectedOutput = 'This is a test string with HTML tags.\n';
        
        String result = RemoveHtmlMarkup.stripHtmlTags(htmlText);
        
        System.assertEquals(expectedOutput, result, 'The HTML tags should be removed and new lines added.');
    }

    @isTest
    static void stripHtmlTagsNullTest() {
        String htmlText = null;
        String expectedOutput = '';
        
        String result = RemoveHtmlMarkup.stripHtmlTags(htmlText);
        
        System.assertEquals(expectedOutput, result, 'The output should be an empty string when input is null.');
    }
}
public class RemoveHtmlMarkup {

    public static String stripHtmlTags(String htmlText) {
        if (htmlText == null) {
            return '';
        }
        

        String modifiedString = htmlText.replaceAll('<p>', '').replaceAll('</p>', '\n');

        // Manually remove remaining HTML tags

        modifiedString = modifiedString.replaceAll('<[^>]+>', '');

        

        return modifiedString;

    }

}
class ProfanityFilter {
  static final List<String> _censorList = [
    "kill yourself", 
    "suicide", 
    "hurt yourself", 
    "die", 
    "kill myself", 
    "cutting myself",
    "end it all",
    "rape",
    "murder",
    "fuck",
    "shit",
    "bitch",
    "asshole",
    "goon",
    "masturbate",
    "edge",
    "blowjob", 
    "sexual",
    "sex",
    "cum",
    "dick",
    "pussy"
  ];

  static String censor(String text) {
    if (text.isEmpty) return text;
    
    String censoredText = text;
    for (final word in _censorList) {
      final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
      censoredText = censoredText.replaceAllMapped(pattern, (match) {
        return '*' * match.group(0)!.length;
      });
    }
    return censoredText;
  }
  
  static bool containsProfanity(String text) {
     if (text.isEmpty) return false;
     for (final word in _censorList) {
       if (text.toLowerCase().contains(word.toLowerCase())) {
         return true;
       }
     }
     return false;
  }
}

from better_profanity import profanity

# Initialize with default swear words
profanity.load_censor_words()
# Add specific self-harm and threat phrases to be stricter
profanity.add_censor_words([
    "kill yourself", 
    "suicide", 
    "hurt yourself", 
    "die", 
    "kill myself", 
    "cutting myself",
    "end it all",
    "rape",
    "murder"
])

def contains_profanity(text: str) -> bool:
    """
    Check if the text contains any profanity.
    Returns True if profanity is found, False otherwise.
    """
    if not text:
        return False
    return profanity.contains_profanity(text)

def censor_profanity(text: str) -> str:
    """
    Censor any profanity in the text with asterisks.
    """
    if not text:
        return ""
    return profanity.censor(text)

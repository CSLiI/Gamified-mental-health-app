try:
    from better_profanity import profanity
    HAS_PROFANITY_LIB = True
except ImportError:
    HAS_PROFANITY_LIB = False
    print("⚠️ WARNING: 'better-profanity' library not found. Profanity filtering is DISABLED.")

# Initialize with default swear words if available
if HAS_PROFANITY_LIB:
    try:
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
            "murder",
            "goon",
            "masturbate",
            "edge",
            "blowjob",
            "sexual",
            "sex",
            "cum",
            "dick",
            "pussy"
        ])
    except Exception as e:
        print(f"⚠️ WARNING: Failed to initialize profanity words: {e}")
        HAS_PROFANITY_LIB = False

def contains_profanity(text: str) -> bool:
    """
    Check if the text contains any profanity.
    Returns True if profanity is found, False otherwise.
    Safe to call even if library is missing (returns False).
    """
    if not text or not HAS_PROFANITY_LIB:
        return False
    return profanity.contains_profanity(text)

def censor_profanity(text: str) -> str:
    """
    Censor any profanity in the text with asterisks.
    Safe to call even if library is missing (returns original text).
    """
    if not text:
        return ""
    if not HAS_PROFANITY_LIB:
        return text
    return profanity.censor(text)

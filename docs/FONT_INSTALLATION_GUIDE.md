# Font Installation Guide - Nunito ✨

## Why Nunito?

Nunito is THE PERFECT choice for a gamified mental health app because:

- ✅ **Rounded & Soft** - Psychological comfort and safety
- ✅ **Warm & Approachable** - Makes users feel welcomed
- ✅ **Playful but Professional** - Perfect balance for gamification
- ✅ **Excellent Readability** - Easy on the eyes for mental health content
- ✅ **Used by Top Wellness Apps** - Headspace, Calm use similar rounded fonts
- ✅ **Perfect for Students** - Appeals to younger users without being childish
- ✅ **Free & Open Source** - Available on Google Fonts

## Installation Steps

### 1. Download Nunito Font Files

Visit Google Fonts and download Nunito:
👉 https://fonts.google.com/specimen/Nunito

**Or download directly:**

1. Go to: https://fonts.google.com/specimen/Nunito
2. Click "Download family" button (top right)
3. Extract the ZIP file

### 2. Create Fonts Directory

In your project root, create:

```
mental_health_app/
  assets/
    fonts/
```

### 3. Copy Font Files

From the downloaded Nunito folder, copy these files to `assets/fonts/`:

Required files:

- ✅ `Nunito-Regular.ttf` (weight: 400)
- ✅ `Nunito-Medium.ttf` (weight: 500)
- ✅ `Nunito-SemiBold.ttf` (weight: 600)
- ✅ `Nunito-Bold.ttf` (weight: 700)
- ✅ `Nunito-ExtraBold.ttf` (weight: 800)

### 4. Verify File Structure

Your structure should look like:

```
mental_health_app/
  assets/
    fonts/
      Nunito-Regular.ttf
      Nunito-Medium.ttf
      Nunito-SemiBold.ttf
      Nunito-Bold.ttf
      Nunito-ExtraBold.ttf
    images/
      Boy_Gif_33FPS/
      Girl_Gif_33FPS/
    ...
  lib/
    ...
  pubspec.yaml
```

### 5. Run Flutter Commands

After copying fonts:

```bash
flutter clean
flutter pub get
flutter run
```

## Font Usage in Code

The font is now applied globally via `main.dart` theme configuration!

**You don't need to specify `fontFamily: 'Nunito'` in individual widgets** - it's automatic.

### Font Weights Available:

- `FontWeight.normal` or `FontWeight.w400` - Regular
- `FontWeight.w500` - Medium
- `FontWeight.w600` - SemiBold
- `FontWeight.bold` or `FontWeight.w700` - Bold
- `FontWeight.w800` - ExtraBold

### Example Usage:

```dart
Text(
  'Hello World',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold, // Uses Nunito Bold automatically
  ),
)
```

## Troubleshooting

### Font not showing up?

1. ✅ Verify font files are in `assets/fonts/`
2. ✅ Check file names match exactly (case-sensitive)
3. ✅ Run `flutter clean` and `flutter pub get`
4. ✅ Hot restart (not just hot reload)
5. ✅ Check `pubspec.yaml` indentation is correct

### Still having issues?

- Ensure all font files are `.ttf` format
- Check the Flutter console for font loading errors
- Try copying one font file at a time and testing

## What's Been Updated

✅ `pubspec.yaml` - Font configuration with Nunito
✅ `main.dart` - Global theme with Nunito applied
✅ `profile_screen.dart` - Redesigned with accurate data
✅ All existing text will automatically use Nunito font

## Why Nunito Over Other Fonts?

### Mental Health Context:

- 🧠 **Rounded fonts reduce stress** - Sharp angles can feel aggressive
- 💚 **Creates psychological safety** - Softer letterforms = more comfortable
- 🌟 **Non-clinical feel** - Avoids medical/hospital associations

### Gamification Context:

- 🎮 **Playful personality** - Fun for achievements, rewards, levels
- 🏆 **Maintains seriousness** - Not too childish for mental health topics
- ⚡ **Energetic but calm** - Perfect balance for wellness + gaming

### Student Audience:

- 👥 **Appeals to Gen Z** - Modern, friendly aesthetic
- 📱 **Screen-optimized** - Clear on all devices
- 🎨 **Versatile** - Works for UI text, headings, and body content

## Next Steps

After installing fonts:

1. Hot restart your app
2. Navigate through all screens
3. Verify Nunito font is applied everywhere
4. Enjoy the warm, friendly, therapeutic look! 🎉💚

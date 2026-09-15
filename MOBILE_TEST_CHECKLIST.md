# Hearing Assist Mobile Test Checklist

## 📱 Pre-Installation Setup
- [ ] Enable "Install from Unknown Sources" in Android settings
- [ ] Ensure device has at least 50MB free storage
- [ ] Enable device vibration in system settings
- [ ] Allow microphone permissions when prompted

## 🚀 Installation Test
- [ ] APK installs without errors
- [ ] App icon appears as "Hearing Assist Demo"
- [ ] App launches on first tap
- [ ] No crash on initial startup

## 🎯 Haptic Feedback Tests (30 seconds)
- [ ] **Speech Detection**: Feel light pulse when captions appear
- [ ] **High Confidence**: Short, sharp vibration for clear speech
- [ ] **Low Confidence**: Double-pulse pattern for uncertain words
- [ ] **Danger Alerts**: Strong triple-pulse for alarms/horns
- [ ] **Settings Toggle**: Turn haptics on/off and verify behavior changes

## 📱 Screen Layout Tests (1 minute)
- [ ] **Portrait Mode**: Layout fits properly in portrait
- [ ] **Landscape Mode**: Try rotation - should stay in portrait
- [ ] **Status Bar**: Green "[ MIC ACTIVE ]" indicator visible
- [ ] **Silence Indicator": "..." appears when no speech
- [ ] **Danger Banner**: Red alert banner appears for danger sounds
- [ ] **Caption Area**: Text scrolls smoothly to newest captions
- [ ] **Bottom Bar**: Action buttons accessible and not cut off

## 🎨 Accessibility Theme Tests (1 minute)
- [ ] **Default Theme**: Dark background, white text readable
- [ ] **High Contrast**: Test in Settings > Contrast Mode > High Contrast
- [ ] **Caption Sizes**: Test all 4 sizes (Small, Medium, Large, Extra Large)
- [ ] **Speaker Colors**: Different speakers have distinct badge colors
- [ ] **Low Confidence Highlighting**: Yellow tint on uncertain words
- [ ] **Tone Badges**: Emoji icons (😌 ⚡ ⚠ 💬) visible and tappable

## 🔘 Feature Tests (2 minutes)
- [ ] **Freeze/Resume**: Tap pause button - captions stop, tap play - resumes
- [ ] **30s Rewind**: Toggle between live stream and 30-second buffer
- [ ] **Settings Sheet**: Opens without crash, all controls work
- [ ] **History Sheet**: Opens, shows past captions
- [ ] **Export .txt**: Generate text file - check file saves
- [ ] **Export .csv**: Generate CSV file - check file saves
- [ ] **Clear History**: Clear button removes all history
- [ ] **Speaker Rename**: Rename "Speaker 1" to custom name
- [ ] **Mock Toggle**: Switch between mock and live modes

## 💬 Tone Detection Tests (1 minute)
- [ ] **Tone Badges**: Tone icons appear with confidence scores
- [ ] **Tone Dialog**: Tap tone badge - dialog opens with explanation
- [ ] **Tone Types**: See different tones (Calm, Excited, Tense, Neutral)
- [ ] **Honest Explanations**: Text says "Voice characteristics suggest..." not absolute statements

## 🔊 Sound Detection Tests (1 minute)
- [ ] **Danger Alerts**: Red banner appears for alarms/horns
- [ ] **Alert Dismissal**: Close button removes danger banner
- [ ] **Sound Confidence**: Shows percentage confidence
- [ ] **Honest Descriptions**: Text says "Possible Vehicle Horn detected" not "Car is coming"

## 📊 Visual Evidence Card Tests (30 seconds)
- [ ] **Card Display**: Evidence card appears below captions
- [ ] **Expand/Collapse**: Tap to expand and collapse details
- [ ] **Evidence Data**: Shows Source, Type, Value, Confidence, Verification State
- [ ] **Real-time Updates**: Values update as new captions appear

## 🔄 Navigation Tests (30 seconds)
- [ ] **Back Button**: Android back button behavior works
- [ ] **App Switching**: Switch to other apps and return - app maintains state
- [ ] **Memory**: App doesn't crash after extended use (5+ minutes)

## 📁 File Export Tests (1 minute)
- [ ] **Text Export**: .txt file contains proper formatting
- [ ] **CSV Export**: .csv file has headers and proper data
- [ ] **File Location**: Check Downloads folder for exported files
- [ ] **File Opening**: Can open exported files in text editor
- [ ] **Clear Function**: Clear history removes exported data

## 🎯 Overall Experience (30 seconds)
- [ ] **Performance**: No significant lag or stuttering
- [ ] **Battery**: Battery drain is reasonable
- [ ] **Heat**: Device doesn't overheat during use
- [ ] **Crashes**: No crashes during 5-minute continuous use
- [ ] **Usability**: Interface is intuitive and responsive

## 📝 Notes
- Total estimated test time: **8-10 minutes**
- Focus on haptic feedback and accessibility features
- Test with device volume at different levels
- Test in different lighting conditions for visibility

# 🆓 How to Get Free AI API Keys

## 🎯 Quick Solution: Google Gemini (Recommended)

### **Step 1: Get Google Gemini API Key (FREE)**
1. **Visit**: https://makersuite.google.com/app/apikey
2. **Sign in** with your Google account
3. **Click** "Create API key"
4. **Copy** the API key
5. **Replace** in `ai_service.dart`:
   ```dart
   final String geminiApiKey = "YOUR_ACTUAL_API_KEY_HERE";
   ```

### **Why Gemini?**
- ✅ **Free tier available** (generous credits)
- ✅ **Fast response times**
- ✅ **Image analysis support** (for camera features)
- ✅ **Easy setup**

## 🔄 Alternative: OpenAI API (Backup Option)

### **Step 1: Get OpenAI API Key**
1. **Visit**: https://platform.openai.com/api-keys
2. **Sign up** for free account
3. **Get $5 free credits** (valid for 3 months)
4. **Create API key**
5. **Replace** in `ai_service.dart`:
   ```dart
   final String openAIApiKey = "YOUR_ACTUAL_API_KEY_HERE";
   final String activeProvider = "openai"; // Change this line
   ```

## 🤖 Alternative: Hugging Face (Backup Option)

### **Step 1: Get Hugging Face API Key**
1. **Visit**: https://huggingface.co/settings/tokens
2. **Sign up** for free account
3. **Create API token**
4. **Replace** in `ai_service.dart`:
   ```dart
   final String huggingFaceApiKey = "YOUR_ACTUAL_API_KEY_HERE";
   final String activeProvider = "huggingface"; // Change this line
   ```

## 🔧 Quick Fix for Your Current Error

### **Immediate Solution:**
1. **Open** `lib/services/ai_service.dart`
2. **Replace** this line:
   ```dart
   final String geminiApiKey = "YOUR_GEMINI_API_KEY_HERE";
   ```
   **With your actual API key**

3. **Keep** this line for Gemini:
   ```dart
   final String activeProvider = "gemini";
   ```

### **If You Want to Use OpenAI Instead:**
1. **Get OpenAI API key** (follow steps above)
2. **Replace** in `ai_service.dart`:
   ```dart
   final String openAIApiKey = "YOUR_OPENAI_API_KEY_HERE";
   final String activeProvider = "openai"; // Change to "openai"
   ```

## 🚀 Testing Your Setup

### **Test 1: Simple Chat**
1. Run your app
2. Go to **AI Chatbot** feature
3. Type: "Hello"
4. Should get a response

### **Test 2: Symptom Checker**
1. Go to **Symptom Checker**
2. Type: "headache"
3. Should get medical advice

### **Test 3: Camera (if working)**
1. Go to **Camera Diagnosis**
2. Take a photo
3. Should analyze the image

## 🆘 Troubleshooting

### **Still Getting 404 Error?**
1. **Check API key** - Make sure it's copied correctly
2. **Check internet** - Try opening https://makersuite.google.com in browser
3. **Check quota** - Free tier might be exhausted
4. **Try alternative** - Switch to OpenAI or Hugging Face

### **API Key Not Working?**
- Make sure no extra spaces
- Make sure you copied the full key
- Make sure you replaced the correct variable
- Make sure you saved the file

### **Need Help?**
- **Google Gemini**: https://developers.google.com/ai/gemini-api/docs/quickstart
- **OpenAI**: https://platform.openai.com/docs/quickstart
- **Hugging Face**: https://huggingface.co/docs/api-inference/index

## 🎉 You're Ready!

Once you get an API key and update the code:
- ✅ **No more 404 errors**
- ✅ **All AI features working**
- ✅ **Ready for hackathon demo**

**Start with Google Gemini - it's the easiest and most reliable for your use case!** 🚀
# 🔍 Debug Testing Issues

## 🚨 **Common Testing Problems & Solutions**

### **Problem 1: 404 Error Still Occurring**

**Check your endpoint format:**
Your curl command uses:
```bash
https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent
```

But your app might be using a different format. Let me verify...

**✅ Your app is using the correct endpoint:**
```dart
"https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey"
```

### **Problem 2: API Key Issues**

**Test your API key directly:**
1. **Open browser** and visit:
   ```
   https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=AIzaSyAGEgzDDbUHtvJAOdOUqmPJADU-7N995_Y
   ```

2. **Expected response:**
   - ✅ **Valid**: JSON with model information
   - ❌ **Invalid**: 404, 401, or "API key not valid"

### **Problem 3: Request Format Issues**

**Your curl works, but app doesn't?** Let me check the request format...

**Your working curl:**
```bash
curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent" \
  -H 'Content-Type: application/json' \
  -H 'X-goog-api-key: AIzaSyAGEgzDDbUHtvJAOdOUqmPJADU-7N995_Y' \
  -X POST \
  -d '{
    "contents": [
      {
        "parts": [
          {
            "text": "Explain how AI works in a few words"
          }
        ]
      }
    ]
  }'
```

**Your app uses:**
```dart
headers: {"Content-Type": "application/json"}
body: jsonEncode({"contents": [{"parts": parts}]})
```

**🔍 Issue Found!** Your curl uses `X-goog-api-key` header, but your app uses query parameter `?key=$apiKey`.

## 🛠️ **Quick Fix**

### **Option 1: Fix Headers (Recommended)**
Update your AI service to use the same headers as your working curl:

```dart
final response = await http.post(
  url,
  headers: {
    "Content-Type": "application/json",
    "X-goog-api-key": apiKey,  // Add this line
  },
  body: jsonEncode({
    "contents": [{"parts": parts}]
  }),
).timeout(const Duration(seconds: 30));
```

### **Option 2: Keep Query Parameter**
If you want to keep the query parameter format, make sure your API key is valid for that format.

## 🧪 **Step-by-Step Testing**

### **Test 1: Browser Test**
1. Visit: `https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=AIzaSyAGEgzDDbUHtvJAOdOUqmPJADU-7N995_Y`
2. **If 404**: API key invalid or endpoint wrong
3. **If JSON response**: API key works

### **Test 2: Terminal Test**
Run your curl command:
```bash
curl "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent" \
  -H 'Content-Type: application/json' \
  -H 'X-goog-api-key: AIzaSyAGEgzDDbUHtvJAOdOUqmPJADU-7N995_Y' \
  -X POST \
  -d '{
    "contents": [
      {
        "parts": [
          {
            "text": "Hello"
          }
        ]
      }
    ]
  }'
```

### **Test 3: App Test**
1. **Update AI service** with correct headers (see Option 1 above)
2. **Run app**
3. **Test chatbot** with "Hello"

## 🎯 **Most Likely Issue**

Your curl command uses `X-goog-api-key` header, but your app uses query parameter. **This is probably why your curl works but app doesn't.**

**Fix**: Update your AI service to use the same header format as your working curl command.

## 📞 **Need More Help?**

Please share:
1. **Exact error message** you're seeing
2. **Which feature** you're testing
3. **Screenshot** of the error if possible

This will help me identify the specific issue! 🔍
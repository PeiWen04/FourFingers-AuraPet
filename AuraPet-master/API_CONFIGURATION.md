# AuraPet - API Configuration

## Gemini API Key Setup

The AuraPet application uses Google's Gemini AI to power the pet companion chat functionality. The API key is currently configured in the `.env` file.

### Current Configuration

✅ **API Key Status**: Active
- **Key**: `AIzaSyBISVJ7U_tjvCNfOOURu6-9L7eoL5RcWsA`
- **Location**: `.env` file in the root directory
- **Variable Name**: `GEMINI_API_KEY`

### How It Works

1. The API key is loaded from the `.env` file when the app starts
2. The key is accessed in [lib/pages/chat_session_page.dart](lib/pages/chat_session_page.dart) using:
   ```dart
   final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
   ```
3. The key is passed to the PetService to initialize the Gemini AI model
4. The app uses the `gemini-2.5-flash-lite` model for chat responses

### Security Recommendations

⚠️ **IMPORTANT SECURITY NOTES**:

1. **DO NOT** commit the `.env` file to version control
2. Add `.env` to your `.gitignore` file
3. Consider rotating this API key and using environment-specific keys
4. For production, use Firebase Remote Config or environment variables
5. Implement API key restrictions in the Google Cloud Console:
   - Restrict by HTTP referrers (for web)
   - Restrict by Android/iOS app
   - Limit to specific APIs (Generative Language API only)

### Getting Your Own API Key

If you need to generate a new API key:

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the key and replace it in your `.env` file:
   ```
   GEMINI_API_KEY=your_new_api_key_here
   ```
5. Restart the application

### Troubleshooting

If the pet doesn't respond:
1. Check if the `.env` file exists in the root directory
2. Verify the API key is correct
3. Check the console for error messages
4. Ensure you have an active internet connection
5. Verify your API key hasn't exceeded its quota

### Testing the API Key

The app automatically checks if the API key is loaded and displays a message in the console:
- ✅ If successful: "API Key loaded: Yes"
- ❌ If failed: "API Key loaded: No - Please set GEMINI_API_KEY in .env file"

You can also test the initialization in the console:
- ✅ "Pet initialized successfully as [Penguin/Owl]"
- ❌ "Failed to initialize pet: [error message]"

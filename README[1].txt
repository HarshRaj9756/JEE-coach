JEE COACH — EASY VERSION
=========================

You do NOT need npm or .env files for this version.

1) CREATE YOUR SUPABASE CLOUD
   - Go to https://supabase.com/ and create a free project.
   - In the project, open SQL Editor.
   - Open supabase/schema.sql from this download and copy/paste ALL of it into SQL Editor.
   - Click Run.
   - In Authentication -> Sign In / Providers -> Email, for the easiest first setup, turn OFF "Confirm email". You can enable email verification later.
   - In Project Settings / API, copy the Project URL and the Publishable/anon key.

2) OPEN THE APP
   - You can test the app with a simple local web server, or upload index.html to a static host (for example, Netlify, GitHub Pages, Cloudflare Pages, etc.).
   - When the app opens, paste your Supabase Project URL + Publishable/anon key into the setup screen.

3) CREATE YOUR ACCOUNT
   - Use your Gmail (or any email) and a password.
   - Your JEE data is then stored against your own account in your own Supabase project.

4) CONNECT YOUR OWN AI
   Open Settings inside the app.
   - OpenRouter: endpoint https://openrouter.ai/api/v1/chat/completions
   - Vercel AI Gateway: endpoint https://ai-gateway.vercel.sh/v1/chat/completions
   - Custom: any OpenAI-compatible chat completions endpoint.
   Add your API key + model. The app stores the key only in your browser, not in Supabase.

5) WHAT IS REAL
   - Daily logs are cloud saved.
   - Schedule blocks are cloud saved.
   - Chat threads + messages are cloud saved.
   - Files are uploaded into a private user folder in Supabase Storage.
   - The coach context uses your actual profile, recent logs and upcoming schedule.
   - There are no dummy progress numbers.

IMPORTANT
---------
This app sends your AI request directly from the browser to the AI provider you choose. That means your AI provider sees your request and, depending on that provider/model, the attached information. Do not upload sensitive data you do not want the AI provider to process.

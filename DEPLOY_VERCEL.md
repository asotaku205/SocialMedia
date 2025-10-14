# Deploy Flutter Web App to Vercel

## 🚀 Quick Deploy

### Option 1: Deploy via Vercel Dashboard (Recommended)

1. **Go to [vercel.com](https://vercel.com)** and sign in with GitHub

2. **Click "Add New" → "Project"**

3. **Import your GitHub repository** (`asotaku205/SocialMedia`)

4. **Configure Build Settings:**
   - Framework Preset: **Other**
   - Build Command: `bash build.sh`
   - Output Directory: `build/web`
   - Install Command: (leave empty)

5. **Add Environment Variables** (if needed):
   - Go to Settings → Environment Variables
   - Add any Firebase or API keys

6. **Click "Deploy"** 🎉

### Option 2: Deploy via Vercel CLI

```bash
# Install Vercel CLI
npm i -g vercel

# Login to Vercel
vercel login

# Deploy
vercel --prod
```

## 🔧 Build Configuration

The `vercel.json` file contains:
- **buildCommand**: Builds Flutter web app in release mode
- **outputDirectory**: Points to `build/web`
- **routes**: Handles SPA routing for Flutter

## ⚙️ Environment Variables

If your app uses Firebase or other services, add these in Vercel:

```
FLUTTER_APP_NAME=YourAppName
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
```

## 📝 Notes

- **Build time**: First deploy takes 5-10 minutes (Flutter SDK download)
- **Subsequent deploys**: ~2-3 minutes (uses cache)
- **Web renderer**: Using CanvasKit for better performance
- **Domain**: Vercel provides free `.vercel.app` domain
- **Custom domain**: Can add in Project Settings

## 🐛 Troubleshooting

### Build fails?
1. Check build logs in Vercel dashboard
2. Ensure `pubspec.yaml` has all dependencies
3. Try local build first: `flutter build web --release`

### Routes not working?
- The `vercel.json` routes configuration handles SPA routing
- All routes redirect to `index.html`

### Assets not loading?
- Check `assets/` folder in `pubspec.yaml`
- Ensure paths in code use relative paths

## 🔗 Useful Links

- [Vercel Documentation](https://vercel.com/docs)
- [Flutter Web Documentation](https://docs.flutter.dev/platform-integration/web)
- [Your Vercel Dashboard](https://vercel.com/dashboard)

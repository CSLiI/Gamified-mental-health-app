# Deploying to Google Cloud Run

This guide walks you through deploying the Mental Health App backend to Google Cloud Run.

## Prerequisites

### 1. Google Cloud Account
- Create a free account at [cloud.google.com](https://cloud.google.com)
- New accounts get $300 in free credits

### 2. Install Google Cloud CLI
Download and install from: https://cloud.google.com/sdk/docs/install

After installation, restart your terminal and verify:
```bash
gcloud --version
```

---

## Step-by-Step Deployment

### Step 1: Authenticate with Google Cloud

```bash
gcloud auth login
```

This opens a browser window to sign in with your Google account.

### Step 2: Create a New Project (or use existing)

```bash
# Create new project
gcloud projects create mental-health-app-api --name="Mental Health App API"

# Set it as the active project
gcloud config set project mental-health-app-api
```

> **Note**: Project IDs must be globally unique. If `mental-health-app-api` is taken, 
> try adding numbers like `mental-health-app-api-123`

### Step 3: Enable Required APIs

```bash
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### Step 4: Deploy to Cloud Run

Navigate to your backend directory and run:

```bash
cd mental_health_app_backend

gcloud run deploy mental-health-api \
  --source . \
  --region asia-southeast1 \
  --allow-unauthenticated \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10 \
  --set-env-vars "DATABASE_URL=your_supabase_connection_string" \
  --set-env-vars "JWT_SECRET=your_jwt_secret" \
  --set-env-vars "BREVO_API_KEY=your_brevo_key"
```

> **Replace the environment variables** with your actual values from your `.env` file!

### Step 5: Get Your Service URL

After deployment, you'll see output like:
```
Service URL: https://mental-health-api-abc123-as.a.run.app
```

Copy this URL - this is your new backend API endpoint!

---

## Setting Environment Variables

You have two options:

### Option A: Command Line (during deploy)
Use `--set-env-vars` as shown above.

### Option B: Google Cloud Console (GUI)
1. Go to [Cloud Run Console](https://console.cloud.google.com/run)
2. Click on your service
3. Click "Edit & Deploy New Revision"
4. Go to "Variables & Secrets" tab
5. Add your environment variables

### Required Variables
| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Your Supabase PostgreSQL URL |
| `JWT_SECRET` | Secret key for JWT tokens |
| `BREVO_API_KEY` | Brevo email API key (if using) |

---

## Update Your Flutter App

After deploying, update your Flutter app to use the new backend:

**File: `lib/core/constants/api_constants.dart`**
```dart
class ApiConstants {
  // Replace with your Cloud Run URL
  static const String baseUrl = 'https://mental-health-api-abc123-as.a.run.app';
}
```

---

## Useful Commands

### View Logs
```bash
gcloud run logs read --service mental-health-api --region asia-southeast1
```

### Update Deployment
```bash
gcloud run deploy mental-health-api --source . --region asia-southeast1
```

### Check Service Status
```bash
gcloud run services describe mental-health-api --region asia-southeast1
```

---

## Choosing a Region

Pick a region close to your users for best performance:

| Region | Location |
|--------|----------|
| `asia-southeast1` | Singapore |
| `asia-east1` | Taiwan |
| `asia-northeast1` | Tokyo |
| `us-central1` | Iowa |
| `europe-west1` | Belgium |

---

## Cost

For small apps, Cloud Run is essentially **FREE**:

- **Free Tier (per month)**:
  - 180,000 vCPU-seconds
  - 360,000 GB-seconds of memory
  - 2 million requests

Your app will likely stay well within these limits!

---

## Troubleshooting

### Build Fails
- Check that all files in `requirements.txt` have valid versions
- Ensure `Dockerfile` is in the backend root directory

### App Crashes on Startup
- Check logs: `gcloud run logs read --service mental-health-api`
- Verify environment variables are set correctly

### Database Connection Issues
- Ensure `DATABASE_URL` is correct
- Check that Supabase allows connections from Cloud Run IPs

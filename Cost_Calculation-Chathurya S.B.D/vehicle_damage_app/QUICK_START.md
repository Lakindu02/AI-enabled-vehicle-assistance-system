# Quick Start Guide

## 🚀 Getting Started

### 1. Setup Environment Variables

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your configuration
nano .env  # or use your favorite editor
```

Update the values in `.env`:
```
API_URL=http://10.0.2.2:8000/assess
GEMINI_API_KEY=your_actual_gemini_api_key
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
# For Android emulator
flutter run

# For iOS simulator
flutter run

# For specific device
flutter devices
flutter run -d <device_id>
```

## 🔧 Configuration

### Platform-Specific API URLs

**Android Emulator:**
- Use `10.0.2.2` to access host machine's localhost
- Example: `http://10.0.2.2:8000/assess`

**iOS Simulator:**
- Use `localhost` or `127.0.0.1`
- Example: `http://localhost:8000/assess`

**Physical Device:**
- Use your computer's IP address
- Find IP: `ifconfig` (Mac/Linux) or `ipconfig` (Windows)
- Example: `http://192.168.1.100:8000/assess`

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `API_URL` | Backend API endpoint | `http://10.0.2.2:8000/assess` |
| `GEMINI_API_KEY` | Google Gemini API key (optional) | `AIzaSy...` |

## 📱 Using the App

1. **Add Images:**
   - Click "Camera" to take a photo
   - Click "Gallery" to select multiple images

2. **Enter Vehicle Details:**
   - Brand (e.g., Toyota)
   - Model (e.g., Corolla)
   - Year (e.g., 2016)

3. **Assess Damage:**
   - Click "Assess Damage" button
   - Wait for processing (shows "Processing N images...")
   - View results

## 🔍 Troubleshooting

### Common Issues

**1. "Could not load .env file" warning**
- This is normal if `.env` doesn't exist
- App will use default values
- Create `.env` to customize configuration

**2. "Connection refused" error**
- Check if backend API is running
- Verify API_URL is correct for your platform
- For Android emulator, use `10.0.2.2` not `localhost`

**3. "Failed to assess damage"**
- Ensure backend server is running
- Check network connectivity
- Verify API endpoint is accessible

### Backend Server

Make sure your backend API is running before using the app:

```bash
# Start your backend server
cd path/to/backend
python app.py  # or your server start command
```

The server should be accessible at the URL specified in `.env`.

## 🎯 Performance Features

### Background Processing
- All heavy operations run in background isolates
- UI remains smooth and responsive
- No frame drops during image processing

### Loading States
- Visual feedback during processing
- Shows number of images being processed
- Button disabled during operation

### Optimized Flow
1. Images selected → Fast, UI thread
2. Validation → Fast, UI thread
3. Processing → Background isolate
4. Results → UI thread update

## 🔒 Security Notes

- ✅ `.env` file is gitignored
- ✅ API keys stored securely
- ✅ No credentials in source code
- ⚠️ Never commit `.env` to version control

## 📊 Performance Monitoring

### Check Performance

```bash
# Run in profile mode
flutter run --profile

# View performance overlay
# Press 'P' in terminal while app is running
```

### Expected Performance
- Smooth 60 FPS during operation
- No "Skipped frames" warnings
- Responsive UI during image processing
- Fast API response times

## 🛠 Development

### Hot Reload

While app is running, press:
- `r` - Hot reload (fast)
- `R` - Hot restart (full restart)
- `q` - Quit app

### Debugging

```bash
# Run with debugging
flutter run --debug

# View logs
flutter logs

# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## 📝 Next Steps

1. ✅ Setup environment variables
2. ✅ Install dependencies
3. ✅ Start backend server
4. ✅ Run the app
5. ✅ Test with sample images
6. ✅ Review performance

For detailed information, see [PERFORMANCE_IMPROVEMENTS.md](PERFORMANCE_IMPROVEMENTS.md)

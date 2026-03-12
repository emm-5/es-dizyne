# ES Dizyne — Professional Mobile Design Suite

A full-featured, offline-first graphic design app for Android inspired by Adobe Photoshop and Affinity Designer.

---

## 🚀 Quick Start (GitHub Actions Build — No PC Needed)

### Step 1: Create a GitHub Account
Go to [github.com](https://github.com) and create a free account if you don't have one.

### Step 2: Create a New Repository
1. Click the **+** icon → **New repository**
2. Name it: `es-dizyne`
3. Set to **Public**
4. Click **Create repository**

### Step 3: Upload the Project Files
You have two options:

**Option A — GitHub Web Upload (easiest for Android)**
1. Open your repository on GitHub
2. Click **Add file** → **Upload files**
3. Upload the ZIP file contents (all folders and files)
4. Click **Commit changes**

**Option B — Using Git (in Userland/Termux)**
```bash
git init
git add .
git commit -m "Initial ES Dizyne project"
git remote add origin https://github.com/YOUR_USERNAME/es-dizyne.git
git push -u origin main
```

### Step 4: Watch the Build
1. Go to your repository on GitHub
2. Click the **Actions** tab
3. You'll see **Build ES Dizyne APK** running
4. Wait 5–10 minutes for it to complete

### Step 5: Download Your APK
1. Click on the completed workflow run
2. Scroll down to **Artifacts**
3. Download **ESDizyne-Universal-APK**
4. Install it on your Android phone

> ⚠️ Enable **"Install from unknown sources"** in Android settings before installing.

---

## 📱 Features

### Canvas & Engine
- Infinite canvas with zoom (0.1% – 6400%)
- Multi-touch pan & zoom
- GPU-accelerated rendering
- DPI system (72, 96, 150, 300, 600 dpi)
- Canvas resize & upscale
- Rulers & grid system

### Layer System (Photoshop-level)
- Pixel, Vector, Text, Adjustment, Group, Smart Object layers
- 27 blend modes (Normal, Multiply, Screen, Vivid Light, Hard Mix, Difference...)
- Layer masks (pixel, vector, luminosity)
- Clipping masks
- Layer effects (Drop Shadow, Inner Glow, Bevel & Emboss, Stroke...)
- Layer opacity & fill separately

### Brush Engine (Photoshop-grade)
- Pressure, tilt & velocity sensitivity
- Brush categories: Basic, Inking, Painting, Watercolour, Oil, Charcoal, Airbrush, Spray
- Brush customization: size, hardness, spacing, scatter, flow, opacity
- Symmetry painting (vertical, horizontal, radial, mandala)
- Brush stabilizer

### Tools
- Move, Transform, Warp
- Selection: Marquee, Lasso, Magic Wand, Quick Select, Select Subject (AI)
- Crop, Clone, Healing, Patch
- Text tool with full typography
- Pen tool (bezier curves)
- Shape tools: Rectangle, Ellipse, Polygon, Star, Arrow, Line, Custom

### Shape Builder
- All standard shapes + advanced
- Boolean operations (Add, Subtract, Intersect, Divide, XOR)
- Corner rounding (live, per-node)
- Logo builder workspace
- Full snapping system

### Text System
- Artistic text, frame text, path text
- Full OpenType support
- Variable fonts
- Custom font import (TTF, OTF, ZIP packs — mass import)
- Dynamic text (date, time, filename, artboard number)
- Highlight-to-edit like Photoshop
- Gradient text

### Color System
- RGB mode (screen/mobile)
- CMYK mode (print)
- LAB & HSL
- Color wheel + sliders + HEX input
- **Custom color palettes** (saved per project + globally)
- Gradient editor (linear, radial, conical, elliptical, mesh)
- Pattern fills
- Eyedropper tool

### Artboard System
- Multiple artboards per project
- Preset sizes (iPhone, iPad, Android, Web, A4, Social Media, etc.)
- Mass export all artboards
- Per-artboard export settings

### File Support

| Open & Edit | Save (Editable) | Export |
|---|---|---|
| .esdz (native) | .esdz | .png |
| .psd | .psd | .jpg |
| .plp | .plp | .tiff |
| .afdesign | .afdesign | .svg |
| .afphoto | .afphoto | .webp |
| .pdf | .pdf | .pdf |
| .eps | .eps | .eps |
| .svg | .svg | .bmp |
| .png, .jpg, .tiff | | .gif |
| .webp, .bmp, .gif | | .avif |
| RAW (CR2, CR3, NEF, ARW, RAF, ORF, RW2, DNG) | | .heic |

### AI Features (Offline)
- Background remover (U2Net model)
- Select Subject (DeepLab v3 mobile)
- Refine edge / hair detection

### Export Options
- DPI override per export
- Scale multiplier (1x, 2x, 3x, 4x)
- Color profile embed/strip
- Filename templates ({name}, {artboard}, {date}, {dpi})
- Mass export all artboards
- ZIP all exports automatically

---

## 🔧 Project Structure

```
es_dizyne/
├── .github/workflows/         # GitHub Actions — auto-builds APK
├── android/                   # Android config
├── assets/                    # Brushes, fonts, shapes, ML models
├── lib/
│   ├── core/engine/           # Canvas rendering engine
│   ├── core/formats/          # PSD, PLP, Affinity, EPS parsers
│   ├── models/                # All data models
│   ├── screens/               # Home, Editor, Splash
│   ├── widgets/               # All UI panels
│   ├── utils/                 # Project manager, export manager
│   └── theme/                 # Dark/light theme
└── pubspec.yaml               # Dependencies
```

---

## 📋 Requirements
- Android 8.0 (API 26) or higher
- Android 14 fully supported
- Tablet and phone optimized
- Stylus pressure support

---

## 🎨 About ES Dizyne

ES Dizyne is built to be the first professional-grade Photoshop/Affinity-level design app on Android. It works fully offline, supports industry-standard file formats, and is designed for mobile-first workflows.

**App Name:** ES Dizyne  
**Native Format:** `.esdz` (lightweight, compressed, fully editable)  
**Framework:** Flutter (Dart)  
**Min Android:** 8.0 (API 26)  

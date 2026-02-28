# Backend Version Check Endpoint

**Date:** February 28, 2026
**Purpose:** API endpoint untuk version checking

---

## 📋 Required Endpoint

### GET /api/app/version

**Purpose:** Return latest app version information

**Authentication:** Not required (public endpoint)

**Response Format:**

```json
{
  "success": true,
  "data": {
    "version": "1.0.1",
    "min_version": "1.0.0",
    "force_update": false,
    "update_url": "https://play.google.com/store/apps/details?id=com.example.lms_frontend",
    "release_notes": "- Bug fixes\n- Performance improvements\n- New features"
  }
}
```

---

## 📊 Response Fields

### version (required)
- **Type:** String
- **Description:** Latest available version
- **Format:** Semantic versioning (e.g., "1.0.1")
- **Example:** "1.0.1"

### min_version (optional)
- **Type:** String
- **Description:** Minimum required version to use the app
- **Format:** Semantic versioning
- **Example:** "1.0.0"
- **Note:** If user's version < min_version, force update

### force_update (optional)
- **Type:** Boolean
- **Description:** Force user to update
- **Default:** false
- **Example:** true

### update_url (optional)
- **Type:** String
- **Description:** URL to download update
- **Default:** Play Store URL (auto-generated)
- **Example:** "https://play.google.com/store/apps/details?id=com.example.lms_frontend"

### release_notes (optional)
- **Type:** String
- **Description:** What's new in this version
- **Format:** Plain text or markdown
- **Example:** "- Bug fixes\n- New features"

---

## 🎯 Version Comparison Logic

### Update Available
```
Current: 1.0.0
Latest: 1.0.1
Result: Update available (optional)
```

### Force Update
```
Current: 1.0.0
Min Version: 1.0.1
Result: Force update required
```

### No Update
```
Current: 1.0.1
Latest: 1.0.1
Result: No update needed
```

---

## 💻 Laravel Implementation Example

### Migration

```php
// database/migrations/xxxx_create_app_versions_table.php
Schema::create('app_versions', function (Blueprint $table) {
    $table->id();
    $table->string('platform'); // 'android' or 'ios'
    $table->string('version'); // Latest version
    $table->string('min_version')->nullable(); // Minimum required
    $table->boolean('force_update')->default(false);
    $table->string('update_url')->nullable();
    $table->text('release_notes')->nullable();
    $table->boolean('is_active')->default(true);
    $table->timestamps();
});
```

### Model

```php
// app/Models/AppVersion.php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppVersion extends Model
{
    protected $fillable = [
        'platform',
        'version',
        'min_version',
        'force_update',
        'update_url',
        'release_notes',
        'is_active',
    ];

    protected $casts = [
        'force_update' => 'boolean',
        'is_active' => 'boolean',
    ];

    public static function getLatest($platform = 'android')
    {
        return self::where('platform', $platform)
            ->where('is_active', true)
            ->latest()
            ->first();
    }
}
```

### Controller

```php
// app/Http/Controllers/Api/AppVersionController.php
namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppVersion;
use Illuminate\Http\Request;

class AppVersionController extends Controller
{
    public function check(Request $request)
    {
        $platform = $request->input('platform', 'android');

        $version = AppVersion::getLatest($platform);

        if (!$version) {
            return response()->json([
                'success' => false,
                'message' => 'Version information not available',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'version' => $version->version,
                'min_version' => $version->min_version,
                'force_update' => $version->force_update,
                'update_url' => $version->update_url,
                'release_notes' => $version->release_notes,
            ],
        ]);
    }
}
```

### Route

```php
// routes/api.php
Route::get('/app/version', [AppVersionController::class, 'check']);
```

### Seeder (Optional)

```php
// database/seeders/AppVersionSeeder.php
namespace Database\Seeders;

use App\Models\AppVersion;
use Illuminate\Database\Seeder;

class AppVersionSeeder extends Seeder
{
    public function run()
    {
        AppVersion::create([
            'platform' => 'android',
            'version' => '1.0.0',
            'min_version' => '1.0.0',
            'force_update' => false,
            'update_url' => 'https://play.google.com/store/apps/details?id=com.example.lms_frontend',
            'release_notes' => 'Initial release',
            'is_active' => true,
        ]);
    }
}
```

---

## 🧪 Testing

### Test Request

```bash
curl http://192.168.101.82:8000/api/app/version
```

### Expected Response

```json
{
  "success": true,
  "data": {
    "version": "1.0.0",
    "min_version": "1.0.0",
    "force_update": false,
    "update_url": "https://play.google.com/store/apps/details?id=com.example.lms_frontend",
    "release_notes": "Initial release"
  }
}
```

---

## 📝 Usage Scenarios

### Scenario 1: Optional Update
```json
{
  "version": "1.0.1",
  "min_version": "1.0.0",
  "force_update": false
}
```
**Result:** Show update dialog with "Nanti" button

### Scenario 2: Force Update
```json
{
  "version": "1.0.2",
  "min_version": "1.0.2",
  "force_update": true
}
```
**Result:** Show update dialog without "Nanti" button, block app usage

### Scenario 3: No Update
```json
{
  "version": "1.0.0",
  "min_version": "1.0.0"
}
```
**Result:** No dialog shown, app continues normally

---

## 🔒 Security Notes

1. **Public Endpoint:** No authentication required
2. **Rate Limiting:** Consider adding rate limiting
3. **Caching:** Cache response for 1 hour to reduce load
4. **Validation:** Validate version format on backend

---

## 📊 Admin Panel (Optional)

Create admin interface to manage versions:

```php
// Admin can:
- Create new version entry
- Set min_version for force update
- Toggle force_update flag
- Update release notes
- Set update URL
- Activate/deactivate versions
```

---

## 🚀 Deployment Checklist

- [ ] Create migration and run
- [ ] Create model
- [ ] Create controller
- [ ] Add route
- [ ] Seed initial version
- [ ] Test endpoint
- [ ] Add to API documentation
- [ ] Configure rate limiting (optional)
- [ ] Setup admin panel (optional)

---

**Last Updated:** February 28, 2026
**Status:** Ready for backend implementation


# Mandi — Production Deployment & Release Guide (Phase 8)

## 1. Environment Configuration

### Dart Define Build Variables
Never hardcode production API credentials in the APK. Build with `--dart-define`:

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=https://<your-project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<your-production-anon-key>
```

## 2. Android Keystore & Application Signing
1. Generate release keystore:
   ```bash
   keytool -genkey -v -keystore android/app/mandi-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mandi
   ```
2. Configure `android/key.properties`:
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=mandi
   storeFile=mandi-release-key.jks
   ```
3. Update `android/app/build.gradle.kts` to reference `signingConfigs.getByName("release")`.

## 3. ProGuard & R8 Optimization Rules
Keep rules configured in `android/app/proguard-rules.pro`:
```proguard
-keep class com.mandi.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn okhttp3.**
-dontwarn io.flutter.**
```

## 4. Production Database Deployment Checklist
- [x] Run `supabase/schema.sql` on the Supabase PostgreSQL production instance.
- [x] Verify Row Level Security is active on all 37 tables (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`).
- [x] Confirm public anon key has no elevated permissions.
- [x] Set up Supabase Storage bucket `voice_notes` with private access and signed URLs.
- [x] Verify automated daily backups are configured in Supabase Project Settings.

## 5. Rollback Strategy
If a deployment defect is detected in production:
1. Revert to the previous App Bundle version on Google Play Console using staged rollouts.
2. If database schema rollback is required, use timestamped migration down-scripts (`supabase/migrations/`).

from pathlib import Path


manifest_path = Path("android/app/src/main/AndroidManifest.xml")
manifest = manifest_path.read_text(encoding="utf-8")

permissions = (
    '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />\n'
    '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />\n'
    '    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />\n'
    '    <uses-permission android:name="android.permission.WAKE_LOCK" />\n'
)

if "android.permission.POST_NOTIFICATIONS" not in manifest:
    manifest = manifest.replace("<application", permissions + "    <application", 1)

manifest = manifest.replace(
    'android:label="manarat_al_indibat"',
    'android:label="منارة الانضباط"',
)

manifest_path.write_text(manifest, encoding="utf-8")

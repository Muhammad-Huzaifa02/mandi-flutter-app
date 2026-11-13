import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Storage client for Mandi Voice Notes & Audio Memos.
/// Manages upload to secure storage buckets and generation of signed time-limited playback URLs.
class VoiceNotesStorageService {
  static const String bucketName = 'voice_notes';
  static final SupabaseClient _client = Supabase.instance.client;

  /// Uploads a local voice memo file to Supabase Storage.
  /// Returns the storage object path on success (e.g., 'shop_123/notes/audio_uuid.m4a').
  static Future<String?> uploadVoiceNote({
    required String shopId,
    required String filePath,
    required String noteId,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final dotIndex = filePath.lastIndexOf('.');
      final extension = dotIndex != -1 ? filePath.substring(dotIndex) : '.m4a';
      final storagePath = '$shopId/$noteId$extension';

      await _client.storage.from(bucketName).upload(
            storagePath,
            file,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4',
              upsert: true,
            ),
          );

      return storagePath;
    } catch (_) {
      return null;
    }
  }

  /// Generates a signed, secure playback URL valid for [expiresInSeconds] (default: 2 hours).
  static Future<String?> getSignedPlaybackUrl({
    required String storagePath,
    int expiresInSeconds = 7200,
  }) async {
    try {
      final signedUrl = await _client.storage.from(bucketName).createSignedUrl(
            storagePath,
            expiresInSeconds,
          );
      return signedUrl;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a voice note from Supabase Storage.
  static Future<bool> deleteVoiceNote(String storagePath) async {
    try {
      await _client.storage.from(bucketName).remove([storagePath]);
      return true;
    } catch (_) {
      return false;
    }
  }
}

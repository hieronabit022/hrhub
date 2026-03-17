class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://knaeimmbgkhunkqbkain.supabase.co',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_X83mOG5r_nls2eQYQTwlbA_KJKdAMs0',
  );

  static const restBaseUrl = '$url/rest/v1';
  static const storageBaseUrl = '$url/storage/v1';
  static const requestAttachmentBucket = String.fromEnvironment(
    'SUPABASE_REQUEST_BUCKET',
    defaultValue: 'request-attachments',
  );

  static Map<String, String> get headers => {
        'apikey': anonKey,
        'Content-Type': 'application/json',
      };
}

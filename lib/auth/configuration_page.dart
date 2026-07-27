import 'package:flutter/material.dart';

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Perfect', style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 12),
                      Text(
                        'برای حفظ حریم خصوصی، اطلاعات اتصال Supabase در کد ذخیره نشده‌اند.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 18),
                      const Text('پس از اجرای migration موجود در پوشهٔ supabase، اپ را با این دو مقدار اجرا کن:'),
                      const SizedBox(height: 12),
                      const SelectableText(
                        'flutter run -d chrome '
                        '--dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co '
                        '--dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY',
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(height: 18),
                      const Text('از publishable/anon key استفاده کن؛ service_role key هرگز نباید در اپ قرار بگیرد.'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

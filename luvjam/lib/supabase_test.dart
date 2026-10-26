
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> testSupabaseConnection() async {
  try {
    final products = await Supabase.instance.client
        .from('products')
        .select('id, name, price');

    print('SUPABASE CONNECTION SUCCESS!');
    print('Products found: ${products.length}');
    print(products);
  } catch (e) {
    print('SUPABASE CONNECTION FAILED!');
    print(e);
  }
}

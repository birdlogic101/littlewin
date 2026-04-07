import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = 'https://jibfozleqgpfutcwgbrw.supabase.co';
  final anonKey = 'sb_publishable_E6_tX3wXWj2W7sG1L4djKw_0HHLv8u_';
  
  print('Calling get_explore_feed RPC...');
  final res = await http.post(
    Uri.parse('$url/rest/v1/rpc/get_explore_feed'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'p_user_id': null,
      'p_limit': 5,
      'p_offset': 0,
    }),
  );

  print('Status code: ${res.statusCode}');
  if (res.statusCode == 200) {
    final list = jsonDecode(res.body) as List;
    print('Results: ${list.length}');
    for (var i = 0; i < list.length; i++) {
        print('\n--- Run $i ---');
        print('Title: ${list[i]['challenge_title']}');
        print('Description: ${list[i]['challenge_description']}');
    }
  } else {
    print('Error: ${res.body}');
  }
}

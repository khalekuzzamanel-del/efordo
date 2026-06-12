import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

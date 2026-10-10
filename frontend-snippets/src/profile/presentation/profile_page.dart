library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kiro/app/providers/locale_provider.dart';
import 'package:kiro/app/providers/marketplace_trades_count_provider.dart';
import 'package:kiro/app/providers/my_cards_provider.dart';
import 'package:kiro/app/providers/rarities_provider.dart';
import 'package:kiro/app/providers/support_requests_responded_count_provider.dart';
import 'package:kiro/app/providers/user_provider.dart';
import 'package:kiro/shared/widgets/coin_balance_widget.dart';
import 'package:kiro/shared/widgets/gem_balance_widget.dart';

import '../../../app/constants/app_dimensions.dart';
import '../../../app/providers/collections_provider.dart';
import '../../../app/router/app_constants_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/api_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/enums/Card_details_source.dart';
import '../../../shared/models/collection_card_model.dart';
import '../../../shared/widgets/animated_clickable.dart';
import '../../../shared/widgets/game_bottom_navigation_bar.dart';
import '../../../shared/widgets/kiro_frame.dart';

part 'parts/profile_controller.dart';
part 'parts/profile_view.dart';
part 'parts/profile_widgets.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    initProfile();
  }

  @override
  Widget build(BuildContext context) {
    return buildView();
  }
}
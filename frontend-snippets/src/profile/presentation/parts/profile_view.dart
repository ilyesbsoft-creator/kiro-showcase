part of '../profile_page.dart';

extension ProfileView on _ProfilePageState {
  Widget buildView() {
    final size = MediaQuery.of(context).size;
    final tr = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // خلفية متدرجة ملائمة للثيم الداكن الأرجواني
        buildBackground(size),

        SafeArea(
          child: isLoading
              ? const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          )
              : Column(
            children: [
              buildHeader(size, tr),
              buildProfileHeroSection(size, tr),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.width(size, 16),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: AppDimensions.height(size, 16)),
                      buildMainCardCard(size, tr),
                      SizedBox(height: AppDimensions.height(size, 16)),
                      buildStatisticsGrid(size, tr),
                      // SizedBox(height: AppDimensions.height(size, 16)),
                      // buildAchievementsAndLevelRow(size, tr),
                      SizedBox(height: AppDimensions.height(size, 16)),
                      buildRecentCardsSection(size, tr),
                      SizedBox(height: AppDimensions.height(size, 16)),
                      buildChangeAvatarButton(size, tr),
                      SizedBox(height: AppDimensions.height(size, 16)),
                      buildAccountInfoGrid(size, tr),
                      SizedBox(height: AppDimensions.height(size, 30)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
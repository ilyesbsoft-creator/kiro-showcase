part of '../profile_page.dart';

extension ProfileController on _ProfilePageState {

  Future<void> initProfile() async {

    setState(() {
      isLoading = true;
    });

    try {
      // TODO:
      // تحميل بيانات البروفيل
    } catch (e) {
      debugPrint("Profile Init Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> refreshProfile() async {
    await initProfile();
  }
}
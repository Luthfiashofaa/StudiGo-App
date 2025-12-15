import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/supabase_service.dart';
import '../../../data/services/auth_persistence_service.dart';
import '../../bindings/auth/login_binding.dart';
import '../../views/auth/login_view.dart';

class ProfileController extends GetxController {
  final emailController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dobController = TextEditingController();
  final phoneController = TextEditingController();

  DateTime? birthDate;
  String countryCode = 'ID';
  String countryDialCode = '+62';
  String? avatarPath;
  String? avatarUrl;
  String? _profileId;

  // Lazy getter to avoid null during initialization
  late final SupabaseService _supabase = Get.find<SupabaseService>();

  final RxBool isSaving = false.obs;
  final RxBool isLoadingProfile = false.obs;
  final RxBool hasChanges = false.obs;

  // store original loaded values to detect changes
  final Map<String, dynamic> _original = {};

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    // Delay reactive updates to next frame to avoid "setState during build" error
    Future.delayed(Duration.zero, () {
      _attachListeners();
      fetchProfile();
    });
  }

  @override
  void onClose() {
    _removeListeners();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  void _attachListeners() {
    emailController.addListener(_checkChanges);
    firstNameController.addListener(_checkChanges);
    lastNameController.addListener(_checkChanges);
    dobController.addListener(_checkChanges);
    phoneController.addListener(_checkChanges);
  }

  void _removeListeners() {
    emailController.removeListener(_checkChanges);
    firstNameController.removeListener(_checkChanges);
    lastNameController.removeListener(_checkChanges);
    dobController.removeListener(_checkChanges);
    phoneController.removeListener(_checkChanges);
  }

  void _checkChanges() {
    final email = emailController.text.trim();
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();
    final phone = phoneController.text.trim();
    final dob = birthDate?.toIso8601String() ?? '';
    final countryC = countryCode;
    final countryD = countryDialCode;

    bool changed = false;

    if ((_original['email'] ?? '') != email) changed = true;
    if ((_original['first_name'] ?? '') != first) changed = true;
    if ((_original['last_name'] ?? '') != last) changed = true;
    if ((_original['phone'] ?? '') != phone) changed = true;
    if ((_original['dob'] ?? '') != dob) changed = true;
    if ((_original['country_code'] ?? '') != countryC) changed = true;
    if ((_original['country_dial_code'] ?? '') != countryD) changed = true;

    // avatarPath indicates a new local image that hasn't been uploaded yet
    if (avatarPath != null) changed = true;

    hasChanges.value = changed;
  }

  void setBirthDate(DateTime date) {
    birthDate = date;
    dobController.text = _formatDate(date);
    update();
    _checkChanges();
  }

  void setCountry(String code, String dialCode) {
    countryCode = code;
    countryDialCode = dialCode;
    update();
    _checkChanges();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} - ${d.month.toString().padLeft(2, '0')} - ${d.year}';

  Future<void> pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          Get.snackbar(
            'Permission denied',
            'Camera permission is required to take photos',
          );
          return;
        }
      } else {
        if (Platform.isAndroid) {
          final statuses = await [
            Permission.photos,
            Permission.storage,
          ].request();
          final granted = statuses.values.any((s) => s.isGranted);
          if (!granted) {
            Get.snackbar(
              'Permission denied',
              'Storage permission is required to select photos',
            );
            return;
          }
        } else if (Platform.isIOS) {
          final status = await Permission.photos.request();
          if (!status.isGranted) {
            Get.snackbar(
              'Permission denied',
              'Photos permission is required to select photos',
            );
            return;
          }
        }
      }

      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        avatarPath = picked.path;
        update();
        _checkChanges();
      }
    } catch (e) {
      Get.snackbar('Error', 'Unable to pick image: ${e.toString()}');
    }
  }

  Future<void> fetchProfile() async {
    final user = _supabase.currentUser;
    if (user == null) return;

    isLoadingProfile.value = true;
    try {
      // Primary: try fetching from `users` table by user ID (sesuai gambar)
      final usersRes = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .limit(1);
      if (usersRes != null && usersRes is List && usersRes.isNotEmpty) {
        final u = Map<String, dynamic>.from(usersRes[0]);
        _profileId = u['id']?.toString();
        emailController.text = u['email']?.toString() ?? user.email ?? '';

        // Parse `name` field (jika ada) atau gunakan `firstname`/`lastname` terpisah
        String firstName = '';
        String lastName = '';

        final nameFull = u['name']?.toString() ?? '';
        if (nameFull.isNotEmpty) {
          final parts = nameFull.split(' ');
          firstName = parts.isNotEmpty ? parts[0] : '';
          lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        } else {
          firstName = u['firstname']?.toString() ?? '';
          lastName = u['lastname']?.toString() ?? '';
        }

        firstNameController.text = firstName;
        lastNameController.text = lastName;
        phoneController.text = u['phone_number']?.toString() ?? '';
        avatarUrl = u['photo_url']?.toString() ?? '';

        final dobRaw = u['birthdate']?.toString();
        if (dobRaw != null && dobRaw.isNotEmpty) {
          final dt = DateTime.tryParse(dobRaw);
          if (dt != null) setBirthDate(dt);
          _original['dob'] = dt?.toIso8601String() ?? '';
        }

        _original['email'] = emailController.text.trim();
        _original['first_name'] = firstNameController.text.trim();
        _original['last_name'] = lastNameController.text.trim();
        _original['phone'] = phoneController.text.trim();
        _original['country_code'] = countryCode;
        _original['country_dial_code'] = countryDialCode;
        _original['avatar_url'] = avatarUrl ?? '';

        hasChanges.value = false;
        update();
        return;
      }

      // Fallback: fetch dari `users` table by email jika id tidak cocok
      final String userEmail = user.email ?? '';
      if (userEmail.isNotEmpty) {
        final usersResEmail = await _supabase
            .from('users')
            .select()
            .eq('email', userEmail)
            .limit(1);
        if (usersResEmail != null &&
            usersResEmail is List &&
            usersResEmail.isNotEmpty) {
          final u = Map<String, dynamic>.from(usersResEmail[0]);
          _profileId = u['id']?.toString();
          emailController.text = u['email']?.toString() ?? user.email ?? '';

          String firstName = '';
          String lastName = '';
          final nameFull = u['name']?.toString() ?? '';
          if (nameFull.isNotEmpty) {
            final parts = nameFull.split(' ');
            firstName = parts.isNotEmpty ? parts[0] : '';
            lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          } else {
            firstName = u['firstname']?.toString() ?? '';
            lastName = u['lastname']?.toString() ?? '';
          }

          firstNameController.text = firstName;
          lastNameController.text = lastName;
          phoneController.text = u['phone_number']?.toString() ?? '';
          avatarUrl = u['photo_url']?.toString() ?? '';

          final dobRaw = u['birthdate']?.toString();
          if (dobRaw != null && dobRaw.isNotEmpty) {
            final dt = DateTime.tryParse(dobRaw);
            if (dt != null) setBirthDate(dt);
            _original['dob'] = dt?.toIso8601String() ?? '';
          }

          _original['email'] = emailController.text.trim();
          _original['first_name'] = firstNameController.text.trim();
          _original['last_name'] = lastNameController.text.trim();
          _original['phone'] = phoneController.text.trim();
          _original['country_code'] = countryCode;
          _original['country_dial_code'] = countryDialCode;
          _original['avatar_url'] = avatarUrl ?? '';

          hasChanges.value = false;
          update();
          return;
        }
      }

      // Final fallback: gunakan auth metadata saja
      final meta = user.userMetadata ?? <String, dynamic>{};
      emailController.text = user.email ?? '';
      firstNameController.text =
          (meta['firstname'] ?? meta['first_name'] ?? meta['given_name'] ?? '')
              ?.toString() ??
          '';
      lastNameController.text =
          (meta['lastname'] ?? meta['last_name'] ?? meta['family_name'] ?? '')
              ?.toString() ??
          '';
      phoneController.text =
          (meta['phone_number'] ?? meta['phone'] ?? '')?.toString() ?? '';
      avatarUrl =
          (meta['photo_url'] ?? meta['photoUrl'] ?? '')?.toString() ?? '';

      final dobRawMeta =
          (meta['birthdate'] ?? meta['dob'] ?? meta['date_of_birth'])
              ?.toString();
      if (dobRawMeta != null && dobRawMeta.isNotEmpty) {
        final dt = DateTime.tryParse(dobRawMeta);
        if (dt != null) setBirthDate(dt);
        _original['dob'] = dt?.toIso8601String() ?? '';
      }

      _original['email'] = emailController.text.trim();
      _original['first_name'] = firstNameController.text.trim();
      _original['last_name'] = lastNameController.text.trim();
      _original['phone'] = phoneController.text.trim();
      _original['country_code'] = countryCode;
      _original['country_dial_code'] = countryDialCode;
      _original['avatar_url'] = avatarUrl ?? '';

      hasChanges.value = false;
      update();
    } catch (e) {
      debugPrint('fetchProfile error: $e');
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<String?> _uploadAvatarIfNeeded() async {
    if (avatarPath == null) {
      debugPrint(
        '_uploadAvatarIfNeeded: avatarPath is null, returning existing avatarUrl = $avatarUrl',
      );
      return avatarUrl;
    }

    final user = _supabase.currentUser;
    if (user == null) {
      debugPrint('_uploadAvatarIfNeeded: user is null, cannot upload');
      Get.snackbar('Error', 'User not logged in');
      return null;
    }

    try {
      final file = File(avatarPath!);
      final exists = await file.exists();
      debugPrint(
        '_uploadAvatarIfNeeded: avatarPath = $avatarPath, exists = $exists',
      );

      if (!exists) {
        debugPrint('_uploadAvatarIfNeeded: File does not exist at $avatarPath');
        Get.snackbar('Error', 'Image file not found');
        return avatarUrl;
      }

      // Get file extension and detect content type
      final ext = avatarPath!.split('.').last.toLowerCase();
      String contentType = 'image/jpeg'; // default
      switch (ext) {
        case 'png':
          contentType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
      }

      // Use unique filename with timestamp to avoid caching issues
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${user.id}/$timestamp.$ext';
      debugPrint(
        '_uploadAvatarIfNeeded: Uploading to bucket=avatars, path=$path with contentType=$contentType',
      );

      // First, try to remove old avatar if exists
      try {
        final existingFiles = await _supabase.storage
            .from('avatars')
            .list(path: user.id);
        for (final file in existingFiles) {
          await _supabase.storage.from('avatars').remove([
            '${user.id}/${file.name}',
          ]);
        }
      } catch (e) {
        debugPrint('Could not remove old avatars: $e');
      }

      // Upload with proper content type
      final uploadPath = await _supabase.storage
          .from('avatars')
          .upload(
            path,
            file,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      // Get public URL with cache-busting parameter
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      final urlWithCacheBust = '$publicUrl?t=$timestamp';

      debugPrint(
        '_uploadAvatarIfNeeded: Upload successful, publicUrl = $urlWithCacheBust',
      );

      avatarUrl = urlWithCacheBust;
      _original['avatar_url'] = avatarUrl ?? '';
      avatarPath = null; // Clear the path after upload
      return avatarUrl;
    } on StorageException catch (e) {
      debugPrint('_uploadAvatarIfNeeded: StorageException - ${e.message}');
      Get.snackbar(
        'Upload Failed',
        'Storage error: ${e.message}. Please check if avatars bucket exists and has proper permissions.',
        duration: const Duration(seconds: 5),
      );
      return avatarUrl;
    } catch (e) {
      debugPrint('_uploadAvatarIfNeeded: Error - $e');
      Get.snackbar(
        'Upload Failed',
        'Failed to upload avatar: ${e.toString()}',
        duration: const Duration(seconds: 4),
      );
      return avatarUrl;
    }
  }

  Future<void> saveProfile() async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('User belum login.');

    isSaving.value = true;
    try {
      debugPrint('saveProfile: Starting save for user ${user.id}');
      debugPrint('saveProfile: avatarPath = $avatarPath');

      final uploadedAvatar = await _uploadAvatarIfNeeded();
      debugPrint('saveProfile: uploadedAvatar = $uploadedAvatar');

      // Gabung firstName + lastName menjadi `name` untuk tabel `users`
      final fullName =
          '${firstNameController.text.trim()} ${lastNameController.text.trim()}'
              .trim();

      final payload = {
        'email': emailController.text.trim(),
        'name': fullName,
        'firstname': firstNameController.text.trim(),
        'lastname': lastNameController.text.trim(),
        'birthdate': birthDate?.toIso8601String(),
        'phone_number': phoneController.text.trim(),
        'photo_url': uploadedAvatar,
        'updated_at': DateTime.now().toIso8601String(),
      }..removeWhere((k, v) => v == null);

      debugPrint('saveProfile: payload = $payload');
      debugPrint('saveProfile: _profileId = $_profileId');

      if (_profileId != null) {
        final id = _profileId!;
        debugPrint('saveProfile: Updating existing user with id=$id');
        await _supabase.from('users').update(payload).eq('id', id);
        _original['email'] = payload['email'] ?? _original['email'];
        _original['first_name'] =
            payload['firstname'] ?? _original['first_name'];
        _original['last_name'] = payload['lastname'] ?? _original['last_name'];
        _original['phone'] = payload['phone_number'] ?? _original['phone'];
        _original['dob'] = payload['birthdate'] ?? _original['dob'];
        _original['country_code'] =
            payload['country_code'] ?? _original['country_code'];
        _original['country_dial_code'] =
            payload['country_dial_code'] ?? _original['country_dial_code'];
        _original['avatar_url'] = uploadedAvatar ?? _original['avatar_url'];
      } else {
        debugPrint('saveProfile: Inserting new user with id=${user.id}');
        payload['id'] = user.id;
        final res = await _supabase.from('users').insert(payload);
        debugPrint('saveProfile: Insert response = $res');
        if (res != null && res is List && res.isNotEmpty) {
          _profileId = res[0]['id']?.toString();
          _original['email'] = payload['email'] ?? '';
          _original['first_name'] = payload['firstname'] ?? '';
          _original['last_name'] = payload['lastname'] ?? '';
          _original['phone'] = payload['phone_number'] ?? '';
          _original['dob'] = payload['birthdate'] ?? '';
          _original['country_code'] = payload['country_code'] ?? '';
          _original['country_dial_code'] = payload['country_dial_code'] ?? '';
          _original['avatar_url'] = uploadedAvatar ?? '';
        }
      }

      Get.snackbar(
        'Sukses',
        'Profil disimpan',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on PostgrestException catch (e) {
      debugPrint('saveProfile: PostgrestException - ${e.message}');
      Get.snackbar('Gagal', e.message ?? e.toString());
    } catch (e) {
      debugPrint('saveProfile: Error - $e');
      Get.snackbar('Gagal', e.toString());
    } finally {
      isSaving.value = false;
      hasChanges.value = false;
    }
  }

  Future<void> deleteProfile() async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('User belum login.');

    if (_profileId == null) return;
    try {
      final id = _profileId!;
      await _supabase.from('users').delete().eq('id', id);
      _profileId = null;
      _original.clear();
      hasChanges.value = false;
      update();
    } catch (e) {
      Get.snackbar('Gagal', 'Tidak dapat menghapus profil: $e');
    }
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0B61FF),
            ).copyWith(primary: const Color(0xFF0B61FF)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) setBirthDate(picked);
  }

  void updateProfile() {
    Get.snackbar(
      'Success',
      'Profile updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void logout() async {
    try {
      // Clear SharedPreferences login state
      final authPersistence = Get.find<AuthPersistenceService>();
      await authPersistence.clearLoginState();

      // Sign out from Supabase
      await _supabase.client.auth.signOut();

      // Navigate to Login
      Get.offAll(() => const LoginView(), binding: LoginBinding());
    } catch (e) {
      Get.snackbar('Error', 'Logout failed: ${e.toString()}');
    }
  }
}

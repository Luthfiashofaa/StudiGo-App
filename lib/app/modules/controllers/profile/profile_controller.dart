import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/supabase_service.dart';
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

  final SupabaseService _supabase = Get.find<SupabaseService>();
  final RxBool isSaving = false.obs;
  final RxBool isLoadingProfile = false.obs;
  final RxBool hasChanges = false.obs;

  // store original loaded values to detect changes
  final Map<String, dynamic> _original = {};

  @override
  void onInit() {
    super.onInit();
    _attachListeners();
    fetchProfile();
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
          Get.snackbar('Permission denied', 'Camera permission is required to take photos');
          return;
        }
      } else {
        if (Platform.isAndroid) {
          final statuses = await [Permission.photos, Permission.storage].request();
          final granted = statuses.values.any((s) => s.isGranted);
          if (!granted) {
            Get.snackbar('Permission denied', 'Storage permission is required to select photos');
            return;
          }
        } else if (Platform.isIOS) {
          final status = await Permission.photos.request();
          if (!status.isGranted) {
            Get.snackbar('Permission denied', 'Photos permission is required to select photos');
            return;
          }
        }
      }

      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
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
      final res = await _supabase.from('profiles').select().eq('user_id', user.id);
      if (res != null && res is List && res.isNotEmpty) {
        final p = Map<String, dynamic>.from(res[0]);
        _profileId = p['id']?.toString();
        emailController.text = p['email']?.toString() ?? '';
        firstNameController.text = p['first_name']?.toString() ?? '';
        lastNameController.text = p['last_name']?.toString() ?? '';
        phoneController.text = p['phone']?.toString() ?? '';
        countryCode = p['country_code']?.toString() ?? countryCode;
        countryDialCode = p['country_dial_code']?.toString() ?? countryDialCode;
        avatarUrl = p['avatar_url']?.toString();

        _original['email'] = emailController.text.trim();
        _original['first_name'] = firstNameController.text.trim();
        _original['last_name'] = lastNameController.text.trim();
        _original['phone'] = phoneController.text.trim();
        _original['country_code'] = countryCode;
        _original['country_dial_code'] = countryDialCode;
        _original['avatar_url'] = avatarUrl ?? '';

        final dobRaw = p['dob']?.toString();
        if (dobRaw != null && dobRaw.isNotEmpty) {
          final dt = DateTime.tryParse(dobRaw);
          if (dt != null) setBirthDate(dt);
          _original['dob'] = dt?.toIso8601String() ?? '';
        }

        hasChanges.value = false;
        update();
        return;
      }

      // fallback: try legacy `users` table (matches screenshot)
      final usersRes = await _supabase.from('users').select().eq('email', user.email).limit(1);
      if (usersRes != null && usersRes is List && usersRes.isNotEmpty) {
        final u = Map<String, dynamic>.from(usersRes[0]);
        _profileId = u['id']?.toString();
        emailController.text = u['email']?.toString() ?? user.email ?? '';
        firstNameController.text = u['firstname']?.toString() ?? u['first_name']?.toString() ?? '';
        lastNameController.text = u['lastname']?.toString() ?? u['last_name']?.toString() ?? '';
        phoneController.text = u['phone_number']?.toString() ?? u['phone']?.toString() ?? '';
        avatarUrl = u['photo_url']?.toString() ?? u['photoUrl']?.toString() ?? '';

        final dobRaw2 = u['birthdate']?.toString() ?? u['birth_date']?.toString();
        if (dobRaw2 != null && dobRaw2.isNotEmpty) {
          final dt2 = DateTime.tryParse(dobRaw2);
          if (dt2 != null) setBirthDate(dt2);
          _original['dob'] = dt2?.toIso8601String() ?? '';
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

      // final fallback: auth metadata
      final meta = user.userMetadata ?? <String, dynamic>{};
      emailController.text = user.email ?? '';
      firstNameController.text = (meta['firstname'] ?? meta['first_name'] ?? meta['given_name'] ?? '')?.toString() ?? '';
      lastNameController.text = (meta['lastname'] ?? meta['last_name'] ?? meta['family_name'] ?? '')?.toString() ?? '';
      phoneController.text = (meta['phone_number'] ?? meta['phone'] ?? '')?.toString() ?? '';
      avatarUrl = (meta['photo_url'] ?? meta['photoUrl'] ?? '')?.toString() ?? '';

      final dobRawMeta = (meta['birthdate'] ?? meta['dob'] ?? meta['date_of_birth'])?.toString();
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
    if (avatarPath == null) return avatarUrl;
    final user = _supabase.currentUser;
    if (user == null) return null;

    try {
      final file = File(avatarPath!);
      final ext = avatarPath!.split('.').last;
      final path = 'avatars/${user.id}.$ext';
      await _supabase.storage.from('avatars').upload(path, file, fileOptions: const FileOptions(upsert: true));
      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      avatarUrl = publicUrl?.toString();
      _original['avatar_url'] = avatarUrl ?? '';
      return avatarUrl;
    } catch (e) {
      debugPrint('avatar upload failed: $e');
      return avatarUrl;
    }
  }

  Future<void> saveProfile() async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('User belum login.');

    isSaving.value = true;
    try {
      final uploadedAvatar = await _uploadAvatarIfNeeded();

      final payload = {
        'user_id': user.id,
        'email': emailController.text.trim(),
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'dob': birthDate?.toIso8601String(),
        'phone': phoneController.text.trim(),
        'country_code': countryCode,
        'country_dial_code': countryDialCode,
        'avatar_url': uploadedAvatar,
        'updated_at': DateTime.now().toIso8601String(),
      }..removeWhere((k, v) => v == null);

      if (_profileId != null) {
        final id = _profileId!;
        await _supabase.from('profiles').update(payload).eq('id', id).eq('user_id', user.id);
        _original['email'] = payload['email'] ?? _original['email'];
        _original['first_name'] = payload['first_name'] ?? _original['first_name'];
        _original['last_name'] = payload['last_name'] ?? _original['last_name'];
        _original['phone'] = payload['phone'] ?? _original['phone'];
        _original['dob'] = payload['dob'] ?? _original['dob'];
        _original['country_code'] = payload['country_code'] ?? _original['country_code'];
        _original['country_dial_code'] = payload['country_dial_code'] ?? _original['country_dial_code'];
        _original['avatar_url'] = uploadedAvatar ?? _original['avatar_url'];
      } else {
        final res = await _supabase.from('profiles').insert(payload);
        if (res != null && res is List && res.isNotEmpty) {
          _profileId = res[0]['id']?.toString();
          _original['email'] = payload['email'] ?? '';
          _original['first_name'] = payload['first_name'] ?? '';
          _original['last_name'] = payload['last_name'] ?? '';
          _original['phone'] = payload['phone'] ?? '';
          _original['dob'] = payload['dob'] ?? '';
          _original['country_code'] = payload['country_code'] ?? '';
          _original['country_dial_code'] = payload['country_dial_code'] ?? '';
          _original['avatar_url'] = uploadedAvatar ?? '';
        }
      }

      Get.snackbar('Sukses', 'Profil disimpan', snackPosition: SnackPosition.BOTTOM);
    } on PostgrestException catch (e) {
      Get.snackbar('Gagal', e.message ?? e.toString());
    } catch (e) {
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
      await _supabase.from('profiles').delete().eq('id', id).eq('user_id', user.id);
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
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B61FF)).copyWith(primary: const Color(0xFF0B61FF)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) setBirthDate(picked);
  }

  void updateProfile() {
    Get.snackbar('Success', 'Profile updated', snackPosition: SnackPosition.BOTTOM);
  }

  void logout() {
    Get.offAll(() => const LoginView(), binding: LoginBinding());
  }
}
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/services/supabase_service.dart';
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

  final SupabaseService _supabase = Get.find<SupabaseService>();
  final RxBool isSaving = false.obs;
  final RxBool isLoadingProfile = false.obs;
  final RxBool hasChanges = false.obs;

  // store original loaded values to detect changes
  final Map<String, dynamic> _original = {};

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

  @override
  void onInit() {
    super.onInit();
    _attachListeners();
    fetchProfile();
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
    final countryC = countryCode ?? '';
    final countryD = countryDialCode ?? '';

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
    // Request runtime permissions first
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
      final res = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', user.id);
      if (res != null && res is List && res.isNotEmpty) {
        final p = Map<String, dynamic>.from(res[0]);
        _profileId = p['id']?.toString();
        emailController.text = p['email']?.toString() ?? '';
        firstNameController.text = p['first_name']?.toString() ?? '';
        lastNameController.text = p['last_name']?.toString() ?? '';
        phoneController.text = p['phone']?.toString() ?? '';
        countryCode = p['country_code']?.toString() ?? countryCode;
        countryDialCode = p['country_dial_code']?.toString() ?? countryDialCode;
        avatarUrl = p['avatar_url']?.toString();
        // store original snapshot to detect future changes
        _original['email'] = emailController.text.trim();
        _original['first_name'] = firstNameController.text.trim();
        _original['last_name'] = lastNameController.text.trim();
        _original['phone'] = phoneController.text.trim();
        _original['country_code'] = countryCode;
        _original['country_dial_code'] = countryDialCode;
        _original['avatar_url'] = avatarUrl ?? '';
        final dobRaw = p['dob']?.toString();
        if (dobRaw != null) {
          final dt = DateTime.tryParse(dobRaw);
          if (dt != null) setBirthDate(dt);
          // ensure original dob is set from loaded value
          _original['dob'] = dt?.toIso8601String() ?? '';
        }
        // ensure hasChanges reflects initial loaded state
        void updateProfile() {
          // simple UX helper used elsewhere — keep it functional
          Get.snackbar(
            'Success',
            'Profile updated',
            snackPosition: SnackPosition.BOTTOM,
          );
        }

        void logout() {
          // Navigate to login and clear stack
          Get.offAll(() => const LoginView(), binding: LoginBinding());
        }
      return avatarUrl;
    }
  }

  Future<void> saveProfile() async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('User belum login.');

    isSaving.value = true;
    try {
      final uploadedAvatar = await _uploadAvatarIfNeeded();

      final payload = {
        'user_id': user.id,
        'email': emailController.text.trim(),
        'first_name': firstNameController.text.trim(),
        'last_name': lastNameController.text.trim(),
        'dob': birthDate?.toIso8601String(),
        'phone': phoneController.text.trim(),
        'country_code': countryCode,
        'country_dial_code': countryDialCode,
        'avatar_url': uploadedAvatar,
        'updated_at': DateTime.now().toIso8601String(),
      }..removeWhere((k, v) => v == null);

      if (_profileId != null) {
        final id = _profileId!;
        await _supabase
            .from('profiles')
            .update(payload)
            .eq('id', id)
            .eq('user_id', user.id);
        // update original snapshot after successful update
        _original['email'] = payload['email'] ?? _original['email'];
        _original['first_name'] =
            payload['first_name'] ?? _original['first_name'];
        _original['last_name'] = payload['last_name'] ?? _original['last_name'];
        _original['phone'] = payload['phone'] ?? _original['phone'];
        _original['dob'] = payload['dob'] ?? _original['dob'];
        _original['country_code'] =
            payload['country_code'] ?? _original['country_code'];
        _original['country_dial_code'] =
            payload['country_dial_code'] ?? _original['country_dial_code'];
        _original['avatar_url'] = uploadedAvatar ?? _original['avatar_url'];
      } else {
        final res = await _supabase.from('profiles').insert(payload);
        if (res != null && res is List && res.isNotEmpty) {
          _profileId = res[0]['id']?.toString();
          // set original snapshot after successful insert
          _original['email'] = payload['email'] ?? '';
          _original['first_name'] = payload['first_name'] ?? '';
          _original['last_name'] = payload['last_name'] ?? '';
          _original['phone'] = payload['phone'] ?? '';
          _original['dob'] = payload['dob'] ?? '';
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
      Get.snackbar('Gagal', e.message ?? e.toString());
    } catch (e) {
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
      await _supabase
          .from('profiles')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
      _profileId = null;
      _original.clear();
      hasChanges.value = false;
      // optionally delete avatar from storage
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
    // TODO: send profile update to API
    Get.snackbar(
      } else {
        // No profile row in `profiles` — try to read from legacy `users` table (as in screenshot)
        try {
          final usersRes = await _supabase
              .from('users')
              .select()
              .eq('email', user.email)
              .limit(1);

          if (usersRes != null && usersRes is List && usersRes.isNotEmpty) {
            final u = Map<String, dynamic>.from(usersRes[0]);
            // map fields from users table
            _profileId = u['id']?.toString();
            emailController.text = u['email']?.toString() ?? user.email ?? '';
            firstNameController.text = u['firstname']?.toString() ?? u['first_name']?.toString() ?? '';
            lastNameController.text = u['lastname']?.toString() ?? u['last_name']?.toString() ?? '';
            phoneController.text = u['phone_number']?.toString() ?? u['phone']?.toString() ?? '';
            avatarUrl = u['photo_url']?.toString() ?? u['photoUrl']?.toString() ?? '';
            final dobRaw2 = u['birthdate']?.toString() ?? u['birth_date']?.toString();
            if (dobRaw2 != null && dobRaw2.isNotEmpty) {
              final dt2 = DateTime.tryParse(dobRaw2);
              if (dt2 != null) setBirthDate(dt2);
              _original['dob'] = dt2?.toIso8601String() ?? '';
            }

            // set snapshot from users table
            _original['email'] = emailController.text.trim();
            _original['first_name'] = firstNameController.text.trim();
            _original['last_name'] = lastNameController.text.trim();
            _original['phone'] = phoneController.text.trim();
            _original['country_code'] = countryCode;
            _original['country_dial_code'] = countryDialCode;
            _original['avatar_url'] = avatarUrl ?? '';
            hasChanges.value = false;
            update();
          } else {
            // fallback to auth user metadata when neither profiles nor users rows exist
            final meta = user.userMetadata ?? <String, dynamic>{};
            emailController.text = user.email ?? '';
            firstNameController.text = (meta['first_name'] ?? meta['firstName'] ?? meta['given_name'] ?? '')?.toString() ?? '';
            lastNameController.text = (meta['last_name'] ?? meta['lastName'] ?? meta['family_name'] ?? '')?.toString() ?? '';
            phoneController.text = (meta['phone'] ?? '')?.toString() ?? '';
            countryCode = (meta['country_code'] ?? countryCode)?.toString() ?? countryCode;
            countryDialCode = (meta['country_dial_code'] ?? countryDialCode)?.toString() ?? countryDialCode;
            avatarUrl = (meta['avatar_url'] ?? '')?.toString() ?? '';
            final dobRawMeta = (meta['dob'] ?? meta['date_of_birth'])?.toString();
            if (dobRawMeta != null && dobRawMeta.isNotEmpty) {
              final dt = DateTime.tryParse(dobRawMeta);
              if (dt != null) setBirthDate(dt);
              _original['dob'] = dt?.toIso8601String() ?? '';
            }

            // set original snapshot from metadata so button stays disabled until edits
            _original['email'] = emailController.text.trim();
            _original['first_name'] = firstNameController.text.trim();
            _original['last_name'] = lastNameController.text.trim();
            _original['phone'] = phoneController.text.trim();
            _original['country_code'] = countryCode;
            _original['country_dial_code'] = countryDialCode;
            _original['avatar_url'] = avatarUrl ?? '';
            hasChanges.value = false;
            update();
          }
        } catch (e) {
          debugPrint('fetchProfile users table fallback error: $e');
        }
      }

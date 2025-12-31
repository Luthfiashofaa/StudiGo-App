import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile/profile_controller.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:image_picker/image_picker.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0B61FF);

    InputDecoration fieldDecoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isTablet = constraints.maxWidth >= 600;
        final double horizontalPadding = isTablet ? 32.0 : 20.0;
        final double verticalPadding = isTablet ? 24.0 : 18.0;
        final double avatarSize = isTablet ? 140.0 : 120.0;
        final double maxContentWidth = isTablet ? 900.0 : double.infinity;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: GetBuilder<ProfileController>(
                init: ProfileController(),
                builder: (ctrl) {
                  final c = ctrl;
                  if (c == null) {
                    return const SizedBox();
                  }
                  return Obx(() {
                    if (c.isLoadingProfile.value) {
                      return const SizedBox(
                        height: 240,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),

                        // Avatar with camera badge
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: avatarSize,
                                height: avatarSize,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: () {
                                    if (c.avatarPath != null) {
                                      return Image.file(
                                        File(c.avatarPath!),
                                        fit: BoxFit.cover,
                                      );
                                    }
                                    if (c.avatarUrl != null &&
                                        c.avatarUrl!.isNotEmpty) {
                                      return Image.network(
                                        c.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Image.asset(
                                              'assets/avatar_placeholder.png',
                                              fit: BoxFit.cover,
                                            ),
                                      );
                                    }
                                    return Image.asset(
                                      'assets/avatar_placeholder.png',
                                      fit: BoxFit.cover,
                                    );
                                  }(),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      builder: (ctx) => SafeArea(
                                        child: Wrap(
                                          children: [
                                            ListTile(
                                              leading: const Icon(
                                                Icons.photo_library,
                                              ),
                                              title: const Text(
                                                'Choose from gallery',
                                              ),
                                              onTap: () {
                                                c.pickImage(
                                                  ImageSource.gallery,
                                                );
                                                Navigator.of(ctx).pop();
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(
                                                Icons.camera_alt,
                                              ),
                                              title: const Text('Take a photo'),
                                              onTap: () {
                                                c.pickImage(ImageSource.camera);
                                                Navigator.of(ctx).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: isTablet ? 44 : 40,
                                    height: isTablet ? 44 : 40,
                                    decoration: BoxDecoration(
                                      color: primaryBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isTablet ? 22 : 18),

                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: isTablet ? 10 : 8),
                        TextField(
                          controller: c.emailController,
                          readOnly: true,
                          keyboardType: TextInputType.emailAddress,
                          decoration: fieldDecoration('Email').copyWith(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),

                        SizedBox(height: isTablet ? 16 : 12),
                        // First & Last Name (two-column on tablet)
                        if (!isTablet) ...[
                          Text(
                            'First Name',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: isTablet ? 10 : 8),
                          TextField(
                            controller: c.firstNameController,
                            decoration: fieldDecoration('First Name'),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            'Last Name',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: isTablet ? 10 : 8),
                          TextField(
                            controller: c.lastNameController,
                            decoration: fieldDecoration('Last Name'),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'First Name',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: c.firstNameController,
                                      decoration: fieldDecoration('First Name'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Last Name',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: c.lastNameController,
                                      decoration: fieldDecoration('Last Name'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],

                        SizedBox(height: isTablet ? 16 : 12),
                        // Date of Birth & Phone Number (two-column on tablet)
                        if (!isTablet) ...[
                          Text(
                            'Date of Birth',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: isTablet ? 10 : 8),
                          GestureDetector(
                            onTap: () => c.pickDate(context),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: c.dobController,
                                decoration: fieldDecoration('Date of Birth'),
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 16 : 12),
                          Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: isTablet ? 10 : 8),
                          Row(
                            children: [
                              Container(
                                height: isTablet ? 56 : 52,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: CountryCodePicker(
                                    onChanged: (country) => c.setCountry(
                                      country.code ?? 'ID',
                                      country.dialCode ?? '+62',
                                    ),
                                    initialSelection: c.countryCode,
                                    favorite: const ['+62', 'US'],
                                    showOnlyCountryWhenClosed: false,
                                    alignLeft: false,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: c.phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: fieldDecoration('Phone Number'),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Date of Birth',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () => c.pickDate(context),
                                      child: AbsorbPointer(
                                        child: TextField(
                                          controller: c.dobController,
                                          decoration: fieldDecoration(
                                            'Date of Birth',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Phone Number',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Container(
                                          height: 56,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: CountryCodePicker(
                                              onChanged: (country) =>
                                                  c.setCountry(
                                                    country.code ?? 'ID',
                                                    country.dialCode ?? '+62',
                                                  ),
                                              initialSelection: c.countryCode,
                                              favorite: const ['+62', 'US'],
                                              showOnlyCountryWhenClosed: false,
                                              alignLeft: false,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextField(
                                            controller: c.phoneController,
                                            keyboardType: TextInputType.phone,
                                            decoration: fieldDecoration(
                                              'Phone Number',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],

                        SizedBox(height: isTablet ? 24 : 20),

                        // Notification Reminder Settings
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Pengingat Jadwal',
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Obx(
                                    () => Switch(
                                      value: c.enableNotifications.value,
                                      onChanged: (value) =>
                                          c.setEnableNotifications(value),
                                      activeColor: primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Obx(
                                () => c.enableNotifications.value
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ingatkan saya',
                                            style: TextStyle(
                                              fontSize: isTablet ? 14 : 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    child: Obx(
                                                      () => DropdownButton<int>(
                                                        value: c
                                                            .reminderMinutesBefore
                                                            .value,
                                                        isExpanded: true,
                                                        underline:
                                                            const SizedBox(),
                                                        items: [5, 10, 15, 30, 60].map((
                                                          int minutes,
                                                        ) {
                                                          return DropdownMenuItem<
                                                            int
                                                          >(
                                                            value: minutes,
                                                            child: Text(
                                                              minutes == 60
                                                                  ? '1 jam'
                                                                  : '$minutes menit',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          if (value != null) {
                                                            c.setReminderMinutesBefore(
                                                              value,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 12,
                                                      ),
                                                  child: Text(
                                                    'sebelum jadwal',
                                                    style: TextStyle(
                                                      fontSize: isTablet
                                                          ? 14
                                                          : 13,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        'Pengingat dimatikan',
                                        style: TextStyle(
                                          fontSize: isTablet ? 14 : 13,
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              // Info text
                              Obx(
                                () => c.enableNotifications.value
                                    ? Text(
                                        'Notifikasi otomatis akan muncul ${c.reminderMinutesBefore.value} menit sebelum jadwal dimulai',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue.shade700,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isTablet ? 24 : 20),
                        Obx(
                          () => ElevatedButton(
                            onPressed: (c.isSaving.value || !c.hasChanges.value)
                                ? null
                                : c.saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              minimumSize: Size.fromHeight(isTablet ? 56 : 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: c.isSaving.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Complete',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: isTablet ? 14 : 12),
                        OutlinedButton(
                          onPressed: c.logout,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: primaryBlue),
                            minimumSize: Size.fromHeight(isTablet ? 52 : 48),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        SizedBox(height: isTablet ? 46 : 40),
                      ],
                    );
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

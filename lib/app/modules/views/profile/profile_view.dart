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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: GetBuilder<ProfileController>(
        builder: (ctrl) {
          return Obx(() {
            if (ctrl.isLoadingProfile.value) {
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
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: ClipOval(
                          child: () {
                            if (ctrl.avatarPath != null) {
                              return Image.file(
                                File(ctrl.avatarPath!),
                                fit: BoxFit.cover,
                              );
                            }
                            if (ctrl.avatarUrl != null &&
                                ctrl.avatarUrl!.isNotEmpty) {
                              return Image.network(
                                ctrl.avatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
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
                                      leading: const Icon(Icons.photo_library),
                                      title: const Text('Choose from gallery'),
                                      onTap: () {
                                        controller.pickImage(
                                          ImageSource.gallery,
                                        );
                                        Navigator.of(ctx).pop();
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.camera_alt),
                                      title: const Text('Take a photo'),
                                      onTap: () {
                                        controller.pickImage(
                                          ImageSource.camera,
                                        );
                                        Navigator.of(ctx).pop();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
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

                const SizedBox(height: 18),

                const Text(
                  'Email',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.emailController,
                  readOnly: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: fieldDecoration(
                    'Email',
                  ).copyWith(filled: true, fillColor: Colors.grey.shade100),
                ),

                const SizedBox(height: 12),
                const Text(
                  'First Name',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.firstNameController,
                  decoration: fieldDecoration('First Name'),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Last Name',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller.lastNameController,
                  decoration: fieldDecoration('Last Name'),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Date of Birth',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => controller.pickDate(context),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: controller.dobController,
                      decoration: fieldDecoration('Date of Birth'),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Phone Number',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: CountryCodePicker(
                          onChanged: (country) => controller.setCountry(
                            country.code ?? 'ID',
                            country.dialCode ?? '+62',
                          ),
                          initialSelection: ctrl.countryCode,
                          favorite: const ['+62', 'US'],
                          showOnlyCountryWhenClosed: false,
                          alignLeft: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller.phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: fieldDecoration('Phone Number'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Obx(
                  () => ElevatedButton(
                    onPressed:
                        (controller.isSaving.value ||
                            !controller.hasChanges.value)
                        ? null
                        : controller.saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isSaving.value
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

                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: controller.logout,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: primaryBlue),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            );
          });
        },
      ),
    );
  }
}

# Setup Reset Password dengan Supabase

## Masalah yang Diperbaiki
- Link reset password dari email membuka halaman kosong
- Token tidak bisa diterima oleh aplikasi mobile

## Solusi yang Diimplementasikan

### 1. **Halaman Web Redirect (`web/auth-callback.html`)**
   - Halaman web yang menerima token dari Supabase
   - Otomatis redirect ke app StudiGo dengan deep link
   - Fallback manual jika auto-redirect gagal

### 2. **Update Auth Callback Handler**
   - Deteksi `type=recovery` untuk password reset
   - Navigasi ke halaman set new password
   - Support untuk normal sign-in juga

---

## Konfigurasi di Supabase Dashboard

### **Step 1: Deploy Halaman Web**

Anda perlu host file `web/auth-callback.html` di web server. Pilihan:

#### **Opsi A: Netlify (Gratis & Mudah)**
1. Buat akun di [netlify.com](https://netlify.com)
2. Drag & drop folder `web/` ke Netlify
3. Dapatkan URL, contoh: `https://studigo-app.netlify.app/auth-callback.html`

#### **Opsi B: GitHub Pages**
1. Push project ke GitHub
2. Settings → Pages → Enable
3. URL: `https://yourusername.github.io/StudiGo-App/web/auth-callback.html`

#### **Opsi C: Firebase Hosting**
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# pilih folder web/
firebase deploy
```

#### **Opsi D: Vercel**
1. Install: `npm i -g vercel`
2. Di folder web/: `vercel`
3. Dapatkan URL

---

### **Step 2: Konfigurasi Supabase**

1. **Buka [Supabase Dashboard](https://supabase.com/dashboard)**

2. **Authentication → URL Configuration**
   
   Tambahkan ke **Redirect URLs**:
   ```
   studigo://auth-callback
   https://YOUR-DOMAIN.com/auth-callback.html
   ```
   
   Contoh:
   ```
   studigo://auth-callback
   https://studigo-app.netlify.app/auth-callback.html
   ```

3. **Authentication → Email Templates → Reset Password**
   
   Edit template, ubah `{{ .ConfirmationURL }}` menjadi:
   ```
   https://YOUR-DOMAIN.com/auth-callback.html#access_token={{ .TokenHash }}&type=recovery
   ```
   
   Atau lebih baik, gunakan redirect:
   ```html
   <p>Reset your password by clicking this link:</p>
   <p><a href="https://YOUR-DOMAIN.com/auth-callback.html{{ .TokenHash }}">Reset Password</a></p>
   ```

---

### **Step 3: Update .env Flutter**

Buat/edit file `.env`:
```env
RESET_PASSWORD_REDIRECT=https://YOUR-DOMAIN.com/auth-callback.html
```

---

## Testing

### **Test di Development:**

1. Jalankan app:
   ```bash
   flutter run
   ```

2. Tap "Forgot Password"

3. Masukkan email yang terdaftar

4. Cek inbox email:
   - Klik link di email
   - Harus redirect ke app
   - Masuk ke halaman "Set New Password"

### **Troubleshooting:**

❌ **Halaman kosong:**
- Pastikan URL di Redirect URLs Supabase sudah benar
- Cek email template menggunakan URL yang benar

❌ **App tidak terbuka:**
- Pastikan deep link `studigo://` sudah terkonfigurasi di AndroidManifest.xml
- Coba tap manual "Open App" di halaman web

❌ **Token expired:**
- Token recovery berlaku 1 jam
- Minta reset password baru jika sudah expired

---

## File yang Diubah

1. ✅ `lib/app/modules/controllers/auth/forgot_password_controller.dart`
   - Menggunakan Supabase built-in reset

2. ✅ `lib/app/modules/views/auth/auth_callback_view.dart`
   - Handle recovery token
   - Navigate ke new password screen

3. ✅ `web/auth-callback.html` (NEW)
   - Landing page untuk token dari email
   - Auto redirect ke app

---

## Next Steps

1. Deploy `web/auth-callback.html` ke hosting pilihan Anda
2. Update Supabase Redirect URLs
3. Update email template (optional)
4. Test end-to-end flow
5. Verifikasi di Android device

---

## Catatan Penting

- **Jangan skip** konfigurasi Redirect URLs di Supabase
- Token recovery hanya valid **1 jam**
- Email template bisa di-customize di Supabase Dashboard
- Untuk production, gunakan custom domain (bukan netlify/vercel subdomain)

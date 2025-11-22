import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // <--- (1) WAJIB DIIMPOR

class AccountProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String? initialImagePath; // Menerima path gambar awal

  const AccountProfileScreen({
    super.key,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    this.initialImagePath, // Menerima path
  });

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  // --- STATE BARU UNTUK GAMBAR PROFIL ---
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker(); // <--- (2) WAJIB DINISIALISASI
  // ----------------------------------------

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    // Inisialisasi path gambar dengan nilai yang dikirim dari AccountPage
    _profileImagePath = widget.initialImagePath;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  final TextStyle _labelStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black54,
  );

  // MARK: - FUNGSI GAMBAR (Image Picker Logic NYATA)
  void _pickImage(ImageSource source) async { // Mengambil ImageSource langsung
    try {
      // Panggil image_picker untuk membuka kamera atau galeri
      final XFile? pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _profileImagePath = pickedFile.path; // Simpan path file lokal
        });
      }
    } catch (e) {
      // Tangani error jika izin ditolak atau terjadi kesalahan lain
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengakses ${source == ImageSource.camera ? "Kamera" : "Galeri"}: Pastikan izin sudah diberikan.')),
      );
    }
  }

  // --- FUNGSI UNTUK MENYIMPAN DAN KEMBALI (Mengirim data) ---
  void _saveProfileAndReturn() {
    final Map<String, dynamic> result = {
      'userName': _nicknameController.text,
      'userEmail': _emailController.text,
      'userPhone': _phoneController.text,
      'userProfilePath': _profileImagePath, // Kirim path gambar baru
    };
    
    Navigator.pop(context, result);
  }
  // ------------------------------------------

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // --- Profile Header Section ---
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: statusBarHeight + 10.0, bottom: 30.0), 
              decoration: const BoxDecoration(
                color: Color(0xFFE54721),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50), 
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Column(
                children: <Widget>[
                  // BARIS UNTUK TOMBOL KEMBALI DAN JUDUL "AKUN"
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context); 
                          },
                        ),
                        const Text(
                          'Akun', 
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 20, 
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ],
                    ),
                  ),

                  // Profile Picture
                  CircleAvatar( 
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 48,
                      // *LOGIC TAMPILKAN GAMBAR NYATA*
                      backgroundImage: _profileImagePath != null
                          // Jika path ada, tampilkan FileImage
                          ? FileImage(File(_profileImagePath!)) 
                          // Jika tidak ada, gunakan asset default
                          : const AssetImage('assets/profile_placeholder.jpg') as ImageProvider, 
                    ),
                  ),
                  const SizedBox(height: 30.0),

                  // Galeri & Kamera Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Hubungkan ke fungsi _pickImage
                      _buildImageSourceButton('Galeri', () => _pickImage(ImageSource.gallery)),
                      const SizedBox(width: 20.0),
                      // Hubungkan ke fungsi _pickImage
                      _buildImageSourceButton('Kamera', () => _pickImage(ImageSource.camera)),
                    ],
                  ),
                ],
              ),
            ),
            
            // --- Form Fields Section ---
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Nama Panggilan (Nickname)
                  Text('Nama Panggilan', style: _labelStyle),
                  const SizedBox(height: 8.0),
                  _buildInputField(_nicknameController, widget.initialName, TextInputType.text),
                  const SizedBox(height: 20.0),

                  // Email
                  Text('Email', style: _labelStyle),
                  const SizedBox(height: 8.0),
                  _buildInputField(_emailController, widget.initialEmail, TextInputType.emailAddress),
                  const SizedBox(height: 20.0),

                  // Nomor Telepon (Phone Number)
                  Text('Nomor Telepon', style: _labelStyle),
                  const SizedBox(height: 8.0),
                  _buildInputField(_phoneController, widget.initialPhone, TextInputType.phone),
                  const SizedBox(height: 40.0),

                  // --- Action Buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      // BATAL (Cancel) Button
                      Expanded(
                        child: _buildActionButton(
                          'BATAL',
                          Colors.grey.shade200,
                          Colors.black,
                          () { Navigator.pop(context); },
                        ),
                      ),
                      const SizedBox(width: 15.0),
                      // SIMPAN (Save) Button
                      Expanded(
                        child: _buildActionButton(
                          'SIMPAN',
                          const Color(0xFFE54721),
                          Colors.white,
                          () => _saveProfileAndReturn(), // Panggil fungsi simpan dan kirim data
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildImageSourceButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, TextInputType keyboardType) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
        border: InputBorder.none,
        filled: true,
        fillColor: Colors.grey.shade200,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0), borderSide: const BorderSide(color: Color(0xFFFF8B6D), width: 2.0)),
      ),
    );
  }

  Widget _buildActionButton(String text, Color backgroundColor, Color textColor, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: textColor,
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 15.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 4, 
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

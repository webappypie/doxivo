import 'package:flutter/material.dart';
import '../../core/storage/file_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/document_model.dart';
import '../../domain/repositories/document_repository.dart';
import '../../services/pdf_toolkit_service.dart';
import '../common/doxivo_button.dart';
import '../common/processing_dialog.dart';
import '../viewer/pdf_viewer_screen.dart';

class ProtectScreen extends StatefulWidget {
  final DocumentModel document;
  final PdfToolkitService pdfToolkitService;
  final FileStorageService fileStorageService;
  final DocumentRepository documentRepository;

  const ProtectScreen({
    super.key,
    required this.document,
    required this.pdfToolkitService,
    required this.fileStorageService,
    required this.documentRepository,
  });

  @override
  State<ProtectScreen> createState() => _ProtectScreenState();
}

class _ProtectScreenState extends State<ProtectScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscurePassword = true;
  int _keyLength = 256;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _protectDocument() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return;
    }

    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password should be at least 4 characters long')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const ProcessingDialog(message: 'Encrypting PDF with AES-256...'),
    );

    try {
      final tempOutputFile = widget.fileStorageService.createTempFile(extension: 'pdf');
      await widget.pdfToolkitService.encryptPdf(
        inputPath: widget.document.filePath,
        outputPath: tempOutputFile.path,
        userPassword: password,
        keyLength: _keyLength,
      );

      final newTitle = '${widget.document.title} (Protected)';
      final bytes = await tempOutputFile.readAsBytes();
      final savedDoc = await widget.fileStorageService.saveManagedPdf(newTitle, bytes);

      final now = DateTime.now();
      final newDoc = DocumentModel(
        id: 'doc_${now.millisecondsSinceEpoch}',
        title: newTitle,
        filePath: savedDoc.path,
        thumbnailPath: widget.document.thumbnailPath,
        pageCount: widget.document.pageCount,
        byteSize: bytes.length,
        createdAt: now,
        updatedAt: now,
      );

      await widget.documentRepository.insertDocument(newDoc);

      if (tempOutputFile.existsSync()) {
        tempOutputFile.deleteSync();
      }

      if (mounted) {
        Navigator.of(context).pop(); // dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document encrypted successfully!')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => PdfViewerScreen(
              document: newDoc,
              documentRepository: widget.documentRepository,
              pdfToolkitService: widget.pdfToolkitService,
              fileStorageService: widget.fileStorageService,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Encryption error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Protect PDF'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Standard PDF Security',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Secures this file using standard AES-256 encryption. Anyone opening this document will be prompted for this password.',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Set Password',
                  hintText: 'Enter password to protect PDF',
                  prefixIcon: const Icon(Icons.key),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm password field
              TextField(
                controller: _confirmController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
              ),
              const SizedBox(height: 20),

              // Key length option
              Text('Encryption Standard', style: AppTypography.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _keyLength == 256 ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _keyLength == 256 ? AppColors.primary : Colors.grey,
                ),
                title: const Text('AES-256 bit (Recommended)'),
                subtitle: const Text('Industry standard, maximum cryptographic security'),
                onTap: () => setState(() => _keyLength = 256),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _keyLength == 128 ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _keyLength == 128 ? AppColors.primary : Colors.grey,
                ),
                title: const Text('AES-128 bit (Legacy)'),
                subtitle: const Text('Backwards compatibility for older PDF viewers'),
                onTap: () => setState(() => _keyLength = 128),
              ),

              const SizedBox(height: 32),
              DoxivoButton(
                label: 'Encrypt & Save PDF',
                icon: Icons.lock_outline,
                onPressed: _protectDocument,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

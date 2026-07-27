// Reusable Widget - Image & PDF Selector File Uploader
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class FileUploader extends StatefulWidget {
  final String label;
  final List<String> allowedExtensions;
  final void Function(File?) onFileSelected;
  final String? initialFileUrl;

  const FileUploader({
    super.key,
    required this.label,
    this.allowedExtensions = const ['pdf', 'jpg', 'jpeg', 'png'],
    required this.onFileSelected,
    this.initialFileUrl,
  });

  @override
  State<FileUploader> createState() => _FileUploaderState();
}

class _FileUploaderState extends State<FileUploader> {
  File? _selectedFile;
  String? _fileName;
  String? _fileSize;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final bytes = await file.length();
        
        // Enforce 5MB size bounds
        if (bytes > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("File size exceeds 5MB limit"),
                backgroundColor: AppColors.danger,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
          _fileSize = "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
        });
        widget.onFileSelected(file);
      }
    } catch (_) {
      // Quietly consume pick cancellations
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileSize = null;
    });
    widget.onFileSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          AppSpacing.h12,
          if (_selectedFile == null)
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      size: 36,
                      color: AppColors.gradientStart,
                    ),
                    AppSpacing.h8,
                    Text(
                      "Upload file (PDF or Image)",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gradientStart,
                      ),
                    ),
                    AppSpacing.h4,
                    Text(
                      "Allowed formats: ${widget.allowedExtensions.join(', ').toUpperCase()} (Max 5MB)",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    _fileName!.endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image,
                    color: _fileName!.endsWith('.pdf') ? AppColors.danger : AppColors.success,
                    size: 32,
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        AppSpacing.h4,
                        Text(
                          _fileSize!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: AppColors.danger),
                    onPressed: _clearFile,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

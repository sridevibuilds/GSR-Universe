// Presentation Layer - Parent View Notice Board Screen (Read-Only)
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../../data/models/notice_model.dart';
import '../cubit/parent_cubit.dart';
import '../cubit/parent_state.dart';

class ParentNoticeBoardPage extends StatelessWidget {
  const ParentNoticeBoardPage({super.key});

  void _showImageModal(BuildContext context, String path, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                backgroundColor: Colors.black.withValues(alpha: 0.8),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 500),
                  color: Colors.black,
                  child: _buildImageWidget(path, isModal: true),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _resolveFileUrl(String? path) {
    final baseUrl = sl<ApiClient>().baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (path == null || path.trim().isEmpty) return "$baseUrl/uploads/sample_submission.pdf";
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final clean = path.startsWith('/') ? path : '/$path';
    return "$baseUrl$clean";
  }

  void _showPdfViewerModal(BuildContext context, String title, Uint8List pdfBytes) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog.fullscreen(
          child: Scaffold(
            backgroundColor: Colors.grey.shade900,
            appBar: AppBar(
              backgroundColor: Colors.grey.shade900,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                title,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            body: PdfPreview(
              build: (format) => pdfBytes,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
            ),
          ),
        );
      },
    );
  }

  Future<void> _handlePdfAction(BuildContext context, String? fileName, String? filePath, {bool isDownload = false}) async {
    final cleanName = (fileName != null && fileName.trim().isNotEmpty)
        ? fileName.trim()
        : (filePath != null && filePath.trim().isNotEmpty ? filePath.trim().split('/').last : 'Notice_Attachment.pdf');

    AppNotifications.showSuccess(context, "${isDownload ? 'Downloading' : 'Opening'} $cleanName...");

    Uint8List? bytes;

    // 1. Try reading directly from local device filesystem if path is local
    if (filePath != null && filePath.trim().isNotEmpty) {
      try {
        final localFile = File(filePath.trim());
        if (await localFile.exists()) {
          bytes = await localFile.readAsBytes();
        }
      } catch (_) {}
    }

    // 2. Fetch network URL via Dio with timeouts
    if (bytes == null || bytes.isEmpty) {
      final url = _resolveFileUrl(filePath);
      final dioClient = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));

      if (url.startsWith('http://') || url.startsWith('https://')) {
        try {
          final response = await dioClient.get<List<int>>(
            url,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.data != null && response.data!.isNotEmpty) {
            bytes = Uint8List.fromList(response.data!);
          }
        } catch (e) {
          debugPrint("Dio File Download Error: $e");
        }
      }
    }

    if (bytes != null && bytes.isNotEmpty) {
      if (isDownload) {
        bool saved = false;
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (!downloadsDir.existsSync()) {
            downloadsDir.createSync(recursive: true);
          }
          final saveFile = File('${downloadsDir.path}/$cleanName');
          await saveFile.writeAsBytes(bytes);
          saved = true;
          if (context.mounted) {
            AppNotifications.showSuccess(context, "Saved to Downloads folder: $cleanName");
          }
        } catch (e) {
          debugPrint("Direct File Save Error: $e");
        }

        if (!saved) {
          await Printing.sharePdf(bytes: bytes, filename: cleanName);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _showPdfViewerModal(context, cleanName, bytes);
        }
      }
    } else {
      if (context.mounted) {
        AppNotifications.showError(context, "Unable to load notice PDF.");
      }
    }
  }

  void _viewPdfAttachment(BuildContext context, String? fileName, String? filePath) {
    final cleanName = fileName ?? (filePath != null ? filePath.split('/').last : 'Notice_Attachment.pdf');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: AppColors.parentPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Notice Attachment",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "File Name: $cleanName",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.parentPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: AppColors.parentPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        filePath ?? "Official notice document",
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("Close", style: GoogleFonts.inter(color: AppColors.textLight, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.parentPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.open_in_new, size: 14, color: Colors.white),
              label: Text("Open PDF", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(ctx);
                _handlePdfAction(context, fileName, filePath, isDownload: false);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageWidget(String path, {bool isModal = false}) {
    final cleanPath = path.trim();

    // Check if local file path
    try {
      final file = File(cleanPath);
      if (file.existsSync()) {
        return Image.file(file, fit: isModal ? BoxFit.contain : BoxFit.cover, width: double.infinity);
      }
    } catch (_) {}

    // Resolve network URL dynamically using ApiClient's configured baseUrl
    String finalUrl = cleanPath;
    if (!cleanPath.startsWith('http://') && !cleanPath.startsWith('https://')) {
      final String serverBaseUrl = sl<ApiClient>().baseUrl.replaceAll(RegExp(r'/+$'), '');
      final String relativePath = cleanPath.startsWith('/') ? cleanPath : '/$cleanPath';
      finalUrl = "$serverBaseUrl$relativePath";
    }

    return Image.network(
      finalUrl,
      fit: isModal ? BoxFit.contain : BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.parentPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.parentPrimary.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.image_outlined, size: 48, color: AppColors.parentPrimary),
              const SizedBox(height: 8),
              Text(
                "Notice Image Screenshot",
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.parentPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                cleanPath.split('/').last,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        final rawNotices = state.notices;
        final notices = rawNotices.map((item) => NoticeModel.fromJson(item)).toList();

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "Notice Board",
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: notices.isEmpty
                ? const Center(
                    child: EmptyStateWidget(
                      title: "No Notices Found",
                      message: "Official circulars and notice board posts published by faculty will appear here.",
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notices.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = notices[index];
                      final String title = item.title;
                      final String description = item.description;
                      final String? attachmentName = item.attachmentName;
                      final String? attachmentPath = item.attachmentPath;
                      final List<String> images = item.images;

                      final bool isPdf = (attachmentName != null && attachmentName.toLowerCase().endsWith('.pdf')) ||
                          (attachmentPath != null && attachmentPath.toLowerCase().endsWith('.pdf'));
                      final bool isSingleImage = !isPdf && (attachmentPath != null && attachmentPath.isNotEmpty);
                      final bool isGallery = images.isNotEmpty;

                      String dateStr = 'N/A';
                      if (item.date.isNotEmpty) {
                        try {
                          dateStr = DateFormat('dd-MMM-yyyy').format(
                            DateTime.parse(item.date),
                          );
                        } catch (_) {
                          dateStr = item.date;
                        }
                      }

                      return Container(
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.parentPrimary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    dateStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.parentPrimary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.push_pin_outlined, color: AppColors.parentPrimary, size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textDark),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                description,
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight, height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // 1. IMAGE DISPLAY INSIDE CARD (Visual Screenshot Card)
                            if (isSingleImage) ...[
                              GestureDetector(
                                onTap: () => _showImageModal(context, attachmentPath, title),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    height: 190,
                                    width: double.infinity,
                                    color: Colors.grey.shade100,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: _buildImageWidget(attachmentPath),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.fullscreen, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // 2. MULTIPLE IMAGES GALLERY CAROUSEL
                            if (isGallery) ...[
                              SizedBox(
                                height: 140,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  separatorBuilder: (context, idx) => const SizedBox(width: 8),
                                  itemBuilder: (context, idx) {
                                    final imgUrl = images[idx];
                                    return GestureDetector(
                                      onTap: () => _showImageModal(context, imgUrl, title),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Container(
                                          width: 140,
                                          color: Colors.grey.shade100,
                                          child: _buildImageWidget(imgUrl),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // 3. PDF VIEW + DOWNLOAD BUTTONS
                            if (isPdf) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.parentPrimary,
                                        side: const BorderSide(color: AppColors.parentPrimary),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.visibility, size: 14),
                                      label: Text("View PDF", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () => _viewPdfAttachment(context, attachmentName, attachmentPath),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.parentPrimary,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.download, size: 14, color: Colors.white),
                                      label: Text("Download PDF", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                      onPressed: () => _handlePdfAction(context, attachmentName, attachmentPath, isDownload: true),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

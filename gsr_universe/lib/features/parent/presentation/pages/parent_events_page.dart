// Presentation Layer - Parent View Events Screen (Read-Only)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback_widgets.dart';
import '../cubit/parent_cubit.dart';
import '../cubit/parent_state.dart';

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';

class ParentEventsPage extends StatelessWidget {
  const ParentEventsPage({super.key});

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
        : (filePath != null && filePath.trim().isNotEmpty ? filePath.trim().split('/').last : 'Event_Attachment.pdf');

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
          _showPdfViewerModal(context, cleanName, bytes);
        }
      }
    } else {
      if (context.mounted) {
        AppNotifications.showError(context, "Unable to load event attachment PDF.");
      }
    }
  }

  void _viewAttachment(BuildContext context, String? fileName, String? filePath) {
    final cleanName = fileName ?? (filePath != null ? filePath.split('/').last : 'Event_Attachment.pdf');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.event, color: AppColors.parentPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Event Attachment",
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
                    const Icon(Icons.file_present, color: AppColors.parentPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        filePath ?? "Uploaded event document",
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
              label: Text("Open File", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentCubit, ParentState>(
      builder: (context, state) {
        final events = state.events;

        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          appBar: AppBar(
            title: Text(
              "Upcoming Events",
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
            child: events.isEmpty
                ? const Center(
                    child: EmptyStateWidget(
                      title: "No Events Found",
                      message: "School and class events published by faculty will appear here.",
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = events[index];
                      final String title = item['title'] ?? item['event_title'] ?? 'School Event';
                      final String description = item['description'] ?? '';
                      final String timeStr = item['event_time'] ?? item['time'] ?? 'All Day';
                      final String venue = item['venue'] ?? item['location'] ?? 'School Auditorium';
                      final String? attachmentName = item['attachment_name'] ?? item['file_name'];
                      final String? attachmentPath = item['attachment_path'] ?? item['file_path'];
                      final bool hasAttachment = (attachmentName != null && attachmentName.isNotEmpty) ||
                          (attachmentPath != null && attachmentPath.isNotEmpty);

                      String eventDateStr = 'N/A';
                      if (item['event_date'] != null) {
                        try {
                          eventDateStr = DateFormat('dd-MMM-yyyy').format(
                            DateTime.parse(item['event_date'].toString()),
                          );
                        } catch (_) {
                          eventDateStr = item['event_date'].toString();
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
                                    eventDateStr,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.parentPrimary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.event, color: AppColors.parentPrimary, size: 18),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textDark),
                            ),
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight, height: 1.4),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 14, color: AppColors.textLight),
                                const SizedBox(width: 4),
                                Text(
                                  timeStr,
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.location_on_outlined, size: 14, color: AppColors.textLight),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    venue,
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textLight),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (hasAttachment) ...[
                              const SizedBox(height: 14),
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
                                      label: Text("View Attachment", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () => _viewAttachment(context, attachmentName, attachmentPath),
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
                                      label: Text("Download Attachment", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
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

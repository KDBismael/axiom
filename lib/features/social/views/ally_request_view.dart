import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons/app_button.dart';
import '../controllers/allies_controller.dart';

class AllyRequestView extends StatefulWidget {
  const AllyRequestView({super.key});

  @override
  State<AllyRequestView> createState() => _AllyRequestViewState();
}

class _AllyRequestViewState extends State<AllyRequestView> {
  late final AlliesController _controller;
  late final String? _requestId;
  late final String _requesterName;
  bool _submitting = false;
  bool? _accepted;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<AlliesController>();
    final args = Get.arguments;
    final payload = args is Map
        ? Map<String, dynamic>.from(args)
        : const <String, dynamic>{};
    _requestId = payload['requestId'] as String?;
    final name = [
      payload['firstName'],
      payload['lastName'],
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    _requesterName = name.isEmpty ? 'Cette personne' : name;
  }

  Future<void> _respond({required bool accept}) async {
    final requestId = _requestId;
    if (requestId == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final success = await _controller.respondToRequest(
      requestId,
      accept: accept,
    );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (success) {
        _accepted = accept;
      } else {
        _error =
            _controller.errorMessage.value ??
            'Impossible de traiter cette demande.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'DEMANDE D’ALLIÉ',
                style: AppTypography.labelMd.copyWith(color: AppColors.outline),
              ),
              const SizedBox(height: 8),
              Text(
                'Une alliance vous attend.',
                style: AppTypography.displayLg.copyWith(
                  color: AppColors.primary,
                  fontSize: 40,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppRadii.structuralRadius,
                  border: Border.all(color: AppColors.outlineVariant15),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.surfaceBright,
                      child: Text(
                        _requesterName[0].toUpperCase(),
                        style: AppTypography.titleLg.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _requesterName,
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLg.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'souhaite devenir votre allié sur Ndeli.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_requestId == null)
                Text(
                  'Cette notification ne contient pas de demande valide.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.error),
                )
              else if (_accepted != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppRadii.interactiveRadius,
                  ),
                  child: Text(
                    _accepted!
                        ? 'Vous êtes maintenant alliés.'
                        : 'Demande refusée.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd.copyWith(
                      color: _accepted! ? AppColors.volt : AppColors.outline,
                    ),
                  ),
                )
              else ...[
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                AppButton(
                  label: 'ACCEPTER LA DEMANDE',
                  leadingIcon: Icons.check,
                  loading: _submitting,
                  onPressed: _submitting ? null : () => _respond(accept: true),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _submitting
                        ? null
                        : () => _respond(accept: false),
                    icon: const Icon(Icons.close),
                    label: const Text('REFUSER'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

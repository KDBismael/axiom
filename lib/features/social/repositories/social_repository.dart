import '../models/ally_invitation.dart';
import '../models/ally_validation_request.dart';

class SocialRepository {
  final List<AllyInvitation> _invitations = [
    const AllyInvitation(
      id: 'inv1',
      inviterName: 'Thomas V.',
      questTitle: '50 Jours de Code Sans Faille',
      roleQuote:
          'Votre rôle est de valider chaque jour l\'intégrité de leur exécution. Si ils '
          'échouent, les fonds engagés vous seront redistribués.',
      stakeAmount: 45000,
      durationDays: 50,
    ),
  ];

  final List<AllyValidationRequest> _validationRequests = [
    const AllyValidationRequest(
      id: 'val1',
      friendName: 'Sophie Valand',
      questTitle: '50 Pages par jour',
      proofType: ProofType.photo,
      evidence: 'Photo de la séance de lecture envoyée aujourd\'hui à 21h02.',
    ),
    const AllyValidationRequest(
      id: 'val2',
      friendName: 'Marc Lefebvre',
      questTitle: 'Méditation Matinale',
      proofType: ProofType.text,
      evidence:
          'Session de 20 minutes complétée à 06h15. Focus sur la respiration profonde. '
          'Calme intérieur atteint avant le début de la journée de travail.',
    ),
  ];

  Future<List<AllyInvitation>> fetchInvitations() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_invitations);
  }

  Future<AllyInvitation> respondToInvitation(String id, {required bool accepted}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _invitations.indexWhere((i) => i.id == id);
    if (index == -1) throw Exception('Invitation not found');
    final updated = _invitations[index].copyWith(
      status: accepted ? InvitationStatus.accepted : InvitationStatus.declined,
    );
    _invitations[index] = updated;
    return updated;
  }

  Future<List<AllyValidationRequest>> fetchValidationRequests() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_validationRequests);
  }

  Future<AllyValidationRequest> respondToValidation(String id, {required bool approved}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final index = _validationRequests.indexWhere((v) => v.id == id);
    if (index == -1) throw Exception('Validation request not found');
    final updated = _validationRequests[index].copyWith(
      status: approved ? ValidationRequestStatus.approved : ValidationRequestStatus.rejected,
    );
    _validationRequests[index] = updated;
    return updated;
  }
}

enum InvitationStatus { pending, accepted, declined }

class AllyInvitation {
  final String id;
  final String inviterName;
  final String questTitle;
  final String roleQuote;
  final double stakeAmount;
  final int durationDays;
  final InvitationStatus status;

  const AllyInvitation({
    required this.id,
    required this.inviterName,
    required this.questTitle,
    required this.roleQuote,
    required this.stakeAmount,
    required this.durationDays,
    this.status = InvitationStatus.pending,
  });

  AllyInvitation copyWith({InvitationStatus? status}) {
    return AllyInvitation(
      id: id,
      inviterName: inviterName,
      questTitle: questTitle,
      roleQuote: roleQuote,
      stakeAmount: stakeAmount,
      durationDays: durationDays,
      status: status ?? this.status,
    );
  }
}

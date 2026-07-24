import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:axiom/features/quests/models/check_in_model.dart';
import 'package:axiom/features/social/controllers/validations_controller.dart';
import 'package:axiom/features/social/models/ally_validation_request.dart';
import 'package:axiom/features/social/repositories/social_repository.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late MockSocialRepository mockRepository;
  late ValidationsController controller;

  AllyValidationRequest request({
    String id = 'val-1',
    ValidationDecisionStatus status = ValidationDecisionStatus.pending,
  }) {
    return AllyValidationRequest(
      id: id,
      questId: 'q-1',
      questTitle: 'Gym',
      evidenceId: 'ev-1',
      proofType: ProofType.text,
      textContent: 'Fait !',
      status: status,
    );
  }

  setUp(() {
    mockRepository = MockSocialRepository();
    controller = ValidationsController(mockRepository);
  });

  group('ValidationsController.loadValidations', () {
    test('populates validations on success', () async {
      when(() => mockRepository.fetchValidations(status: any(named: 'status')))
          .thenAnswer((_) async => [request()]);

      await controller.loadValidations();

      expect(controller.validations, hasLength(1));
    });
  });

  group('ValidationsController.decide', () {
    test('reloads validations after a decision', () async {
      when(() => mockRepository.decideValidation('val-1', approved: true))
          .thenAnswer((_) async {});
      when(() => mockRepository.fetchValidations(status: any(named: 'status')))
          .thenAnswer((_) async => [request(status: ValidationDecisionStatus.approved)]);

      await controller.decide('val-1', approved: true);

      verify(() => mockRepository.decideValidation('val-1', approved: true)).called(1);
      expect(controller.validations.single.status, ValidationDecisionStatus.approved);
    });

    test('surfaces the backend French error when another ally already decided', () async {
      when(() => mockRepository.decideValidation('val-1', approved: true))
          .thenThrow(SocialException('Cette demande a déjà été traitée'));

      await controller.decide('val-1', approved: true);

      expect(controller.errorMessage.value, 'Cette demande a déjà été traitée');
    });
  });

  group('ValidationsController pendingValidations', () {
    test('filters only pending status', () async {
      when(() => mockRepository.fetchValidations(status: any(named: 'status'))).thenAnswer(
        (_) async => [
          request(id: 'val-1', status: ValidationDecisionStatus.pending),
          request(id: 'val-2', status: ValidationDecisionStatus.cancelled),
        ],
      );

      await controller.loadValidations();

      expect(controller.pendingValidations, hasLength(1));
      expect(controller.pendingValidations.single.id, 'val-1');
    });
  });
}

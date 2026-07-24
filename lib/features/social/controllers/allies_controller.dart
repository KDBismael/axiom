import 'package:get/get.dart';
import '../models/ally.dart';
import '../models/ally_invitation.dart';
import '../models/ally_request.dart';
import '../models/user_search_result.dart';
import '../repositories/social_repository.dart';

class AlliesController extends GetxController {
  AlliesController(this._repository);

  final SocialRepository _repository;

  final allies = <Ally>[].obs;
  final invitations = <AllyInvitation>[].obs;
  final allyRequests = <AllyRequest>[].obs;
  final searchResults = <UserSearchResult>[].obs;

  final isLoading = false.obs;
  final isSearching = false.obs;
  final errorMessage = RxnString();
  final lastCreatedInvitation = Rxn<AllyInvitation>();

  List<AllyRequest> get incomingRequests =>
      allyRequests.where((r) => r.direction == AllyRequestDirection.incoming).toList();

  @override
  void onInit() {
    super.onInit();
    loadAllies();
    loadInvitations();
    loadAllyRequests();
  }

  Future<void> loadAllies() async {
    isLoading.value = true;
    try {
      allies.assignAll(await _repository.fetchAllies());
    } on SocialException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadInvitations() async {
    try {
      invitations.assignAll(await _repository.fetchInvitations());
    } on SocialException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> loadAllyRequests() async {
    try {
      allyRequests.assignAll(await _repository.fetchAllyRequests());
    } on SocialException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> createInvitation({String? inviteeContact}) async {
    errorMessage.value = null;
    try {
      final invitation = await _repository.createInvitation(
        inviteeContact: inviteeContact,
      );
      lastCreatedInvitation.value = invitation;
      invitations.add(invitation);
    } on SocialException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> redeemInvitation(String token) async {
    errorMessage.value = null;
    try {
      await _repository.redeemInvitation(token);
      await loadAllies();
    } on SocialException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> declineInvitation(String token) async {
    errorMessage.value = null;
    try {
      await _repository.declineInvitation(token);
    } on SocialException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> search(String query) async {
    if (query.trim().length < 2) {
      searchResults.clear();
      return;
    }
    isSearching.value = true;
    errorMessage.value = null;
    try {
      searchResults.assignAll(await _repository.searchUsers(query.trim()));
    } on SocialException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> sendRequest(String recipientId) async {
    errorMessage.value = null;
    try {
      await _repository.sendAllyRequest(recipientId);
    } on SocialException catch (e) {
      errorMessage.value = e.message;
    }
  }

  Future<void> respondToRequest(String id, {required bool accept}) async {
    errorMessage.value = null;
    try {
      await _repository.respondToAllyRequest(id, accept: accept);
      await loadAllyRequests();
      if (accept) await loadAllies();
    } on SocialException catch (e) {
      errorMessage.value = e.message;
    }
  }
}

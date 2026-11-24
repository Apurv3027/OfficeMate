import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/services/firebase_service.dart';
import '../../core/utils/balance_calculator.dart';
import '../models/group_member_model.dart';
import '../models/member_balance_model.dart';
import '../models/purchase_model.dart';
import '../models/settlement_model.dart';
import 'group_repository.dart';
import 'purchase_repository.dart';
import 'settlement_repository.dart';

class BalanceRepository {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  final GroupRepository _groupRepository;
  final PurchaseRepository _purchaseRepository;
  final SettlementRepository _settlementRepository;

  BalanceRepository({
    GroupRepository? groupRepository,
    PurchaseRepository? purchaseRepository,
    SettlementRepository? settlementRepository,
  })  : _groupRepository = groupRepository ?? GroupRepository(),
        _purchaseRepository = purchaseRepository ?? PurchaseRepository(),
        _settlementRepository = settlementRepository ?? SettlementRepository();

  String get currentUserId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<List<GroupMemberModel>> getGroupMembers(
    String groupId,
  ) async {
    final snapshot = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .get();

    return snapshot.docs
        .map((doc) => GroupMemberModel.fromJson(doc.data()))
        .toList();
  }

  Stream<List<MemberBalanceModel>> watchBalances(
    String groupId,
  ) {
    late StreamSubscription<List<PurchaseModel>> purchaseSubscription;
    late StreamSubscription<List<SettlementModel>> settlementSubscription;

    final controller = StreamController<List<MemberBalanceModel>>();

    List<PurchaseModel> purchases = [];
    List<SettlementModel> settlements = [];

    List<GroupMemberModel>? members;

    bool purchasesLoaded = false;
    bool settlementsLoaded = false;
    bool closed = false;

    void calculateAndEmit() {
      if (closed ||
          members == null ||
          !purchasesLoaded ||
          !settlementsLoaded) {
        return;
      }

      try {
        final balances = BalanceCalculator.calculate(
          members: members!,
          purchases: purchases,
          settlements: settlements,
        );

        controller.add(balances);
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
      }
    }

    Future<void> start() async {
      try {
        members = await getGroupMembers(groupId);

        if (closed) return;

        purchaseSubscription =
            _purchaseRepository.watchPurchases(groupId).listen(
          (data) {
            purchases = data;
            purchasesLoaded = true;
            calculateAndEmit();
          },
          onError: (error) {
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              return;
            }
            if (!closed) controller.addError(error);
          },
        );

        settlementSubscription =
            _settlementRepository.watchSettlements(groupId).listen(
          (data) {
            settlements = data;
            settlementsLoaded = true;
            calculateAndEmit();
          },
          onError: (error) {
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              return;
            }
            if (!closed) controller.addError(error);
          },
        );
      } catch (error, stackTrace) {
        if (!closed) {
          if (error is FirebaseException &&
              error.code == 'permission-denied') {
            return;
          }
          controller.addError(error, stackTrace);
        }
      }
    }

    controller.onListen = start;

    controller.onCancel = () async {
      closed = true;

      if (purchasesLoaded) {
        await purchaseSubscription.cancel();
      }

      if (settlementsLoaded) {
        await settlementSubscription.cancel();
      }
    };

    return controller.stream;
  }
}

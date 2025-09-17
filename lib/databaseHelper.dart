import 'ElectricityPaymentModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseHelper {
  final CollectionReference collection = FirebaseFirestore.instance.collection(ElectricityPaymentModel.CollectionName);

  // insert a new payment
  Future<DocumentReference> addPayment(ElectricityPaymentModel payment) async {
    return await collection.add(payment.toJson());
  }
  // update an existing payment
  Future<void> updatePayment(String id, ElectricityPaymentModel payment) async {
    return await collection.doc(id).update(payment.toJson());
  }
  // delete a payment
  Future<void> deletePayment(String id) async {
    return await collection.doc(id).delete();
  }
  // load all payments 
  Stream<QuerySnapshot> getStreamPayments() {
    return collection.snapshots();
  }
  
}

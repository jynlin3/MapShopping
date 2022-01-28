import 'package:cloud_firestore/cloud_firestore.dart';

const columnUserName = 'userName';

class AuthService {
  final CollectionReference userCollection =
  FirebaseFirestore.instance.collection('UserData');

  Future<String> signInWithName(String name) async{
    QuerySnapshot querySnapshot = await userCollection.where(columnUserName, isEqualTo: name).get();
    if (querySnapshot.docs.isNotEmpty){
      return querySnapshot.docs[0].id;
    }
    else{
      DocumentReference newUser = await userCollection.add({columnUserName: name});
      return newUser.id;
    }
  }
}
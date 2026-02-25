import 'user_model.dart';

class UserData {
  static List<UserModel> users = [
    UserModel(
      id: '1',
      name: 'Adele',
      email: 'adele@example.com',
      registrationDate: 'September 9, 2013',
      avatar: 'assets/adele.png',
    ),
    UserModel(
      id: '2',
      name: 'Arlene McCoy',
      email: 'arlene@example.com',
      registrationDate: 'August 2, 2013',
      avatar: 'assets/arlene.png',
    ),
    UserModel(
      id: '3',
      name: 'Cody Fisher',
      email: 'cody@example.com',
      registrationDate: 'September 24, 2017',
      avatar: 'assets/cody.png',
    ),
    UserModel(
      id: '4',
      name: 'Esther Howard',
      email: 'esther@example.com',
      registrationDate: 'December 29, 2012',
      avatar: 'assets/esther.png',
    ),
    UserModel(
      id: '5',
      name: 'Ronald Richards',
      email: 'ronald@example.com',
      registrationDate: 'May 20, 2015',
      avatar: 'assets/ronald.png',
    ),
  ];
}

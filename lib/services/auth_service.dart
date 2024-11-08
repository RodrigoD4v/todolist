import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // O usuário cancelou o login
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('ID Token: ${googleAuth.idToken}');
      
      // Enviar o idToken para o backend
      await sendIdTokenToServer(googleAuth.idToken);

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (error) {
      print('Erro no signInWithGoogle: $error');
      return null;
    }
  }

  Future<void> sendIdTokenToServer(String? idToken) async {
    if (idToken == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.33:8080/auth/login'), // Substitua pela URL pelo ip + porta local em que está rodando a Api
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'idToken': idToken,
        }),
      );

      if (response.statusCode == 200) {
        print('Token enviado com sucesso!');
        // Lógica adicional após enviar o token com sucesso
      } else {
        print('Erro ao enviar o token: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Erro na requisição ao servidor: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}

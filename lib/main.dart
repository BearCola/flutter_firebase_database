import 'package:firebase_sample/model/board.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn();

final FirebaseDatabase dababase = FirebaseDatabase.instance;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _imageUrl;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Board'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlatButton(
              child: Text('google-sign'),
              onPressed: () => _googleSignin(),
              color: Colors.red,
            ),
            FlatButton(
              child: Text('Signin with Email'),
              onPressed: () => _signInWithEmail(),
              color: Colors.orange,
            ),
            FlatButton(
              child: Text('Create Account'),
              onPressed: () => _createUser(),
              color: Colors.purple,
            ),
            FlatButton(
              child: Text('Signout'),
              onPressed: () => _logout(),
              color: Colors.redAccent,
            ),
            FlatButton(
              child: Text('Database'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              },
              color: Colors.blueAccent,
            ),
            Image.network(_imageUrl == null || _imageUrl.isEmpty
                ? 'https://avatars1.githubusercontent.com/u/27527229?s=460&v=4'
                : _imageUrl)
          ],
        ),
      ),
    );
  }

  Future<FirebaseUser> _googleSignin() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    print("TOKEN: ${googleAuth.accessToken}, ID:${googleAuth.idToken}");

    final FirebaseUser user = await _auth.signInWithCredential(credential);
    print("signed in " + user.displayName);
    print("signed in " + user.toString());
    print('User is: ${user.photoUrl}');
    setState(() {
      _imageUrl = user.photoUrl;
    });
    return user;
  }

  Future _createUser() async {
    FirebaseUser user = await _auth
        .createUserWithEmailAndPassword(
            email: "secretis1013@naver.com", password: "test12345")
        .then((user) {
      print("User created ${user}");
      print("Email: ${user.email}");
    });
  }

  _logout() {
    setState(() {
      _imageUrl = null;
      _googleSignIn.signOut();
    });
  }

  _signInWithEmail() {
    _auth
        .signInWithEmailAndPassword(
            email: 'diablo1031@naver.com', password: 'test12345')
        .catchError((error) {
      print('Something went wrong!');
    }).then((newUser) {
      print('User signed in: ${newUser.email}');
    });
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Board> boardMessages = List();
  Board board;
  final FirebaseDatabase database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  DatabaseReference databaseReference;

  @override
  void initState() {
    super.initState();
    board = Board('', '');
    databaseReference = database.reference().child('community_board');
    databaseReference.onChildAdded.listen(_onEntryAdded);
    databaseReference.onChildChanged.listen(_onEntryChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            flex: 1,
            child: Center(
              child: Form(
                key: formKey,
                child: Flex(
                  direction: Axis.vertical,
                  children: <Widget>[
                    ListTile(
                      leading: Icon(Icons.subject),
                      title: TextFormField(
                        initialValue: '',
                        onSaved: (val) => board.subject = val,
                        validator: (val) => val == "" ? val : null,
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.message),
                      title: TextFormField(
                        initialValue: '',
                        onSaved: (val) => board.body = val,
                        validator: (val) => val == '' ? val : null,
                      ),
                    ),
                    FlatButton(
                      child: Text('Post'),
                      color: Colors.redAccent,
                      onPressed: () {
                        handleSubmit();
                      },
                    ),
                    Flexible(
                      child: FirebaseAnimatedList(
                        query: databaseReference,
                        itemBuilder: (
                          _,
                          DataSnapshot snapshot,
                          Animation<double> animation,
                          int index,
                        ) {
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red,
                              ),
                              title: Text(boardMessages[index].subject),
                              subtitle: Text(boardMessages[index].body),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onEntryAdded(Event event) {
    setState(() {
      boardMessages.add(Board.fromSnapshot(event.snapshot));
    });
  }

  void handleSubmit() {
    final FormState form = formKey.currentState;
    if (form.validate()) {
      form.save();
      form.reset();

      databaseReference.push().set(board.toJson());
    }
  }

  void _onEntryChanged(Event event) {
    var oldEntry = boardMessages.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    setState(() {
      boardMessages[boardMessages.indexOf(oldEntry)] =
          Board.fromSnapshot(event.snapshot);
    });
  }
}

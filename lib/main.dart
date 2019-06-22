import 'package:firebase_sample/model/board.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

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
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
//  int _counter = 0;
//
//  void _incrementCounter() {
//    dababase
//        .reference()
//        .child('message')
//        .set({'firstname': 'ColaBear', 'lastname': 'BearCola', 'Age': 45});
//    setState(() {
//      dababase
//          .reference()
//          .child('message')
//          .once()
//          .then((DataSnapshot snapshot) {
//        Map<dynamic, dynamic> data = snapshot.value;
//
//        print('Values from db: ${snapshot.value}');
//      });
//    });
//  }

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
    databaseReference.onChildChanged.listen(_onEntryChanged)
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
        )
//      floatingActionButton: FloatingActionButton(
//        onPressed: _incrementCounter,
//        tooltip: 'Increment',
//        child: Icon(Icons.add),
//      ),
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

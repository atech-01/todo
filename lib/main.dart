// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todo/alert/alert.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

TextEditingController todoController = TextEditingController();

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> todoList = [];

  @override
  void initState() {
    super.initState();
    getTodo();
  }

  Future addTodo(BuildContext context) async {
    var url = Uri.parse("http://192.168.81.64/todo/addTodo.php");

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"todo": todoController.text}),
    );

    debugPrint(response.body);
    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      todoController.text = "";
      // debugPrint(responseBody['message']);
      CustomDialogs.showSuccessDialog(
        context,
        message: responseBody['message'],
      );
      await getTodo();
    }
  }

  Future getTodo() async {
    var url = Uri.parse("http://192.168.81.64/todo/getTodo.php");

    var response = await http.get(url);

    var responseBody = jsonDecode(response.body);

    debugPrint(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      debugPrint("Hello getTodo");
      List<dynamic> list = responseBody['data'];
      setState(() {
        todoList =
            list
                .map<Map<String, dynamic>>(
                  (todo) => {'id': todo['id'], 'todo': todo['todo']},
                )
                .toList();
      });
    }
  }

  Future deleteTodo(String id) async {
    debugPrint("Clicked");
    var url = Uri.parse("http://192.168.81.64/todo/deleteTodo.php");

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'id': id}),
    );

    debugPrint(response.body);

    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      CustomDialogs.showSuccessDialog(
        context,
        message: responseBody['message'],
      );
      getTodo();
    }
  }

  Future editTodo(BuildContext context, String id, String newTodo) async {
    // debugPrint("Clicked");
    var url = Uri.parse("http://192.168.81.64/todo/editTodo.php");

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'id': id, 'newTodo': newTodo}),
    );

    debugPrint(response.body);

    var responseBody = jsonDecode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == true) {
      CustomDialogs.showSuccessDialog(
        context,
        message: responseBody['message'],
      );
      getTodo();
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: SizedBox(
                  width: size.width * 0.7,
                  height: 60,
                  child: TextFormField(
                    controller: todoController,

                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Enter your todo",
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.only(right: 10),
                child: Container(
                  alignment: Alignment.center,
                  height: 60,
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () {
                      addTodo(context);
                    },
                    child: Text("Add", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
          Container(
            // decoration: Box,
          ),
          todoList.isEmpty
              ? Container(
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                child: Center(child: Text("Nothing has been added")),
              )
              : Expanded(
                child: ListView.builder(
                  itemCount: todoList.length,
                  itemBuilder: (context, index) {
                    return todoItem(
                      context,
                      todoList[index]['id'],
                      todoList[index]['todo'],
                      (id) => deleteTodo(id),
                      (id, newTodo) => editTodo(context, id, newTodo),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}

todoItem(
  BuildContext context,
  String id,
  String todoText,
  void Function(String id) onDelete,
  void Function(String id, String newTodo) onEdit,
) {
  return Card(
    color: Colors.white,
    margin: EdgeInsets.only(top: 20, right: 10, left: 10, bottom: 10),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          subtitle: Text(
            todoText,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => onDelete(id),
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                TextEditingController editController = TextEditingController(
                  text: todoText,
                );

                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: Text("Edit Todo"),
                        content: TextField(controller: editController),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onEdit(id, editController.text);
                            },
                            child: Text("Save"),
                          ),
                        ],
                      ),
                );
              },
              child: Text("Edit", style: TextStyle(color: Colors.blueAccent)),
            ),
          ],
        ),
      ],
    ),
  );
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatScreen(
        channel:
          WebSocketChannel.connect(Uri.parse('wss://echo.websocket.org')),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  String _name = 'Brian Yetter';

  ChatMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(child: Text(_name[0])),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(_name + " User",
                    style: Theme.of(context).textTheme.headline6),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: SelectableText(text),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final WebSocketChannel channel;

  ChatScreen({required this.channel});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Chat Box', textAlign: TextAlign.center)),
        elevation: Theme.of(context).platform == TargetPlatform.iOS ? 0.0 : 4.0,
        // elevation gives shadow size
      ),
      body: Column(
        children: [
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.black,
          ),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onChanged: (String text) {
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                onSubmitted: _isComposing ? _handleSubmitted : null,
                decoration:
                    //InputDecoration.collapsed(hintText: 'Send a message'),
                    InputDecoration(
                  //contentPadding: EdgeInsets.symmetric(vertical: 0),
                  hintText: "Join the chat!",
                  border: InputBorder.none,
                ),
                focusNode: _focusNode,
                style: new TextStyle(
                  fontSize: 30,
                ),
              ),
            ),
            Container(
                margin: EdgeInsets.symmetric(horizontal: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? CupertinoButton(
                        child: Text('Send'),
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_textController.text)
                            : null,
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_textController.text)
                            : null,
                      ))
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    Stream stream = widget.channel.stream;
    stream.listen((msg) {
      ChatMessage message = ChatMessage(
        text: msg,
      );
      setState(() {
        _messages.insert(0, message);
      });
    });
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _isComposing = false;
    });

    widget.channel.sink.add(text);

    // make sure we still have focus post submit
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }
}

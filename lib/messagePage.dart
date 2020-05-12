import 'package:flutter/material.dart';
import 'package:sms/sms.dart';
import 'package:timeago/timeago.dart' as timeago;

class MessagePage extends StatefulWidget {
  final sender;
  final threadId;
  final name;

  const MessagePage({Key key, this.sender, this.threadId, this.name}) : super(key: key);

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  SmsQuery query = new SmsQuery();

  Future<List<SmsMessage>> getMessages() async {
    List<SmsMessage> message = await query.querySms(
      threadId: this.widget.threadId,
      kinds: [SmsQueryKind.Inbox, SmsQueryKind.Sent],
    );
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(this.widget.name)),
        body: Stack(
          children: <Widget>[
            _messageBuilder()
          ],
        ));
  }

  Widget _messageBuilder() {
    return Positioned(
      
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        color: Colors.black,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Builder(builder: (BuildContext context) {
          return FutureBuilder<List<SmsMessage>>(
            future: getMessages(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.none &&
                  snapshot.data == null) {
                print(snapshot.data);
                return Container(
                  child: Text('the data is ${snapshot.data}'),
                );
              } else {
                return snapshot.hasData
                    ? ListView.builder(
                        itemBuilder: (context, index) {
                          return snapshot.data.isNotEmpty
                              ? snapshot.data[index].kind == SmsMessageKind.Sent
                                  ? _textMessageBubble(
                                      true,
                                      snapshot.data[index].body,
                                      snapshot.data[index].date,
                                      snapshot.data[index].onStateChanged)
                                  : _textMessageBubble(
                                      false,
                                      snapshot.data[index].body,
                                      snapshot.data[index].date,
                                      snapshot.data[index].onStateChanged)
                              : Center(
                                  child: Text('no messages'),
                                );
                        },
                        itemCount: snapshot.data.length == null
                            ? 1
                            : snapshot.data.length,
                      )
                    : CircularProgressIndicator();
              }
            },
          );
        }),
      ),
    );
  }

  Widget _textMessageBubble(bool isByMe, String _message, DateTime _timestamp, Stream<SmsMessageState> smsMessageState) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      alignment: isByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
                bottomLeft: isByMe ? Radius.circular(30) : Radius.circular(0),
                bottomRight:
                    isByMe ? Radius.circular(0) : Radius.circular(30))),
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.08 +
                    (_message.length / 20 * 5.0),
                maxWidth: MediaQuery.of(context).size.width * 2 / 3),
            child: SingleChildScrollView(
                          child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _message,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.w500),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 0.0),
                    child: Text(
                      timeago.format(_timestamp),
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(right: 0.0),
                  //   child: SmsMessageState.Sent == false ? Icon(Icons.done) : Icon(Icons.error),
                  // ),
                ],
              ),
            )),
      ),
    );
  }
}

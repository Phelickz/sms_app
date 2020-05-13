import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:sms/contact.dart';
import 'package:sms/sms.dart';

import 'received.dart';
import 'send.dart';
import 'sent.dart';



class Conversation extends StatefulWidget {
  Conversation(this.thread, this.userProfile) : super();

  final SmsThread thread;
  final UserProfile userProfile;

  @override
  State<Conversation> createState() => new _ConversationState();
}

class _ConversationState extends State<Conversation> {
  final SmsReceiver _receiver = new SmsReceiver();

  @override
  void initState() {
    _receiver.onSmsReceived.listen((sms) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('building conversation');
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(
            widget.thread.contact.fullName ?? widget.thread.contact.address),
        // backgroundColor: ContactColor.getColor(widget.thread.contact.fullName),
      ),
      body: new Column(
          children: <Widget>[
            new Expanded(
      child: SizedBox(
        height: 500,
        width: 200,
        child: new Messages(widget.thread.messages, this.widget.thread, this.widget.userProfile)),
      
            ),
            Container(
      height: 100,
      child: new FormSend(
        widget.thread,
        onMessageSent: _onMessageSent,
      ),
            ),
          ],
        ),
    );
  }

  void _onMessageSent(SmsMessage message) {
    setState(() {
      widget.thread.addNewMessage(message);
    });
  }
}

// class ConversationStore extends InheritedWidget {
//   const ConversationStore(this.userProfile, this.thread, {Widget child})
//       : super(child: child);

//   final UserProfile userProfile;
//   final SmsThread thread;

//   static ConversationStore of(BuildContext context) {
//     return context.dependOnInheritedWidgetOfExactType().child
//         as ConversationStore;
//   }

//   @override
//   bool updateShouldNotify(InheritedWidget oldWidget) {
//     return true;
//   }
// }

class Messages extends StatelessWidget {
  final List<SmsMessage> messages;
  final SmsThread thread;
  final UserProfile userProfile;
  Messages(this.messages, this.thread, this.userProfile);

  @override
  Widget build(BuildContext context) {
    final groups = MessageGroupService.of(context).groupByDate(messages);
    return new ListView.builder(
        reverse: true,
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return new MessageGroup(groups[index], thread, userProfile);
        });
  }
}

class MessageGroup extends StatelessWidget {
  final Group group;
  final SmsThread thread;
  final UserProfile userProfile;
  MessageGroup(this.group, this.thread, this.userProfile) : super();

  @override
  Widget build(BuildContext context) {
    // final userProfile = ConversationStore.of(context).userProfile;
    // final thread = ConversationStore.of(context).thread;

    List<Widget> widgets = <Widget>[
      new Container(
        child: new Text(_formatDatetime(group.messages[0], context)),
        margin: new EdgeInsets.only(top: 25.0),
      )
    ];

    for (int i = 0; i < group.messages.length; i++) {
      if (group.messages[i].kind == SmsMessageKind.Sent) {
        widgets.add(
            new SentMessage(group.messages[i], _isCompactMode(i), userProfile));
      } else {
        widgets.add(new ReceivedMessage(
            group.messages[i], _isCompactMode(i), thread.contact));
      }
    }

    return new Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: new Container(
        child: new Column(
          children: widgets,
        ),
      ),
    );
  }

  String _formatDatetime(SmsMessage message, BuildContext context) {
    return MaterialLocalizations.of(context).formatFullDate(message.date);
  }

  bool _isCompactMode(int i) {
    return i > 0 && group.messages[i].kind == group.messages[i - 1].kind;
  }
}



class MessageGroupService {
  static MessageGroupService of(BuildContext context) {
    return new MessageGroupService._private(context);
  }

  MessageGroupService._private(this.context);

  final BuildContext context;

  List<Group> groupByDate(List<SmsMessage> messages) {
    final groups = new _GroupCollection();
    messages.forEach((message) {
      String groupLabel =
          MaterialLocalizations.of(context).formatFullDate(message.date);
      if (groups.contains(groupLabel)) {
        groups.get(groupLabel).addMessage(message);
      } else {
        groups.add(new Group(groupLabel, messages: [message]));
      }
    });
    return groups.groups;
  }
}

class Group {
  String label;
  List<SmsMessage> messages;

  Group(this.label, {this.messages = const <SmsMessage>[]});

  void addMessage(SmsMessage message) {
    messages.insert(0, message);
  }
}

class _GroupCollection {
  List<Group> groups = <Group>[];

  bool contains(String label) {
    return groups.any((group) {
      return group.label == label;
    });
  }

  Group get(String label) {
    return groups.singleWhere((group) {
      return group.label == label;
    });
  }

  void add(Group group) {
    groups.add(group);
  }
}
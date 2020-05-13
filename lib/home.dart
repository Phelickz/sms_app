import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sms/contact.dart';
import 'package:sms/sms.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'contacts.dart';
import 'conversation.dart';
import 'messagePage.dart';
import 'sent.dart';


class Threads extends StatefulWidget {
  @override
  State<Threads> createState() => new _ThreadsState();
}

class _ThreadsState extends State<Threads> with TickerProviderStateMixin {
  bool _loading = true;
  List<SmsThread> _threads;
  UserProfile _userProfile;
  final SmsQuery _query = new SmsQuery();
  final SmsReceiver _receiver = new SmsReceiver();
  final UserProfileProvider _userProfileProvider = new UserProfileProvider();
  final SmsSender _smsSender = new SmsSender();

  // Animation
  AnimationController opacityController;

  @override
  void initState() {
    super.initState();
    _receiver.onSmsReceived.listen(_onSmsReceived);
    _userProfileProvider.getUserProfile().then(_onUserProfileLoaded);
    _query.getAllThreads.then(_onThreadsLoaded);
    _smsSender.onSmsDelivered.listen(_onSmsDelivered);

    // Animation
    opacityController = new AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this, value: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('SMS Conversations'),
      ),
      body: _getThreadsWidgets(),
      floatingActionButton: new FloatingActionButton(
        onPressed: () {},
        child: new Icon(Icons.add),
      ),
    );
  }

  Widget _getThreadsWidgets() {
    if (_loading) {
      return new Center(
        child: new CircularProgressIndicator(),
      );
    } else {
      return new FadeTransition(
        opacity: opacityController,
        child: new ListView.builder(
            itemCount: _threads.length,
            itemBuilder: (context, index) {
              return new Thread(_threads[index], _userProfile);
            }),
      );
    }
  }

  void _onSmsReceived(SmsMessage sms) async {
    var thread = _threads.singleWhere((thread) {
      return thread.id == sms.threadId;
    }, orElse: () {
      var thread = new SmsThread(sms.threadId);
      _threads.insert(0, thread);
      return thread;
    });

    thread.addNewMessage(sms);
    await thread.findContact();

    int index = _threads.indexOf(thread);
    if (index != 0) {
      _threads.removeAt(index);
      _threads.insert(0, thread);
    }

    setState(() {});
  }

  void _onThreadsLoaded(List<SmsThread> threads) {
    _threads = threads;
    _checkIfLoadCompleted();
  }

  void _onUserProfileLoaded(UserProfile userProfile) {
    _userProfile = userProfile;
    _checkIfLoadCompleted();
  }

  void _checkIfLoadCompleted() {
    if (_threads != null && _userProfile != null) {
      setState(() {
        _loading = false;
        opacityController.animateTo(1.0, curve: Curves.easeIn);
      });
    }
  }

  void _onSmsDelivered(SmsMessage sms) async {
    final contacts = new ContactQuery();
    Contact contact = await contacts.queryContact(sms.address);
    final snackBar = new SnackBar(
        content: new Text('Message to ${contact.fullName} delivered'));
    Scaffold.of(context).showSnackBar(snackBar);
  }
}





class Badge extends StatelessWidget {
  Badge(this.messages) : super();

  final List<SmsMessage> messages;

  @override
  Widget build(BuildContext context) {
    if (_countUnreadMessages() == 0) {
      return new Container(
          // color: Colors.red,
          );
    }

    return SizedBox(
      child: new Container(
        width: 10,
        padding: const EdgeInsets.all(8.0),
        decoration:
            new ShapeDecoration(shape: new CircleBorder(), color: Colors.red),
        child: new Text(_countUnreadMessages().toString(),
            style: new TextStyle(color: Colors.white)),
      ),
    );
  }

  int _countUnreadMessages() {
    return messages
        .where((msg) => msg.kind == SmsMessageKind.Received && !msg.isRead)
        .length;
  }
}


class Thread extends StatelessWidget {
  Thread(SmsThread thread, UserProfile userProfile)
      : thread = thread,
        userProfile = userProfile,
        super(key: new ObjectKey(thread));

  final SmsThread thread;
  final UserProfile userProfile;

  @override
  Widget build(BuildContext context) {
    return new ListTile(
      dense: true,
      leading: new Avatar(thread.contact.thumbnail, thread.contact.fullName),
      title: new Text(thread.contact.fullName ?? thread.contact.address),
      subtitle: new Text(
        thread.messages.first.body.trim(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: SizedBox(
        width: 40,
        height: 40,
        child: new Badge(thread.messages)),
      onTap: () => _showConversation(context),
    );
  }

  void _showConversation(BuildContext context) {
    Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) => new Conversation(thread, userProfile)));
  }}
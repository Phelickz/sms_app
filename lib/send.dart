import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:sms/contact.dart';
import 'package:sms/sms.dart';
// import '../sim/sim_bloc_provider.dart';

typedef void MessageSentCallback(SmsMessage message);

class FormSend extends StatelessWidget {
  FormSend(this.thread, {this.onMessageSent});

  final SmsThread thread;
  final MessageSentCallback onMessageSent;
  final TextEditingController _textField = new TextEditingController();
  final SmsSender _sender = new SmsSender();

  @override
  Widget build(BuildContext context) {
    final simCards = SimCardsBlocProvider.of(context);
    return new Material(
      elevation: 4.0,
      child: new Row(
        children: [
          new Expanded(
            child: new Container(
              child: new TextField(
                controller: _textField,
                decoration: new InputDecoration(
                  border: InputBorder.none,
                  labelStyle: new TextStyle(fontSize: 16.0),
                  hintText: "Send message:",
                ),
              ),
              padding: new EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8.0),
            ),
          ),
          new IconButton(
              icon: new StreamBuilder<SimCard>(
                  stream: simCards.onSimCardChanged ?? '',
                  initialData: simCards.selectedSimCard ?? '',
                  builder: (context, snapshot) {
                    return snapshot.hasData ? new Row(
                      children: [
                        new Icon(
                          Icons.sim_card,
                          color: snapshot.data.state == SimCardState.Ready
                              ? Colors.blue
                              : Colors.grey
                        ),
                        new Text(snapshot.data.slot.toString(),
                          style: new TextStyle(color: snapshot.data.state == SimCardState.Ready
                              ? Colors.black
                              : Colors.grey
                          ),
                        ),
                      ],
                    ) : Container();
                  }),
              onPressed: () {
                SimCardsBlocProvider.of(context).toggleSelectedSim();
              }),
          new IconButton(
            icon: new Icon(Icons.send),
            onPressed: () {
              _sendMessage(context);
            },
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) async {
    SmsMessage message =
        new SmsMessage(thread.address, _textField.text, threadId: thread.id);
    message.onStateChanged.listen((SmsMessageState state) {
      if (state == SmsMessageState.Delivered) {
        print('Message delivered to ${message.address}');
        _notifyDelivery(message, context);
      }
      if (state == SmsMessageState.Sent) {
        print('Message sent to ${message.address}');
      }
    });

    final simCard = SimCardsBlocProvider.of(context).selectedSimCard;
    await _sender.sendSms(message, simCard: simCard);
    _textField.clear();
    onMessageSent(message);
  }

  void _notifyDelivery(SmsMessage message, BuildContext context) async {
    final contacts = new ContactQuery();
    Contact contact = await contacts.queryContact(message.address);
    final snackBar = new SnackBar(
        content: new Text('Message to ${contact.fullName} delivered'));
    Scaffold.of(context).showSnackBar(snackBar);
  }
}

class SimCardsBlocProvider extends InheritedWidget {
  SimCardsBlocProvider({this.simCardBloc, @required Widget child})
      : assert(child != null),
        super(child: child);

  final SimCardsBloc simCardBloc;

  static SimCardsBloc of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<SimCardsBlocProvider>();
    // final provider = context.inheritFromWidgetOfExactType(SimCardsBlocProvider);
    if (provider != null) {
      return (provider as SimCardsBlocProvider).simCardBloc;
    }

    return null;
  }

  @override
  bool updateShouldNotify(SimCardsBlocProvider old) {
    return simCardBloc != old.simCardBloc;
  }
}


class SimCardsBloc {
  SimCardsBloc() {
    _onSimCardChanged = _streamController.stream.asBroadcastStream();
  }

  final _simCardsProvider = new SimCardsProvider();
  final _streamController = new StreamController<SimCard>();
  Stream<SimCard> _onSimCardChanged;
  List<SimCard> _simCards;
  SimCard _selectedSimCard;

  Stream<SimCard> get onSimCardChanged => _onSimCardChanged ?? '';

  SimCard get selectedSimCard => _selectedSimCard;

  void loadSimCards() async {
    _simCards = await _simCardsProvider.getSimCards();
    _simCards.forEach((sim) {
      if (sim.state == SimCardState.Ready) {
        this.selectSimCard(sim);
      }
    });
  }

  void toggleSelectedSim() async {
    if (_simCards == null) {
      _simCards = await _simCardsProvider.getSimCards();
    }

    _selectNextSimCard();
    _streamController.add(_selectedSimCard);
  }

  SimCard _selectNextSimCard() {
    if (_selectedSimCard == null) {
      _selectedSimCard = _simCards[0];
      return _selectedSimCard;
    }

    for (var i = 0; i < _simCards.length; i++) {
      if (_simCards[i].imei == _selectedSimCard.imei) {
        if (i + 1 < _simCards.length) {
          _selectedSimCard = _simCards[i + 1];
        } else {
          _selectedSimCard = _simCards[0];
        }
        break;
      }
    }

    return _selectedSimCard;
  }

  void selectSimCard(SimCard sim) {
    _selectedSimCard = sim;
    _streamController.add(_selectedSimCard);
  }
}
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sms/contact.dart';
import 'package:sms/sms.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'contacts.dart';
import 'messagePage.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  SmsQuery query = new SmsQuery();
  ContactQuery _query = new ContactQuery();

  List<Contact> contacts =[];
  List<SmsMessage> messages;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  
    // getAllSms();
  }

  Future<List<SmsMessage>> getAllSms() async {
    List<SmsMessage> message = await query.getAllSms;
    for(int i =0; i < message.length; i++){
      Contact oneContact = await _query.queryContact(message[i].address);
      // print(oneContact.photo.toString());
      contacts.add(oneContact);
    }
    setState(() {
      messages = message;
    });
    // print(message);
    
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages')
      ),
      body: FutureBuilder<List<SmsMessage>>(
        future: getAllSms(),
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
                      // Uint8List fullSize = contacts[index].photo.bytes;
                      // Uint8List thumbnail = contacts[index].thumbnail.bytes;

                      return snapshot.data.isNotEmpty
                          ? InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => MessagePage(
                                              sender:
                                                  snapshot.data[index].sender,
                                              threadId: snapshot.data[index].threadId,
                                              name: contacts[index].fullName,
                                            )));
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  // backgroundImage: MemoryImage(fullSize),
                                ),
                                title: Text(contacts[index].fullName),
                                subtitle: Text(snapshot.data[index].body),
                                trailing: Text(
                                    timeago.format(snapshot.data[index].date)),
                              ),
                            )
                          : Center(
                              child: Text('no messages'),
                            );
                    },
                    itemCount:
                        snapshot.data.length == null ? 1 : snapshot.data.length,
                  )
                : CircularProgressIndicator();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => Contacts()));
        },),
    );
  }
}

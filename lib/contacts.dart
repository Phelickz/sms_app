// import 'dart:html';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
// import 'package:sms/contact.dart';
import 'package:contacts_service/contacts_service.dart';

import 'messagePage.dart';

class Contacts extends StatefulWidget {
  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  // final Iterable<Item> _items;
  String number;
  List<String> numbers;
  @override
  void initState() {
  
    super.initState();
    getContacts();
    _askPermissions();
  }

  Future<void> _askPermissions() async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus != PermissionStatus.granted) {
      _handleInvalidPermissions(permissionStatus);
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await Permission.contacts.request();
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      Map<Permission, PermissionStatus> permissionStatus =
          await [Permission.contacts].request();
      return permissionStatus[Permission.contacts] ??
          PermissionStatus.undetermined;
    } else {
      return permission;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      throw PlatformException(
          code: "PERMISSION_DENIED",
          message: "Access to location data denied",
          details: null);
    } else if (permissionStatus == PermissionStatus.undetermined) {
      throw PlatformException(
          code: "PERMISSION_DISABLED",
          message: "Location data is not available on device",
          details: null);
    }
  }

  Future<List<Contact>> getContacts() async {
    Iterable<Contact> contacts =
        await ContactsService.getContacts(withThumbnails: false);
    // for (final contact in contacts) {
    //   ContactsService.getAvatar(contact).then((avatar) {
    //     if (avatar == null) return;
    //     setState(() {
    //       contact.avatar = avatar;
    //     });
    //   }).catchError((e) {
    //     print(e.message);
    //   });
    // }
    return contacts.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contacts')),
      body: FutureBuilder<List<Contact>>(
        future: getContacts(),
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
                      var _contact = snapshot.data[index];

                      // Uint8List fullSize = contacts[index].photo.bytes;
                      // Uint8List thumbnail = contacts[index].thumbnail.bytes;

                      return snapshot.data.isNotEmpty
                          ? InkWell(
                              // onTap: () {
                              //   Navigator.push(
                              //       context,
                              //       MaterialPageRoute(
                              //           builder: (context) => MessagePage()));
                              // },
                              child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(_contact.initials()),
                                    //backgroundImage: MemoryImage(fullSize),
                                  ),
                                  title: Text(snapshot.data[index].displayName),
                                  // subtitle: Text(numbers[index] ?? ''),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: _contact.phones
                                        .map((i) => Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 0.0),
                                              child: InkWell(
                                                  onTap: () {
                                                    print(i.value);
                                                    Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                            builder: (context) =>
                                                                MessagePage(sender: i.value, name: _contact.displayName ?? '')));
                                                  },
                                                  child: Text(i.value ?? '')),
                                            ))
                                        .toList(),
                                  )
                                  // trailing: Text(
                                  //     timeago.format(snapshot.data[index].date)),
                                  ),
                            )
                          : Center(
                              child: Text('no contacts'),
                            );
                    },
                    itemCount:
                        snapshot.data.length == null ? 1 : snapshot.data.length,
                  )
                : Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

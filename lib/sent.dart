import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sms/contact.dart';
import 'package:sms/sms.dart';

import 'package:flutter/rendering.dart';

class SentMessage extends Message {
  SentMessage(SmsMessage message, bool compactMode, this.userProfile)
      : super(message,
            compactMode: compactMode,
            backgroundColor: Colors.lightBlue[100],
            arrowDirection: ArrowDirection.Right);

  final UserProfile userProfile;

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new Stack(
        children: [
          new Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new Expanded(
                child: new Container(
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      new Text(message.body.trim()),
                      new Align(
                        child: new Padding(
                          padding: new EdgeInsets.only(top: 5.0),
                          child: new Text(
                            time.format(context),
                            style: new TextStyle(color: Colors.grey[500]),
                          ),
                        ),
                        alignment: Alignment.centerRight,
                      ),
                    ],
                  ),
                  margin: new EdgeInsets.only(left: 48.0),
                  padding: new EdgeInsets.all(10.0),
                  decoration: new BoxDecoration(
                    borderRadius: new BorderRadius.circular(10.0),
                    color: this.backgroundColor
                  ),
                ),
              ),
              new Container(
                child:
                    createAvatar(userProfile.thumbnail, userProfile.fullName),
                margin: new EdgeInsets.only(left: 8.0, top: 8.0),
              ),
            ],
          ),
          new Container(
            width: double.infinity,
            child: createArrow(),
          ),
        ],
      ),
      margin: new EdgeInsets.only(
          top: compactMode ? 2.0 : 10.0, bottom: 0.0, left: 15.0, right: 15.0),
    );
  }
}

enum ArrowDirection { Left, Right }

class ArrowPainter extends CustomPainter {
  final Color color;
  final ArrowDirection direction;
  final _paint = new Paint();

  ArrowPainter({this.color, this.direction}) {
    _paint.color = this.color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    Path path = new Path();

    if (this.direction == ArrowDirection.Left) {
      canvas.translate(56.0, 0.0);
      path.lineTo(-15.0, 0.0);
    } else {
      canvas.translate(size.width - 56.0, 0.0);
      path.lineTo(15.0, 0.0);
    }

    path.lineTo(0.0, 20.0);
    path.lineTo(0.0, 0.0);
    canvas.drawPath(path, _paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

abstract class Message extends StatelessWidget {
  Message(this.message,
      {this.compactMode = false, this.backgroundColor, this.arrowDirection})
      : super();

  final SmsMessage message;
  final bool compactMode;
  final Color backgroundColor;
  final ArrowDirection arrowDirection;

  bool get sent =>
      message.kind == SmsMessageKind.Sent ||
      message.state == SmsMessageState.Sent ||
      message.state == SmsMessageState.Sending ||
      message.state == SmsMessageState.Delivered;

  get time {
    return new TimeOfDay(hour: message.date.hour, minute: message.date.minute);
  }

  createAvatar(Photo thumbnail, String alternativeText) {
    if (compactMode) {
      return new Container(width: 40.0);
    }

    return new Avatar(thumbnail, alternativeText);
  }

  createArrow() {
    if (compactMode) {
      return new Container();
    }

    return new CustomPaint(
      painter: new ArrowPainter(
          color: this.backgroundColor, direction: this.arrowDirection),
    );
  }
}


class Avatar extends StatelessWidget {
  Avatar(Photo photo, String alternativeText)
      : photo = photo,
        alternativeText = alternativeText,
        super(key: new ObjectKey(photo));

  final Photo photo;
  final String alternativeText;

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return new CircleAvatar(
        backgroundImage: new MemoryImage(photo.bytes),
      );
    }

    return new CircleAvatar(
      backgroundColor: Colors.blue,
      child: new Text(alternativeText != null ? alternativeText[0] : 'C'),
    );
  }
}
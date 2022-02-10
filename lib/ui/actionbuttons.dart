import 'package:flutter/material.dart';

// ignore: must_be_immutable
class PrimaryButton extends StatelessWidget {
  final void Function()? onTap;
  final String text;
  double height, width;
  EdgeInsets padding;
  bool filled;
  PrimaryButton(
      {required this.text,
      required this.onTap,
      this.filled = true,
      this.height = 40,
      this.width = 120,
      this.padding = const EdgeInsets.all(8)});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: MaterialButton(
        onPressed: onTap,
        child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: filled ? null : Border.all(color: Color(0xff3EDBF0)),
                gradient: filled
                    ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xff3EDBF0), Color(0xff77ACF1)])
                    : null),
            child: Center(
                child: Text(text,
                    style: TextStyle(
                        color: filled ? Colors.white : Color(0xff9038FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)))),
      ),
    );
  }
}

// ignore: must_be_immutable
class SecondaryButton extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  EdgeInsets padding;
  SecondaryButton(
      {required this.text,
      required this.onTap,
      this.padding = EdgeInsets.zero});
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: padding,
        child: GestureDetector(
            onTap: onTap,
            child: Center(
                child: Text(text,
                    style: TextStyle(
                        color: Color(0xff04009A),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)))));
  }
}

class SocialButtonArea extends StatelessWidget {
  final void Function()? facebookAction, linkedinAction;
  SocialButtonArea(
      {required this.facebookAction, required this.linkedinAction});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("OR", style: TextStyle(color: Color(0xffd0d0d0))),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: GestureDetector(
                      onTap: facebookAction,
                      child: Image.asset('assets/facebook.png', scale: 17)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: GestureDetector(
                      onTap: linkedinAction,
                      child: Image.asset('assets/linkedin.png', scale: 17)),
                ),
              ],
            ))
      ],
    );
  }
}

class FilterCookie extends StatelessWidget {
  final String text;
  final bool selected;
  FilterCookie({required this.text, required this.selected});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: selected ? Color(0xffA259FF) : Color(0xffF0F0F0)),
        child: Center(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                child: Text(text,
                    style: TextStyle(
                        color: selected ? Colors.white : Color(0xff808080))))),
      ),
    );
  }
}

class RippleButton extends StatelessWidget {
  final String text;
  final Color? color;
  final void Function() onTap;
  RippleButton({required this.text, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: color ?? Colors.black),
          borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        splashColor: color ?? Colors.transparent,
        child: Ink(
          height: 30,
          color: Colors.transparent,
          child: Center(child: Text(text, style: TextStyle(color: color))),
        ),
      ),
    );
  }
}

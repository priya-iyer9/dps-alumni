import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/ui/InputField.dart';
import 'package:alumniapp/ui/actionbuttons.dart';
import 'package:flutter/material.dart';

class ResetPassword extends StatefulWidget {
  final Server server;
  ResetPassword({required this.server});
  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  TextEditingController resetEmailController = TextEditingController();
  late bool resetEmailError,loading;

  @override
  void initState(){
    resetEmailError = false;
    loading = false;
    super.initState();
  }
  resetPassword() async {
    if(resetEmailController.value.text.trim().length==0){
      setState(() {
        resetEmailError = true;
      });
    }else{
      setState(() {
        loading = true;
      });
      widget.server.forgotPassword(resetEmailController.value.text.trim())
          .then((val){
        if(val.code==AuthResponseCode.success){
          Navigator.of(context).pop();
          setState(() {
            loading = false;
          });
          emailSent();
        }else{
          setState(() {
            resetEmailError = true;
            loading = false;
          });
        }
      });
    }
  }

  emailSent(){
    return showDialog(
        context: context,
        builder:(context){
          return Dialog(
              child:
              Container(
                height:200,
                child: Column(
                    mainAxisAlignment:MainAxisAlignment.center,
                    crossAxisAlignment:CrossAxisAlignment.center,
                    children:[
                      Padding(
                          padding:EdgeInsets.all(12),
                          child:Container(
                              width:50,height:50,
                              decoration:BoxDecoration(
                                  gradient:LinearGradient(
                                      begin:Alignment.centerLeft,
                                      end:Alignment.centerRight,
                                      colors:[Color.fromRGBO(3,163,99,1),Color.fromRGBO(8,199,68,1)]
                                  ),
                                  borderRadius:BorderRadius.circular(25)
                              ),
                              child:Center(child:Icon(Icons.done_sharp,color:Colors.white))
                          )
                      ),
                      Padding(
                          padding:EdgeInsets.all(12),
                          child:Text("Password reset email sent to ${resetEmailController.value.text.trim()}",textAlign:TextAlign.center)
                      )
                    ]
                ),
              )
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child:Scaffold(
        body:Stack(
          children: [
            Container(
              child: Column(
                mainAxisAlignment:MainAxisAlignment.center,
                children: [
                  Padding(
                    padding:EdgeInsets.all(10),
                    child:Text("Please enter your email address to reset password")
                  ),
                  Padding(
                    padding: EdgeInsets.all(10),
                    child: InputField(
                      error:resetEmailError,
                      errorMessage:"Email not registered",
                      hint:"Email",
                      controller:resetEmailController,
                      onChanged:(val){
                        setState(() {
                          resetEmailError = false;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding:EdgeInsets.symmetric(horizontal:15,vertical:15),
                    child:PrimaryButton(
                        onTap:()=>resetPassword(),
                        text:"Reset"
                    ),
                  )
                ],
              ),
            ),
            Container(
              height:loading?MediaQuery.of(context).size.height:0,
              color:Colors.black.withOpacity(0.8),
              child:Center(
                child:CircularProgressIndicator(
                  valueColor:AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
                )
              )
            )
          ],
        )
      ),
    );
  }
}

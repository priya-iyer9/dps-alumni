import 'dart:async';

import 'package:alumniapp/Service/CutomUser.dart';
import 'package:alumniapp/Service/Message.dart';
import 'package:alumniapp/Service/Server.dart';
import 'package:alumniapp/Service/Utils.dart';
import 'package:alumniapp/screens/ProfilePage.dart';
import 'package:alumniapp/ui/CustomAvatar.dart';
import 'package:alumniapp/ui/InputField.dart';
import 'package:alumniapp/ui/actionbuttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AllMessagesScreen extends StatefulWidget {
  final CustomUser? user;
  final Server server;
  AllMessagesScreen({required this.user,required this.server});
  @override
  _AllMessagesScreenState createState() => _AllMessagesScreenState();
}
class _AllMessagesScreenState extends State<AllMessagesScreen> {

  @override
  void initState() {
    super.initState();
  }

  allTextsSeen() async {
    await widget.server.allTextsSeen(widget.user!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child:Scaffold(
        body:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children: [
            Padding(
              padding:EdgeInsets.symmetric(vertical:16,horizontal:16),
              child:GestureDetector(
                onTap:()=>Navigator.of(context).pop(),
                child:Icon(Icons.chevron_left_rounded,size:28)
              )
            ),
            SingleChildScrollView(
              child:StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
                stream:widget.server.getUserChats(widget.user!.uid),
                builder:(context,snapshot){
                  if(snapshot.hasData){
                    if(snapshot.data!.docs.length==0){
                      return Center(child:Text("No chats"));
                    }
                    return ListView.builder(
                      shrinkWrap:true,
                      physics:NeverScrollableScrollPhysics(),
                      itemCount:snapshot.data!.docs.length,
                      itemBuilder:(context,index){
                        final chat = Chat.fromJson(snapshot.data!.docs[index]);
                        Utils.debugPrint(chat.chatId);
                        return ChatListItem(chat:chat,server:widget.server,user:widget.user);
                      }
                    );
                  }
                  return Text("NoData");
                }
              )
            )
          ],
        )
      )
    );
  }
}

class ChatListItem extends StatefulWidget {
  final Chat chat;
  final CustomUser? user;
  final Server server;
  ChatListItem({required this.chat,required this.server,required this.user});
  @override
  _ChatListItemState createState() => _ChatListItemState();
}
class _ChatListItemState extends State<ChatListItem> {
  CustomUser? target;

  @override
  void initState() {
    super.initState();
    getTarget();
  }

  getTarget() async {
    final uid = widget.chat.users!.where((element) =>element!=widget.user!.uid).first;
    final res = await widget.server.getUserById(uid!);
    setState(() {
      target = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:EdgeInsets.symmetric(horizontal:20,vertical:10),
      child:target==null?Container(height:0)
      :GestureDetector(
        onTap:()=>Navigator.of(context).push(
          MaterialPageRoute(
            builder:(context)=>ChatScreen(chat:widget.chat,user:widget.user,server:widget.server,target:target)
          )
        ),
        child: Row(
          children: [
            CustomAvatar(user:target!,server:widget.server,radius:25),
            SizedBox(width:15),
            Column(
              crossAxisAlignment:CrossAxisAlignment.start,
              children: [
                Text(Utils.getName(target!)),
                StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
                  stream:widget.server.streamLastMessage(widget.chat.chatId),
                  builder:(context,snapshot){
                    if(snapshot.hasData){
                      if(snapshot.data!.docs.length>0){
                        final message = CustomMessage.fromJson(snapshot.data!.docs[0]);
                        if(message.sentBy==widget.user!.uid){
                          if(message.seen){
                            return Text("seen \u2981 "+message.text.toString(),style:TextStyle(color:Color(0xff909090)));
                          }
                          return Text("sent \u2981 "+message.text.toString(),style:TextStyle(color:Color(0xff909090)));
                        }else{
                          if(!message.seen){
                            return Text(message.text.toString(),style:TextStyle(color:Color(0xff909090),fontWeight:FontWeight.w500));
                          }
                          return Text(message.text.toString(),style:TextStyle(color:Color(0xff909090)));
                        }
                      }else{
                        return Center(child:Text("No messages"));
                      }
                    }
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:AlwaysStoppedAnimation<Color>(Color(0xffA259FF)),
                      ),
                    );
                  }
                )
              ],
            ),
            Expanded(child:Container()),
            Column(
              crossAxisAlignment:CrossAxisAlignment.end,
              children: [
                Text(Utils.getChatTime(widget.chat.timestamp),style:TextStyle(fontSize:10)),
                Text(Utils.getYesterdayToday(widget.chat.timestamp)??Utils.getDate(widget.chat.timestamp),style:TextStyle(fontSize:10))
              ],
            )
          ],
        ),
      )
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Chat? chat;
  final CustomUser? user,target;
  final Server server;
  ChatScreen({required this.chat,required this.user,required this.server,required this.target});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();
  late Chat? chat;
  late CustomMessage? lastFetched;
  late FocusNode textNode;
  late ScrollController controller;
  @override
  void initState() {
    super.initState();
    chat = widget.chat;
    lastFetched = null;
    textNode = FocusNode();
    if(chat==null){
      textNode.requestFocus();
    }
    controller =  ScrollController();
    widget.server.clearMessageNotifications(widget.user!.uid);
  }

  Future messageStream(){
    if(chat!=null){
      Utils.debugPrint("Fetching messages");
      Utils.debugPrint(chat!.chatId);
      return widget.server.fetchMessages(chat!,lastFetched!,widget.target!.uid);
    }else{
      return Future.value(null);
    }
  }

  sendMessage() async {
    final message = CustomMessage(sentBy:widget.user!.uid,text:messageController.value.text,seen:false,timestamp:DateTime.now(),to:widget.target!.uid);
    messageController.clear();
    if(chat==null){
      //newChat and sendMessage
      final cht = Chat(users:[widget.user!.uid,widget.target!.uid]);
      final res = await widget.server.sendMessageInNewChat(message,cht);
      if(res.code==DbResponseCode.failed){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text("Error sending :(")));
      }else{
        setState(() {
          chat = Chat(chatId:res.insertedId,users:[widget.user!.uid,widget.target!.uid]);
        });
        Utils.debugPrint(chat!.chatId);
      }
    }else{
      //sendMessage
      final res = await widget.server.sendMessageInExistingChat(message,chat!.chatId);
      if(res.code==DbResponseCode.failed){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text("Error sending :(")));
      }
    }
  }

  gotoprofile(){
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:(context)=>ViewProfile(user:widget.user,target:widget.target,server:widget.server)
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    Timer(Duration(milliseconds:500),(){
      controller.jumpTo(controller.position.maxScrollExtent+10);
    });
    return SafeArea(
      child:Scaffold(
        body:Container(
          height:MediaQuery.of(context).size.height,
          child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children: [
              Container(
                decoration:BoxDecoration(
                  color:Colors.white,
                  boxShadow:[BoxShadow(
                    color: Colors.grey,
                    offset: Offset(0,0.5),
                    blurRadius:5,
                  )]
                ),
                child: Row(
                  children: [
                    Padding(
                      padding:EdgeInsets.symmetric(vertical:20,horizontal:16),
                      child:GestureDetector(
                        onTap:()=>Navigator.of(context).pop(),
                        child:Icon(Icons.chevron_left_rounded,size:28)
                      )
                    ),
                    GestureDetector(
                      onTap:gotoprofile,
                      child:CustomAvatar(user:widget.target!,server:widget.server,radius:20)
                    ),
                    SizedBox(width:10),
                    Padding(
                      padding: EdgeInsets.only(right:20),
                      child: GestureDetector(
                        onTap:gotoprofile,
                        child: Column(
                          crossAxisAlignment:CrossAxisAlignment.start,
                          children:[
                            Text(widget.target!.getFullName()),
                            Container(
                              width:270,
                              child: Text(widget.target!.collegeName.toString(),overflow:TextOverflow.ellipsis,style:TextStyle(color:Color(0xff909090),fontSize:12))
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child:Stack(
                  children:[
                    Positioned(
                      top:10,
                      bottom:60,
                      child:
                        chat!=null?
                        StreamBuilder<QuerySnapshot<Map<String,dynamic>>>(
                          stream:widget.server.streamMessages(chat!.chatId),
                          builder:(context,snapshot){
                            if(snapshot.data!=null){
                              return Container(
                                width:MediaQuery.of(context).size.width,
                                child: ListView.builder(
                                  controller:controller,
                                  physics:BouncingScrollPhysics(),
                                  shrinkWrap:true,
                                  itemCount:snapshot.data!.docs.length,
                                  itemBuilder:(context,index){
                                    final message = CustomMessage.fromJson(snapshot.data!.docs[index]);
                                    return MessageUI(
                                      message:message,
                                      sentByMe:message.sentBy==widget.user!.uid,
                                      isLast:index==snapshot.data!.docs.length-1,
                                    );
                                  },
                                ),
                              );
                            }else{
                              return Center(child:CircularProgressIndicator(valueColor:AlwaysStoppedAnimation<Color>(Color(0xffA259FF))));
                            }
                          }
                      ):Container(
                        width:MediaQuery.of(context).size.width,
                        child: Column(
                          mainAxisAlignment:MainAxisAlignment.center,
                          crossAxisAlignment:CrossAxisAlignment.center,
                          children: [
                            Center(
                              child:Text("Start a conversation :)")
                            ),
                          ],
                        ),
                      )
                    ),
                    Positioned(
                        bottom:0,left:10,right:0,
                        child:Row(
                          children: [
                            Expanded(
                              child: InputField(
                                hint:"Type something",
                                error:false,
                                controller:messageController,
                                focusNode:textNode,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal:5),
                              child: PrimaryButton(text:"Send",onTap:sendMessage,width:50)
                            ),
                          ],
                        )
                    )
                  ],
                ),
              ),
            ],
          )
        )
      )
    );
  }
}

class MessageUI extends StatelessWidget {
  final CustomMessage message;
  final bool sentByMe,isLast;
  MessageUI({required this.message,required this.sentByMe,this.isLast=false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:EdgeInsets.symmetric(vertical:3,horizontal:8),
      child:Column(
        crossAxisAlignment:sentByMe?CrossAxisAlignment.end:CrossAxisAlignment.start,
        children: [
          Container(
            constraints:BoxConstraints(
              maxWidth:4*MediaQuery.of(context).size.width/5,
            ),
            decoration:BoxDecoration(
                borderRadius:BorderRadius.circular(10),
                color:sentByMe?Color(0xffA259FF):Color(0xffEDEDED)
            ),
            child:Padding(
              padding: EdgeInsets.symmetric(horizontal:13,vertical:8),
              child: Text(message.text.toString(),style:TextStyle(color:sentByMe?Colors.white:Colors.black54)),
            )
          ),
          sentByMe?
            isLast?
              message.seen?
                Padding(
                  padding: EdgeInsets.symmetric(horizontal:4),
                  child: Text("seen",style:TextStyle(color:Color(0xff909090),fontSize:9)),
                )
              :Padding(
                padding: EdgeInsets.symmetric(horizontal:4),
                child: Text("sent",style:TextStyle(color:Color(0xff909090),fontSize:9)),
              )
            :Container(height:0)
          :Container(height:0)

        ],
      )
    );
  }
}

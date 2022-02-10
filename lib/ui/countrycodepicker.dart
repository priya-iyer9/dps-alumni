import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Country{
  final String name,symbol,code;
  Country({required this.name,required this.symbol,required this.code});
  factory Country.fromJson(json)=>Country(name:json["name"],code:json["code"],symbol:json["symbol"]);
}

class CountryCodePicker extends StatefulWidget {
  final void Function(Country?) onChanged;
  CountryCodePicker({required this.onChanged});
  @override
  _CountryCodePickerState createState() => _CountryCodePickerState();
}

class _CountryCodePickerState extends State<CountryCodePicker> {
  List<Country> items = List.empty(growable:true);
  Country selectedCountry = Country(name:"India",symbol:"IN",code:"91");
  @override
  void initState() {
    getCountries();
    super.initState();
  }

  getCountries() async {
    final x = await rootBundle.loadString("assets/countries.json");
    final clgs = jsonDecode(x);
    List<Country> res = [];
    clgs.forEach((element){res.add(Country.fromJson(element));});
    setState(() {
      items = res;
    });
  }

  dialog(){
    showDialog(
      context: context,
      builder: (context){
        return Dialog(
          child: ListView.builder(
            itemCount:items.length,
            shrinkWrap:true,
            itemBuilder:(context,index){
              return MaterialButton(
                onPressed:(){
                  setState(() {
                    selectedCountry = items[index];
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  child:Padding(
                    padding: EdgeInsets.symmetric(vertical:10,horizontal:10),
                    child: Row(
                      children: [
                        Text(items[index].name),
                        Expanded(child:Container()),
                        Text(items[index].code),
                      ],
                    ),
                  )
                ),
              );
            },
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width:60,
      decoration:BoxDecoration(
          color:Color(0xfff0f0f0),
          borderRadius:BorderRadius.circular(10)
      ),
      child:Padding(
        padding:EdgeInsets.symmetric(vertical:17),
        child: GestureDetector(
          onTap:dialog,
          child:Center(child: Text("+"+selectedCountry.code,overflow:TextOverflow.ellipsis))
        ),
      )
    );
  }
}



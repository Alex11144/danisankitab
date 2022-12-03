import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:danisankitab/player_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'booknode.dart';

class SelectorPage extends StatefulWidget {
  final List<BookNode> bookNodes;
  SelectorPage({Key key, @required this.bookNodes}) : super(key: key);

  @override
  _SelectorPageState createState() => _SelectorPageState();
}

class _SelectorPageState extends State<SelectorPage> {

  PageController pageController;
  double currentPage = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    pageController.addListener(() {
      setState(() {
        // print(pageController.page);
        currentPage = pageController.page;
      });
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    int ttt = widget.bookNodes.length;
    int ppp = 6;
    int pcount = (ttt/ppp).ceil();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: PageView.builder(
              controller: pageController,
              itemCount: pcount,
              itemBuilder: (BuildContext context, int index) {
                return SafeArea(child: myGrid(index * ppp));
              },
            )),
            Container(color: Colors.blue, height: 5, width: (currentPage/(max(1, pcount-1)))*MediaQuery.of(context).size.width,)
          ]
      ),
    );
  }

  Widget myGrid(int offset) {

    return Padding(padding: EdgeInsets.all(5), child: Column(
      children: [
        Expanded(child: Row(children: [Expanded(child: myGridI(offset + 0)), Expanded(child: myGridI(offset + 1))])),
        Expanded(child: Row(children: [Expanded(child: myGridI(offset + 2)), Expanded(child: myGridI(offset + 3))])),
        Expanded(child: Row(children: [Expanded(child: myGridI(offset + 4)), Expanded(child: myGridI(offset + 5))])),
      ],
    ));
  }

  Widget myGridI(int index) {
    if (index >= widget.bookNodes.length) return Container();

    return GestureDetector(
        onTap: (){
          if (widget.bookNodes[index].isCategory) {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                SelectorPage(bookNodes: widget.bookNodes[index].children)));
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>
                PlayerPage(widget.bookNodes[index])));
          }
        },
        child: SelectorItemWidget(widget.bookNodes[index])
    );
  }
}

class SelectorItemWidget extends StatelessWidget {

  final BookNode _bookNode;
  SelectorItemWidget(this._bookNode);

  @override
  Widget build(BuildContext context) {
    return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Container(
              // margin: EdgeInsets.fromLTRB(15, 15, 15, 10),
              decoration: BoxDecoration(/*borderRadius: BorderRadius.all(Radius.circular(10)),*/ image: DecorationImage(fit: BoxFit.cover, image: CachedNetworkImageProvider("https://danisankitab.az/persistent/"+_bookNode.artUri))),
            )),

            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
              child: DefaultTextStyle(
                softWrap: false,
                overflow: TextOverflow.fade,
                style: Theme.of(context).textTheme.subtitle1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(_bookNode.title),
                    // three line description

                    if (!_bookNode.isCategory) Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _bookNode.subtitle,
                        style: Theme.of(context).textTheme.subtitle1.copyWith(color: Colors.black54, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
    );
  }
}


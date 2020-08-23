import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:hostess/global/colors.dart';
import 'package:hostess/notifier/food_notifier.dart';
import 'package:hostess/screens/details_screen.dart';
import 'package:provider/provider.dart';

class MenuItem extends StatelessWidget {
  final int index;
  final String price;

  MenuItem({this.index, this.price});

  Widget _price() {
    List<String> splitRes = price.split('#');
    String splitPrice = splitRes[1];
    return Text(
      splitPrice,
      style: TextStyle(
        color: t_primary,
        fontSize: 18.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    FoodNotifier foodNotifier = Provider.of<FoodNotifier>(context);
    return Container(
      height: 100,
      child: InkWell(
        onTap: () {
          foodNotifier.currentFood = foodNotifier.foodList[index];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FoodDetail(),
            ),
          );
        },
        child: Row(
          children: <Widget>[
            Container(
              width: 80,
              height: 80,
              child: Card(
                semanticContainer: true,
                clipBehavior: Clip.antiAliasWithSaveLayer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: foodNotifier.foodList[index].imageLow != null
                    ? CachedNetworkImage(
                        imageUrl: foodNotifier.foodList[index].imageLow,
                        fit: BoxFit.cover,
                        progressIndicatorBuilder:
                            (context, url, downloadProgress) => Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: CircularProgressIndicator(
                              value: downloadProgress.progress),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      )
                    : Image.asset('assets/placeholder_1024.png',
                        fit: BoxFit.cover),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 2.0, 5.0, 2.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      foodNotifier.foodList[index].title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t_primary,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      foodNotifier.foodList[index].description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t_secondary,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '₴',
                    style: TextStyle(
                      color: t_primary,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 2),
                  _price(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

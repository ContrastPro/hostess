import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:hostess/api/categories_api.dart';
import 'package:hostess/api/profile_api.dart';
import 'package:hostess/database/db_cart.dart';

import 'package:hostess/global/colors.dart';

import 'package:hostess/notifier/categories_notifier.dart';
import 'package:hostess/notifier/profile_notifier.dart';
import 'package:hostess/screens/cart_screen.dart';
import 'package:hostess/screens/details_screen.dart';

import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final String restaurant;
  final String address;

  HomeScreen({this.restaurant, this.address});

  @override
  _HomeScreenState createState() =>
      _HomeScreenState(restaurant: restaurant, address: address);
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final String restaurant;
  final String address;

  _HomeScreenState({this.restaurant, this.address});

  int _isExist = 1;
  int _selectedIndex = 0;
  int _total;
  bool isClicked = false;
  AnimationController _animationController;

  @override
  void initState() {
    _load();
    ProfileNotifier profileNotifier =
        Provider.of<ProfileNotifier>(context, listen: false);
    getProfile(profileNotifier, restaurant, address);

    CategoriesNotifier categoriesNotifier =
        Provider.of<CategoriesNotifier>(context, listen: false);
    getCategories(categoriesNotifier, restaurant, address);

    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _isEmptyCart();
    super.initState();
  }

  Future<void> _load() async {
    await FirebaseFirestore.instance
        .collection(restaurant)
        .doc(address)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          _isExist = 0;
        });
      } else {
        setState(() {
          _isExist = 2;
        });
      }
    });
  }

  _isEmptyCart() async {
    int total = await MastersDatabaseProvider.db.calculateTotal();
    setState(() => _total = total);
  }

  _onSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    ProfileNotifier profileNotifier = Provider.of<ProfileNotifier>(context);

    CategoriesNotifier categoriesNotifier =
        Provider.of<CategoriesNotifier>(context);

    Widget _time() {
      DateTime date = DateTime.now();
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time,
            color: Colors.white,
            size: 18.0,
          ),
          SizedBox(width: 10),
          Text(
            profileNotifier.profileList[0].subTime[date.weekday - 1],
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      );
    }

    Widget _chip(int index) {
      return FilterChip(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        label: Text(
          categoriesNotifier.categoriesList[index].title,
          style: TextStyle(
            fontSize: 16.0,
            color: _selectedIndex != null && _selectedIndex == index
                ? c_background
                : t_primary.withOpacity(0.4),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: _selectedIndex != null && _selectedIndex == index
            ? c_primary
            : Colors.white.withOpacity(0),
        elevation:
            _selectedIndex != null && _selectedIndex == index ? 0.0 : 2.0,
        pressElevation: 0.0,
        onSelected: (bool value) {
          _onSelected(index);
        },
      );
    }

    Widget _price(subPrice) {
      List<String> splitRes = subPrice.split('#');
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

    Widget _menuItem(int index, DocumentSnapshot document) {
      return Container(
        color: c_background,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Container(
            height: 100,
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FoodDetail(
                      id: document.data()['id'],
                      restaurant: restaurant,
                      address: address,
                      categories: categoriesNotifier
                          .categoriesList[_selectedIndex].title,
                    ),
                  ),
                );
                _isEmptyCart();
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
                      child: document.data()['imageLow'] != null
                          ? CachedNetworkImage(
                              imageUrl: document.data()['imageLow'],
                              fit: BoxFit.cover,
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) => Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: CircularProgressIndicator(
                                    value: downloadProgress.progress),
                              ),
                              errorWidget: (context, url, error) => Image.asset(
                                  'assets/placeholder_1024.png',
                                  fit: BoxFit.cover),
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
                            document.data()['title'],
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
                            document.data()['description'],
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
                        _price(document.data()['subPrice'][0]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget _setMenu() {
      return categoriesNotifier.categoriesList[_selectedIndex].title != null
          ? StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection(restaurant)
                  .doc(address)
                  .collection('ru')
                  .doc('Menu')
                  .collection(
                      categoriesNotifier.categoriesList[_selectedIndex].title)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong'));
                }

                if (!snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 80.0),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 10)),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(
                    left: 25.0,
                    top: 0.0,
                    right: 30.0,
                    bottom: 20.0,
                  ),
                  itemCount: snapshot.data.documents.length,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return _menuItem(index, snapshot.data.documents[index]);
                  },
                );
              },
            )
          : SizedBox();
    }

    Widget _homeScreen() {
      return profileNotifier.profileList.isNotEmpty
          ? Scaffold(
              backgroundColor: c_secondary,
              body: Stack(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: profileNotifier.profileList[0].image != null
                        ? CachedNetworkImage(
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            imageUrl: profileNotifier.profileList[0].image,
                            placeholder: (context, url) => Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 50.0),
                                child:
                                    CircularProgressIndicator(strokeWidth: 10),
                              ),
                            ),
                            errorWidget: (context, url, error) => Image.asset(
                                'assets/placeholder_1024.png',
                                fit: BoxFit.cover),
                          )
                        : Image.asset('assets/placeholder_1024.png',
                            fit: BoxFit.cover),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.55,
                    height: double.infinity,
                    color: c_primary,
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 50.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            '${profileNotifier.profileList[0].title}'
                                .toUpperCase(),
                            maxLines: 3,
                            textAlign: TextAlign.left,
                            minFontSize: 25,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 50.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 20),
                          profileNotifier.profileList.isNotEmpty
                              ? _time()
                              : Container(),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      width: double.infinity,
                      height: isClicked
                          ? MediaQuery.of(context).size.height * 0.80
                          : 0.0,
                      duration: Duration(seconds: 1),
                      curve: Curves.fastOutSlowIn,
                      decoration: BoxDecoration(
                        color: c_background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.0),
                          topRight: Radius.circular(30.0),
                        ),
                      ),
                      child: CustomScrollView(
                        slivers: <Widget>[
                          SliverList(
                            delegate: SliverChildListDelegate(
                              <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Column(
                                      children: <Widget>[
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 30.0,
                                              right: 30.0,
                                              top: 40.0,
                                            ),
                                            child: Text(
                                              'Меню',
                                              style: TextStyle(
                                                color: t_primary,
                                                fontSize: 30.0,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      height: 80,
                                      child: ListView.builder(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 10),
                                          scrollDirection: Axis.horizontal,
                                          itemCount: categoriesNotifier
                                              .categoriesList.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: EdgeInsets.all(5.0),
                                              child: _chip(index),
                                            );
                                          }),
                                    ),
                                    _setMenu(),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 20.0),
                          child: FloatingActionButton.extended(
                            elevation: 2,
                            focusElevation: 4,
                            hoverElevation: 4,
                            highlightElevation: 8,
                            heroTag: 'menu',
                            onPressed: () {
                              setState(() {
                                isClicked = !isClicked;
                                isClicked
                                    ? _animationController.forward()
                                    : _animationController.reverse();
                              });
                            },
                            icon: AnimatedIcon(
                              icon: AnimatedIcons.menu_close,
                              color: Colors.white,
                              progress: _animationController,
                            ),
                            label: Text(
                              'Меню',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: c_secondary.withOpacity(0.5),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.0, vertical: 20.0),
                          child: RawMaterialButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CartScreen(),
                                ),
                              );
                              _isEmptyCart();
                            },
                            fillColor: c_secondary.withOpacity(0.5),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                ),
                                _total != null
                                    ? Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: Colors.deepOrange[900],
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : SizedBox(),
                              ],
                            ),
                            padding: EdgeInsets.all(15.0),
                            shape: CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Scaffold(
              body: Center(child: CircularProgressIndicator(strokeWidth: 10)));
    }

    Widget _setWidget() {
      if (_isExist == 0) {
        return _homeScreen();
      } else if (_isExist == 1) {
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(strokeWidth: 10),
          ),
        );
      } else {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/empty_search.png',
                fit: BoxFit.cover,
              ),
              SizedBox(height: 40.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  'Упс...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t_primary,
                    fontSize: 25.0,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
                child: Text(
                  'Похоже заведение которое вы ищите ещё не существует :(',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: t_primary.withOpacity(0.5),
                    fontSize: 20.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 80.0, 20.0, 0.0),
                child: FloatingActionButton.extended(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.arrow_back,
                    color: t_primary,
                  ),
                  label: Text(
                    'Вернуться назад',
                    style: TextStyle(
                      color: t_primary,
                      fontSize: 20.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  backgroundColor: c_background,
                ),
              ),
            ],
          ),
        );
      }
    }

    return _setWidget();
  }
}

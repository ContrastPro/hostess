import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:hostess/api/categories_api.dart';
import 'package:hostess/api/profile_api.dart';
import 'package:hostess/database/db_cart.dart';

import 'package:hostess/global/colors.dart';
import 'package:hostess/global/fade_route.dart';

import 'package:hostess/notifier/categories_notifier.dart';
import 'package:hostess/notifier/profile_notifier.dart';
import 'package:hostess/screens/cart_screen.dart';
import 'package:hostess/screens/details_screen.dart';

import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  final String uid;
  final String address;

  HomeScreen({this.uid, this.address});

  @override
  _HomeScreenState createState() =>
      _HomeScreenState(uid: uid, address: address);
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final String uid;
  final String address;

  _HomeScreenState({this.uid, this.address});

  int _isExist = 1;
  int _selectedIndex = 0;
  int _total;
  bool _isClicked = false;
  bool _isClickedLang = false;
  String _language;
  AnimationController _animationController;

  @override
  void initState() {
    _preLoad();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    super.initState();
  }

  Future<void> _preLoad() async {
    await FirebaseFirestore.instance
        .collection(uid)
        .doc(address)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        setState(() {
          _isExist = 0;
        });
        _load();
        _isEmptyCart();
      } else {
        setState(() {
          _isExist = 2;
        });
      }
    });
  }

  _load() async {
    ProfileNotifier profileNotifier =
        Provider.of<ProfileNotifier>(context, listen: false);
    await getProfile(profileNotifier, uid, address);
    setState(() => _language = profileNotifier.profileList[0].subLanguages[0]);
    CategoriesNotifier categoriesNotifier =
        Provider.of<CategoriesNotifier>(context, listen: false);
    getCategories(categoriesNotifier, uid, address,
        profileNotifier.profileList[0].subLanguages[0]);
  }

  _isEmptyCart() async {
    int total = await MastersDatabaseProvider.db.calculateTotal();
    setState(() => _total = total);
  }

  _onSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  _launchMap(String openMap) async {
    String url =
        'https://www.google.com/maps/search/${Uri.encodeFull(openMap)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _makePhoneCall(String openPhone) async {
    if (await canLaunch(openPhone)) {
      await launch(openPhone);
    } else {
      throw 'Could not launch $openPhone';
    }
  }

  @override
  Widget build(BuildContext context) {
    ProfileNotifier profileNotifier = Provider.of<ProfileNotifier>(context);

    CategoriesNotifier categoriesNotifier =
        Provider.of<CategoriesNotifier>(context);

    double _size() {
      if (_isClickedLang) {
        switch (profileNotifier.profileList[0].subLanguages.length) {
          case 1:
            return 60.0;

            break;
          case 2:
            return 100.0;

            break;
          default:
            return 140.0;

            break;
        }
      } else {
        return 18.0;
      }
    }

    Widget _time() {
      DateTime date = DateTime.now();
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time,
            color: Colors.white,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              profileNotifier.profileList[0].subTime[date.weekday - 1],
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      );
    }

    Widget _chip(int index) {
      return FilterChip(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                  FadeRoute(
                    page: FoodDetail(
                      id: document.data()['id'],
                      uid: uid,
                      address: address,
                      language: _language,
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
                                  'assets/placeholder_200.png',
                                  fit: BoxFit.cover),
                            )
                          : Image.asset('assets/placeholder_200.png',
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
      return categoriesNotifier.categoriesList.isNotEmpty && _language != null
          ? StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection(uid)
                  .doc(address)
                  .collection(_language)
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
                    padding: const EdgeInsets.only(top: 100.0),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 6)),
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
          : Column(
              children: [
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
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 0.0),
                  child: Text(
                    'Похоже меню на языке "$_language" всё ещё в разработке. Выберите другой язык!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: t_primary.withOpacity(0.5),
                      fontSize: 20.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            );
    }

    Widget _setLanguage() {
      return _language != null
          ? Stack(
              children: [
                AnimatedContainer(
                  duration: Duration(seconds: 1),
                  curve: Curves.fastOutSlowIn,
                  width: _size(),
                  height: 36,
                  decoration: BoxDecoration(
                    color: c_secondary.withOpacity(0.6),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(30.0),
                      bottomRight: Radius.circular(30.0),
                    ),
                  ),
                  margin: EdgeInsets.only(left: 18),
                  child: ListView.builder(
                      reverse: true,
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          profileNotifier.profileList[0].subLanguages.length,
                      padding: EdgeInsets.only(left: 25),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _language = profileNotifier
                                    .profileList[0].subLanguages[index];
                                _isClickedLang = !_isClickedLang;
                              });
                              getCategories(
                                  categoriesNotifier, uid, address, _language);
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              child: Image.asset(
                                  'assets/${profileNotifier.profileList[0].subLanguages[index]}.png'),
                            ),
                          ),
                        );
                      }),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _isClickedLang = !_isClickedLang),
                    child: Container(
                      width: 36,
                      height: 36,
                      child: Image.asset('assets/$_language.png'),
                    ),
                  ),
                ),
              ],
            )
          : SizedBox();
    }

    Widget _backSide() {
      return Stack(
        children: [
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
                        child: CircularProgressIndicator(strokeWidth: 6),
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/placeholder_1024.png',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset('assets/placeholder_1024.png', fit: BoxFit.cover),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.55,
            height: double.infinity,
            color: c_primary,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 50.0, 10.0, 50.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    '${profileNotifier.profileList[0].title}'.toUpperCase(),
                    maxLines: 3,
                    textAlign: TextAlign.left,
                    minFontSize: 25,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 45.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 35),
                  GestureDetector(
                    onTap: () => _launchMap(
                        profileNotifier.profileList[0].title +
                            ", " +
                            profileNotifier.profileList[0].address),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            profileNotifier.profileList[0].address,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  profileNotifier.profileList[0].phone.isNotEmpty
                      ? Column(
                          children: [
                            SizedBox(height: 20),
                            GestureDetector(
                              onTap: () => _makePhoneCall(
                                  'tel:${profileNotifier.profileList[0].phone}'),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.phone,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      profileNotifier.profileList[0].phone,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : SizedBox(),
                  SizedBox(height: 20),
                  _time(),
                ],
              ),
            ),
          ),
        ],
      );
    }

    Widget _frontSide() {
      return Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              width: double.infinity,
              height:
                  _isClicked ? MediaQuery.of(context).size.height * 0.80 : 0.0,
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
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 30.0,
                                right: 30.0,
                                top: 40.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Меню',
                                      style: TextStyle(
                                        color: t_primary,
                                        fontSize: 30.0,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  _setLanguage(),
                                ],
                              ),
                            ),
                            Container(
                              height: 80,
                              child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      categoriesNotifier.categoriesList.length,
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
            child: Padding(
              padding: const EdgeInsets.only(top: 20.0, left: 18.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  FloatingActionButton.extended(
                    elevation: 2,
                    focusElevation: 4,
                    hoverElevation: 4,
                    highlightElevation: 8,
                    heroTag: 'menu',
                    onPressed: () {
                      setState(() {
                        _isClicked = !_isClicked;
                        _isClicked
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
                  RawMaterialButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        FadeRoute(
                          page: CartScreen(),
                        ),
                      );
                      _isEmptyCart();
                    },
                    fillColor: c_secondary.withOpacity(.5),
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
                    padding: EdgeInsets.all(13.0),
                    shape: CircleBorder(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    Widget _homeScreen() {
      return profileNotifier.profileList.isNotEmpty
          ? Scaffold(
              backgroundColor: c_secondary,
              body: Stack(
                children: <Widget>[
                  _backSide(),
                  _frontSide(),
                ],
              ),
            )
          : Scaffold(
              body: Center(child: CircularProgressIndicator(strokeWidth: 6)));
    }

    Widget _setWidget() {
      if (_isExist == 0) {
        return _homeScreen();
      } else if (_isExist == 1) {
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(strokeWidth: 6),
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

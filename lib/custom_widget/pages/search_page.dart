import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hostess/custom_widget/custom_container.dart';
import 'package:hostess/custom_widget/custom_fade_route.dart';
import 'package:hostess/custom_widget/product_widget/product_widget.dart';
import 'package:hostess/global/colors.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String _searchQuery = "";
  String _searchCategory = "All";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Widget _buildSearchField() {
      final border = OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15.0)),
        borderSide: BorderSide(color: Colors.transparent),
      );

      return Theme(
        data: Theme.of(context).copyWith(
          cursorColor: c_accent,
          hintColor: Colors.transparent,
        ),
        child: TextFormField(
          decoration: InputDecoration(
            suffix: const SizedBox(width: 50),
            focusedBorder: border,
            border: border,
            prefixIcon: const Icon(
              Icons.search,
              color: c_primary,
            ),
            filled: true,
            hintText: 'Название заведения',
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
            /*fillColor: Colors.white.withOpacity(0.8),*/
            fillColor: c_secondary.withOpacity(0.15),
          ),
          controller: _searchController,
          onChanged: (String value) {
            setState(() => _searchQuery = value.toLowerCase());
          },
        ),
      );
    }

    Widget _searchList() {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Search')
            .doc('Global_Search')
            .collection(_searchCategory)
            .where('subSearchKey', arrayContains: _searchQuery)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 140),
                child: const CircularProgressIndicator(),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(9.0, 120.0, 10.0, 30.0),
            itemCount: snapshot.data.docs.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                color: c_background,
                child: ListTile(
                  title: Text(snapshot.data.docs[index].data()['title']),
                  subtitle: Text(snapshot.data.docs[index].data()['address']),
                  onTap: () {
                    List<String> splitRes =
                        snapshot.data.docs[index].data()['id'].split('#');
                    Navigator.push(
                      context,
                      FadeRoute(
                        page: ProductWidget(
                            uid: splitRes[0], address: splitRes[1]),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    }

    Widget _globalList() {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Search')
            .doc('Global_Search')
            .collection(_searchCategory)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(9.0, 120.0, 10.0, 30.0),
            itemCount: snapshot.data.docs.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                color: c_background,
                child: ListTile(
                  title: Text(snapshot.data.docs[index].data()['title']),
                  subtitle: Text(snapshot.data.docs[index].data()['address']),
                  onTap: () {
                    List<String> splitRes =
                        snapshot.data.docs[index].data()['id'].split('#');
                    Navigator.push(
                      context,
                      FadeRoute(
                        page: ProductWidget(
                            uid: splitRes[0], address: splitRes[1]),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: c_primary,
      resizeToAvoidBottomInset: false,
      body: CustomContainer(
        title: 'Поиск',
        child: Stack(
          children: [
            if (_searchQuery.isNotEmpty)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 140),
                  child: CircularProgressIndicator(),
                ),
              ),
            _searchQuery.isNotEmpty ? _searchList() : _globalList(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0.0),
              child: _buildSearchField(),
            ),
          ],
        ),
      ),
    );
  }
}

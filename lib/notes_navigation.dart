// ignore_for_file: avoid_print, constant_identifier_names
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';
import 'helpers/adaptive.dart';
import 'package:animations/animations.dart';
import 'helpers/globals.dart' as globals;
import 'pages/archive_page.dart';
import 'pages/notes_home_page.dart';
import 'pages/search_page.dart';

//TODO: cleanup navigation dart file
enum ViewType { Tile, Grid }

class NestNotes extends StatefulWidget {
  const NestNotes({Key? key}) : super(key: key);

  @override
  _ScrawlAppState createState() => _ScrawlAppState();
}

class _ScrawlAppState extends State<NestNotes> {
  late SharedPreferences sharedPreferences;
  bool isTileView = false;
  ViewType viewType = ViewType.Tile;
  bool isAppLogged = false;
  String appPin = "";
  bool openNav = false;

  bool isAndroid = UniversalPlatform.isAndroid;
  bool isIOS = UniversalPlatform.isIOS;
  bool isWeb = UniversalPlatform.isWeb;
  bool isDesktop = false;

  late PageController _pageController;
  int _page = 0;

  final _pageList = <Widget>[
    HomePage(title: "nest notes"),
    const ArchivePage(),
    const SearchPage(),
    //const SettingsPage(),
  ];

  String username = '';

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  getPref() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      isAppLogged = sharedPreferences.getBool("is_logged") ?? false;
      appPin = sharedPreferences.getString("app_pin") ?? '';
      bool isTile = sharedPreferences.getBool("is_tile") ?? false;
      username = sharedPreferences.getString('nc_userdisplayname') ?? '';
      print(appPin);
      viewType = isTile ? ViewType.Tile : ViewType.Grid;
    });
  }

  Future getdata() async {
    sharedPreferences = await SharedPreferences.getInstance();
    if (isAppLogged) {
      try {
        final client = NextCloudClient.withCredentials(
          Uri(host: sharedPreferences.getString('nc_host')),
          sharedPreferences.getString('nc_username') ?? '',
          sharedPreferences.getString('nc_password') ?? '',
        );
        final userData = await client.avatar.getAvatar(
            sharedPreferences.getString('nc_username').toString(), 150);
        sharedPreferences.setString('nc_avatar', userData);

        // ignore: unnecessary_null_comparison
      } on RequestException catch (e, stacktrace) {
        print('qs' + e.statusCode.toString());
        print(e.body);
        print(stacktrace);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Unable to login. Try again.'),
          duration: Duration(seconds: 2),
        ));
      }
    }
  }

  void navigationTapped(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  @override
  void initState() {
    super.initState();
    getPref();
    getdata();
    _pageController = PageController();
  }

  Future<bool> onWillPop() async {
    if (_pageController.page!.round() == _pageController.initialPage) {
      sharedPreferences.setBool("is_app_unlocked", false);
      return true;
    } else {
      _pageController.jumpToPage(_pageController.initialPage);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    var brightness = MediaQuery.of(context).platformBrightness;
    bool darkModeOn = (globals.themeMode == ThemeMode.dark ||
        (brightness == Brightness.dark &&
            globals.themeMode == ThemeMode.system));
    isDesktop = isDisplayDesktop(context);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: darkModeOn ? Colors.transparent : Colors.transparent,
      ),
    );

    if (!isDesktop) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: FlexColorScheme.themedSystemNavigationBar(
          context,
          systemNavBarStyle: FlexSystemNavBarStyle.background,
          useDivider: false,
          opacity: 0,
        ),
        child: WillPopScope(
          onWillPop: () => Future.sync(onWillPop),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            body: PageView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                HomePage(title: "Noter"),
                const ArchivePage(),
                const SearchPage(),
                //const SettingsPage(),
              ],
              onPageChanged: onPageChanged,
              controller: _pageController,
            ),
          ),
        ),
      );
    } else {
      bool isPortrait =
          MediaQuery.of(context).orientation == Orientation.portrait;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: FlexColorScheme.themedSystemNavigationBar(
          context,
          systemNavBarStyle: FlexSystemNavBarStyle.background,
          useDivider: false,
          opacity: 0,
        ),
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // SizedBox(width: 50,),
                Image.asset(
                  //TODO: get app logo
                  '',
                  height: 50,
                ),
                const SizedBox(
                  width: 20,
                ),
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    "Noter",
                    style: GoogleFonts.roboto(),
                  ),
                ),
              ],
            ),
            actions: [
              Visibility(
                visible: viewType == ViewType.Tile && _page == 0,
                child: IconButton(
                  icon: const Icon(Icons.grid_view_outlined),
                  onPressed: () {
                    setState(() {
                      viewType = ViewType.Grid;
                      HomePage.staticGlobalKey.currentState!
                          .toggleView(viewType);
                    });
                  },
                ),
              ),
              Visibility(
                visible: viewType == ViewType.Grid && _page == 0,
                child: IconButton(
                  icon: const Icon(Icons.view_agenda_outlined),
                  onPressed: () {
                    setState(() {
                      viewType = ViewType.Tile;
                      HomePage.staticGlobalKey.currentState!
                          .toggleView(viewType);
                    });
                  },
                ),
              ),
            ],
          ),
          body: PageTransitionSwitcher(
            transitionBuilder: (child, animation, secondaryAnimation) {
              return FadeThroughTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                child: child,
              );
            },
            child: _pageList[_page],
          ),
          bottomNavigationBar: Container(
            margin: isPortrait
                ? const EdgeInsets.only(bottom: 60)
                : const EdgeInsets.only(left: 480, bottom: 60, right: 480),
            child: Card(
              elevation: isPortrait ? 0 : 1,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _page = 0;
                        });
                      },
                      icon: const Icon(Icons.notes_outlined),
                      tooltip: 'Notes',
                      color: _page == 0
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _page = 1;
                        });
                      },
                      icon: const Icon(Icons.archive),
                      tooltip: 'Archive',
                      color: _page == 1
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _page = 2;
                        });
                      },
                      icon: const Icon(Icons.search),
                      tooltip: 'Search',
                      color: _page == 2
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _page = 3;
                        });
                      },
                      icon: const Icon(Icons.menu),
                      tooltip: 'Menu',
                      color: _page == 3
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}

///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2019-03-22 12:43
///
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:openjmu/constants/constants.dart';
import 'package:openjmu/pages/home/marketing_page.dart';
import 'package:openjmu/pages/home/message_page.dart';
import 'package:openjmu/pages/home/post_square_page.dart';
import 'package:openjmu/pages/home/school_work_page.dart';
import 'package:openjmu/pages/home/self_page.dart';

@FFRoute(
  name: 'openjmu://home',
  routeName: '首页',
  argumentNames: <String>['initAction'],
)
class MainPage extends StatefulWidget {
  const MainPage({
    Key key,
    this.initAction,
  }) : super(key: key);

  /// Which page should be loaded at the first init time.
  /// 设置应初始化加载的页面索引
  final int initAction;

  @override
  State<StatefulWidget> createState() => MainPageState();

  /// Widget that placed in main page to open the self page.
  /// 首页顶栏左上角打开个人页的封装部件
  static Widget get selfPageOpener {
    return GestureDetector(
      onTap: Instances.mainPageScaffoldKey.currentState.openDrawer,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(left: 15.w, right: 10.w),
            child: SvgPicture.asset(
              R.ASSETS_ICONS_SELF_PAGE_AVATAR_CORNER_SVG,
              color: currentTheme.iconTheme.color,
              height: 15.w,
            ),
          ),
          const UserAvatar(size: 54.0, canJump: false)
        ],
      ),
    );
  }

  static Widget notificationButton({
    @required BuildContext context,
    bool isTeam = false,
  }) {
    return Consumer<NotificationProvider>(
      builder: (BuildContext _, NotificationProvider provider, Widget __) {
        return SizedBox(
          width: 56.w,
          child: Stack(
            overflow: Overflow.visible,
            children: <Widget>[
              MaterialButton(
                elevation: 0.0,
                minWidth: 56.w,
                height: 56.w,
                padding: EdgeInsets.zero,
                color: context.themeData.canvasColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13.w),
                ),
                child: SvgPicture.asset(
                  R.ASSETS_ICONS_NOTIFICATION_SVG,
                  color: currentTheme.iconTheme.color,
                  width: 24.w,
                ),
                onPressed: () async {
                  provider.stopNotification();
                  await navigatorState.pushNamed(
                    Routes.openjmuNotifications,
                    arguments: <String, dynamic>{
                      'initialPage': isTeam ? '集市' : '广场',
                    },
                  );
                  provider.initNotification();
                },
              ),
              Positioned(
                top: 5.w,
                right: 5.w,
                child: Visibility(
                  visible: isTeam
                      ? provider.showTeamNotification
                      : provider.showNotification,
                  child: ClipRRect(
                    borderRadius: maxBorderRadius,
                    child: Container(
                      width: 12.w,
                      height: 12.w,
                      color: context.themeData.accentColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget publishButton({
    @required BuildContext context,
    @required String route,
  }) {
    return Consumer<ThemesProvider>(
      builder: (_, ThemesProvider provider, __) {
        return MaterialButton(
          color: context.themeData.accentColor,
          elevation: 0.0,
          minWidth: 100.w,
          height: 56.w,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13.w),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          child: Text(
            '发动态',
            style: TextStyle(
              color: adaptiveButtonColor(),
              fontSize: 20.sp,
              height: 1.24,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: () {
            navigatorState.pushNamed(route);
          },
        );
      },
    );
  }
}

class MainPageState extends State<MainPage> with AutomaticKeepAliveClientMixin {
  /// Titles for bottom navigation.
  /// 底部导航的各项标题
  static const List<String> pagesTitle = <String>['广场', '集市', '课业', '消息'];

  /// Icons for bottom navigation.
  /// 底部导航的各项图标
  static const List<String> pagesIcon = <String>[
    R.ASSETS_ICONS_BOTTOM_NAVIGATION_SQUARE_SVG,
    R.ASSETS_ICONS_BOTTOM_NAVIGATION_MARKET_SVG,
    R.ASSETS_ICONS_BOTTOM_NAVIGATION_SCHOOL_WORK_SVG,
    R.ASSETS_ICONS_BOTTOM_NAVIGATION_MESSAGES_SVG,
  ];

  /// Bottom navigation bar's height;
  /// 底部导航的高度
  static const double bottomBarHeight = 72.0;

  /// Base text style for [TabBar].
  /// 顶部Tab的文字样式基类
  static TextStyle get _baseTabTextStyle => TextStyle(
        fontSize: 23.sp,
        textBaseline: TextBaseline.alphabetic,
      );

  /// Selected text style for [TabBar].
  /// 选中的Tab文字样式
  static TextStyle get tabSelectedTextStyle => _baseTabTextStyle.copyWith(
        fontWeight: FontWeight.bold,
      );

  /// Un-selected text style for [TabBar].
  /// 未选中的Tab文字样式
  static TextStyle get tabUnselectedTextStyle => _baseTabTextStyle.copyWith(
        fontWeight: FontWeight.w300,
      );

  /// 是否展示公告
  final ValueNotifier<bool> showAnnouncement = ValueNotifier<bool>(true);

  /// Index for pages.
  /// 当前页面索引
  int _currentIndex;

  /// Icon size for bottom navigation bar's item.
  /// 底部导航的图标大小
  double get bottomBarIconSize => bottomBarHeight / 1.75;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    LogUtils.d('CurrentUser ${UserAPI.currentUser}');

    /// Initialize current page index.
    /// 设定初始页面
    _currentIndex = widget.initAction ??
        Provider.of<SettingsProvider>(currentContext, listen: false)
            .homeSplashIndex;

    /// 进入首屏10秒后，公告默认消失
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(10.seconds, () {
        if (mounted && showAnnouncement.value) {
          showAnnouncement.value = false;
        }
      });
    });

    Instances.eventBus.on<ActionsEvent>().listen((ActionsEvent event) {
      /// Listen to actions event to react with quick actions both on Android and iOS.
      /// 监听原生捷径时间以切换页面
      final int index =
          Constants.quickActionsList.keys.toList().indexOf(event.type);
      if (index != -1) {
        _selectedTab(index);
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  /// Method to update index.
  /// 切换页面方法
  void _selectedTab(int index) {
    if (index == _currentIndex) {
      return;
    }
    setState(() => _currentIndex = index);
  }

  /// Announcement widget.
  /// 公告组件
  Widget announcementWidget(BuildContext context) {
    if (!context.select<SettingsProvider, bool>(
      (SettingsProvider p) => p.announcementsEnabled,
    )) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: showAnnouncement,
      builder: (_, bool isShowing, __) {
        final Map<String, dynamic> announcement = context
            .read<SettingsProvider>()
            .announcements[0] as Map<String, dynamic>;
        return AnimatedPositioned(
          duration: 1.seconds,
          curve: Curves.fastLinearToSlowEaseIn,
          bottom: isShowing ? 0.0 : -72.w,
          left: 0.0,
          right: 0.0,
          height: 72.w,
          child: GestureDetector(
            onTap: () {
              ConfirmationDialog.show(
                context,
                title: announcement['title'] as String,
                content: announcement['content'] as String,
                cancelLabel: '朕已阅',
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.w),
                  topRight: Radius.circular(20.w),
                ),
                color: context.themeData.colorScheme.primary,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      announcement['title'] as String,
                      style: TextStyle(
                        color: adaptiveButtonColor(),
                        fontSize: 19.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (showAnnouncement.value) {
                        showAnnouncement.value = false;
                      }
                    },
                    child: Icon(
                      Icons.keyboard_arrow_down_sharp,
                      color: adaptiveButtonColor(),
                      size: 40.w,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Bottom navigation bar.
  /// 底部导航栏
  Widget bottomNavigationBar(BuildContext context) {
    return FABBottomAppBar(
      color: Colors.grey[600].withOpacity(currentIsDark ? 0.8 : 0.4),
      height: bottomBarHeight,
      iconSize: bottomBarIconSize,
      selectedColor: context.themeData.accentColor,
      itemFontSize: 16.0,
      onTabSelected: _selectedTab,
      showText: false,
      initIndex: _currentIndex,
      items: List<FABBottomAppBarItem>.generate(
        pagesTitle.length,
        (int i) => FABBottomAppBarItem(
          iconPath: pagesIcon[i],
          text: pagesTitle[i],
        ),
      ),
    );
  }

  @override
  @mustCallSuper
  Widget build(BuildContext context) {
    super.build(context);
    return WillPopScope(
      onWillPop: () async {
        if (Instances.mainPageScaffoldKey.currentState.isDrawerOpen) {
          Instances.mainPageScaffoldKey.currentState.openEndDrawer();
          return false;
        } else {
          return doubleBackExit();
        }
      },
      child: Scaffold(
        key: Instances.mainPageScaffoldKey,
        body: Stack(
          children: <Widget>[
            IndexedStack(
              children: <Widget>[
                const PostSquarePage(),
                const MarketingPage(),
                SchoolWorkPage(key: Instances.schoolWorkPageStateKey),
                const MessagePage(),
              ],
              index: _currentIndex,
            ),
            announcementWidget(context),
          ],
        ),
        drawer: SelfPage(),
        drawerEdgeDragWidth: Screens.width * 0.0666,
        bottomNavigationBar: bottomNavigationBar(context),
        resizeToAvoidBottomInset: false,
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:glutassistant/Common/Constant.dart';
import 'package:glutassistant/Utility/FileUtil.dart';
import 'package:glutassistant/Utility/SharedPreferencesUtil.dart';
import 'package:image_picker/image_picker.dart';

enum ScoreType { exam, fitness }
enum BackgroundImage { disable, enable }
enum DashboardType { card, timeline }
enum CampusType { yanshan, pingfeng }

class GlobalData with ChangeNotifier {
  SharedPreferenceUtil su;

  TextEditingController _currentWeekController = TextEditingController();
  TextEditingController _opacityController = TextEditingController();

  TextEditingController get currentWeekController => _currentWeekController;
  TextEditingController get opacityController => _opacityController;

  ScoreType _scoreType = ScoreType.exam;
  int _themeColorIndex = 0;
  int _selectedPage = 1;
  int _currentWeek = 1;
  int _selectedWeek = 1;
  double _opacity = Constant.VAR_DEFAULT_OPACITY;
  BackgroundImage _backgroundEnable = BackgroundImage.disable;
  DashboardType _dashboardType = DashboardType.timeline;
  CampusType _campusType = CampusType.yanshan;
  String _cookie = '';

  String _firstWeek = '';
  String _firstWeekTimestamp = '';
  String _currentWeekStr = '';

  String _msg = '';

  ScoreType get scoreType => _scoreType;
  double get opacity => _opacity;
  int get themeColorIndex => _themeColorIndex;
  int get selectedWeek => _selectedWeek;
  int get currentWeek => _currentWeek;
  int get selectedPage => _selectedPage;
  DashboardType get dashboardType => _dashboardType;
  BackgroundImage get backgroundEnable => _backgroundEnable;
  CampusType get campusType => _campusType;
  String get cookie => _cookie;

  String get firstWeek => _firstWeek;
  String get firstWeekTimestamp => _firstWeekTimestamp;
  String get currentWeekStr => _currentWeekStr;

  String get msg => _msg;

  set scoreType(ScoreType scoreType) {
    if (_scoreType == scoreType) return;
    _scoreType = scoreType;
    notifyListeners();
  }

  set selectedWeek(int selectedWeek) {
    if (_selectedWeek == selectedWeek) return;
    _selectedWeek = selectedWeek;
    notifyListeners();
  }

  set currentWeek(int currentWeek) {
    if (_currentWeek == currentWeek) return;
    _currentWeek = currentWeek;
    notifyListeners();
  }

  set selectedPage(int selectedPage) {
    if (_selectedPage == selectedPage) return;
    _selectedPage = selectedPage;
    notifyListeners();
  }

  Future<void> setBackgroundEnable(bool backgroundEnable) async {
    BackgroundImage tmp =
        backgroundEnable ? BackgroundImage.enable : BackgroundImage.disable;
    if (_backgroundEnable == tmp) return;
    _backgroundEnable = tmp;
    notifyListeners();
    print(_backgroundEnable);
    su.setBool(
        'background_enable', _backgroundEnable == BackgroundImage.enable);
  }

  Future<void> setDashboardType(int dashboardType) async {
    DashboardType tmp =
        dashboardType == 0 ? DashboardType.card : DashboardType.timeline;
    if (_dashboardType == tmp) return;
    _dashboardType = tmp;
    notifyListeners();
    su.setInt('dashboard_type', _dashboardType == DashboardType.card ? 0 : 1);
  }

  Future<void> setCampusType(int campusType) async {
    CampusType tmp = campusType == 0 ? CampusType.yanshan : CampusType.pingfeng;
    if (_campusType == tmp) return;
    _campusType = tmp;
    notifyListeners();
    su.setInt('campus_type', campusType);
  }

  Future<void> setThemeColorIndex(int themeColorIndex) async {
    if (_themeColorIndex == themeColorIndex) return;
    _themeColorIndex = themeColorIndex;
    notifyListeners();
    su.setInt('theme_color', themeColorIndex);
  }

  Future<void> setOpacity() async {
    if (_opacity == double.parse(_opacityController.text.trim())) return;
    _opacity = double.parse(_opacityController.text.trim());
    notifyListeners();
    su.setDouble('opacity', double.parse(_opacityController.text.trim()));
  }

  Future<void> setCurrentWeek() async {
    if (currentWeekStr == _currentWeekController.text.trim()) return;
    _currentWeekStr = _currentWeekController.text.trim();
    notifyListeners();
    su.setString('first_week', _currentWeekController.text.trim());
    su.setString('first_week_timestamp',
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString());
  }

  Future<void> saveImage() async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);
    FileUtil fu = await FileUtil.getInstance();
    if (image != null) {
      image.copy(fu.getDir() + '/' + Constant.FILE_BACKGROUND_IMG);
      _msg = '你可能需要重新启动本APP使得背景图修改生效';
    } else
      _msg = '读取照片失败啦，未知原因';
  }

  Future<void> refreshGlobal() async {
    su = await SharedPreferenceUtil.getInstance();
    _themeColorIndex = await su.getInt('theme_color');
    _opacity = await su.getDouble('opacity');
    _firstWeekTimestamp = await su.getString('first_week_timestamp');
    if (_firstWeekTimestamp == '') _firstWeekTimestamp = '1';

    _dashboardType = await su.getInt('dashboard_type') == 0
        ? DashboardType.card
        : DashboardType.timeline;

    _currentWeekStr = await su.getString('first_week');
    if (_currentWeekStr == '') _currentWeekStr = '1';

    DateTime _now = DateTime.now();
    DateTime _startWeek = DateTime(_now.year, _now.month, _now.day)
        .subtract(Duration(days: _now.weekday - 1));
    _currentWeek = (((_startWeek.millisecondsSinceEpoch / 1000 -
                    int.parse(_firstWeekTimestamp)) ~/
                25200 /
                24)
            .ceil() +
        int.parse(_currentWeekStr));
    if (_currentWeek > 25) _currentWeek = 1;
    _selectedWeek = _currentWeek;
    _currentWeekStr = _currentWeek > 25 ? '1' : _currentWeek.toString();
    _backgroundEnable = await su.getBool('background_enable')
        ? BackgroundImage.enable
        : BackgroundImage.disable;

    _opacity = _backgroundEnable == BackgroundImage.enable
        ? await su.getDouble('opacity')
        : 1.0; // 透明度尽在开启背景图时生效

    _campusType = await su.getInt('campus_type') == 0
        ? CampusType.yanshan
        : CampusType.pingfeng;

    notifyListeners();
  }
}

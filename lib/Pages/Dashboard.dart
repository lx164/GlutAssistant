import 'dart:math';

import 'package:flutter/material.dart';
import 'package:glutassistant/Common/Constant.dart';
import 'package:glutassistant/Utility/BalanceUtil.dart';
import 'package:glutassistant/Utility/SQLiteUtil.dart';
import 'package:glutassistant/Utility/SharedPreferencesUtil.dart';
import 'package:glutassistant/Widget/DetailCard.dart';
import 'package:glutassistant/Widget/SnackBar.dart';

class Dashboard extends StatefulWidget {
  final int _week;
  Dashboard(this._week);
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _weekday = DateTime.now().weekday;
  bool _isLoading = false;
  double _opacity = Constant.VAR_DEFAULT_OPACITY;

  Map<String, dynamic> _balance = {'balance': '未知', 'lastupdate': '从未更新'};
  List<Map<String, dynamic>> _courseList = [];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _buildBody(),
    );
  }

  @override
  void initState() {
    _init();
    super.initState();
  }

  Widget _buildBalanceArea() {
    Widget child = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Positioned(
          top: 0,
          left: 0,
          child: Text('一卡通余额', style: TextStyle(color: Colors.white)),
        ),
        _buildBalanceText(),
        Positioned(
          bottom: 0,
          right: 0,
          child: Row(
            children: <Widget>[
              Text(
                '${_balance['lastupdate']}',
                style: TextStyle(color: Colors.white),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLoading = true;
                  });
                  BalanceUtil.refreshBalance().then((onValue) {
                    setState(() {
                      _balance = onValue;
                    });
                    CommonSnackBar.buildSnackBar(context, _balance['msg']);
                    setState(() {
                      _isLoading = false;
                    });
                  });
                },
                child: Icon(
                  Icons.sync,
                  color: Colors.white,
                ),
              )
            ],
          ),
        )
      ],
    );
    Color color = Color(
        Constant.VAR_COLOR[Random.secure().nextInt(Constant.VAR_COLOR.length)]);
    return DetailCard(color, child);
  }

  Widget _buildBalanceText() {
    if (_isLoading) return CircularProgressIndicator();
    return Text(
      '￥${_balance['balance']}',
      style: TextStyle(fontSize: 40, color: Colors.white),
    );
  }

  List<Widget> _buildBody() {
    List<Widget> mainBody = [];
    mainBody = _buildCourseList();
    mainBody.add(_buildBalanceArea());
    return mainBody;
  }

  List<Widget> _buildCourseList() {
    List<Widget> todayCourseList = [];
    if (_courseList.length > 0) {
      for (int i = 0; i < _courseList.length; i++) {
        int startTime = _courseList[i]['startTime'];
        int endTime = _courseList[i]['endTime'];
        String startTimeStr = startTime.toString();
        String endTimeStr = endTime.toString();
        if (startTime > 4) {
          if (startTime >= 5 && startTime <= 6)
            startTimeStr = '中午' + (startTime - 4).toString();
          else
            startTimeStr = (startTime - 2).toString();
        }
        if (endTime > 4) {
          if (endTime >= 5 && endTime <= 6)
            endTimeStr = '中午' + (endTime - 4).toString();
          else
            endTimeStr = (endTime - 2).toString();
        }
        Widget child = Row(
          children: <Widget>[
            Container(
                padding: EdgeInsets.fromLTRB(1, 0, 10, 0),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.access_time,
                      color: Color(0xff4090f7),
                      size: 25,
                    ),
                    Text(
                      '$startTimeStr - $endTimeStr节',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    )
                  ],
                )),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  child: Row(children: <Widget>[
                    Icon(
                      Icons.class_,
                      color: Color(0xff4090f7),
                      size: 25,
                    ),
                    Expanded(
                        child: Text(
                      _courseList[i]['course'],
                      style: TextStyle(fontSize: 20, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ))
                  ]),
                ),
                Container(
                  child: Row(children: <Widget>[
                    Icon(
                      Icons.location_on,
                      color: Color(0xff4090f7),
                      size: 25,
                    ),
                    Text(
                      _courseList[i]['location'],
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    )
                  ]),
                )
              ],
            ))
          ],
        );
        Color color = Color(Constant
            .VAR_COLOR[Random.secure().nextInt(Constant.VAR_COLOR.length)]);
        DetailCard course = DetailCard(color, child);
        todayCourseList.add(course);
      }
    } else {
      Color color = Color(Constant
          .VAR_COLOR[Random.secure().nextInt(Constant.VAR_COLOR.length)]);
      todayCourseList.add(DetailCard(
          color,
          Text(
            '今天没有课上哦(๑˙ー˙๑)',
            style: TextStyle(fontSize: 20),
          )));
    }
    return todayCourseList;
  }

  void _init() async {
    await BalanceUtil.init();
    setState(() {
      _balance = BalanceUtil.getCacheBalance();
    });
    await SharedPreferenceUtil.init();
    _opacity = await SharedPreferenceUtil.getDouble('opacity');
    setState(() {
      _opacity ??= Constant.VAR_DEFAULT_OPACITY;
    });
    await SQLiteUtil.init();
    await SQLiteUtil.queryCourse(widget._week, _weekday).then((onValue) {
      if (onValue.length > 0) {
        for (int i = 0; i < onValue.length; i++) {
          Map<String, dynamic> courseDetail = {};
          courseDetail['course'] = onValue[i]['courseName'];
          courseDetail['location'] = onValue[i]['location'];
          courseDetail['startTime'] = onValue[i]['startTime'];
          courseDetail['endTime'] = onValue[i]['endTime'];
          _courseList.add(courseDetail);
        }
      }
      setState(() {
        _courseList;
      });
    });
  }
}

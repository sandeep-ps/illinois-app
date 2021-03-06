/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/model/UserData.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events/CompositeEventsDetailPanel.dart';
import 'package:illinois/ui/events/EventsSchedulePanel.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/explore/ExploreConvergeDetailItem.dart';
import 'package:location/location.dart' as Core;
import 'package:illinois/service/User.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/model/Dining.dart';
import 'package:illinois/model/Event.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

class ExploreCard extends StatefulWidget {
  final GestureTapCallback onTap;
  final Explore explore;
  final Core.LocationData locationData;
  final bool showTopBorder;
  final bool hideInterests;
  final bool showSmallImage;
  final String source;
  final double horizontalPadding;
  final BoxBorder border;

  ExploreCard(
      {Key key, this.onTap, this.explore, this.locationData, this.showTopBorder = false, this.showSmallImage = true, this.hideInterests = false, this.source, this.horizontalPadding=16, this.border})
      : super(key: key);

  @override
  _ExploreCardState createState() => _ExploreCardState();
}

class _ExploreCardState extends State<ExploreCard> implements NotificationsListener {

  static const EdgeInsets _detailPadding = EdgeInsets.only(bottom: 8, left: 16, right: 16);
  static const EdgeInsets _iconPadding = EdgeInsets.only(right: 8);
  static const double _smallImageSize = 64;

  @override
  void initState() {
    NotificationService().subscribe(this, User.notifyFavoritesUpdated);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  String get semanticLabel {
    dynamic explore = widget.explore;
    String category = ((explore is Event) ? explore.category : null) ?? "";
    String title = widget?.explore?.exploreTitle ?? "";
    String time = _getEventTimeDisplayString();
    String locationText = ExploreHelper.getShortDisplayLocation(widget.explore, widget.locationData) ?? "";
    String workTime = ((explore is Dining) ? explore.displayWorkTime : null) ?? "";
    int eventConvergeScore = (explore is Event) ? explore.convergeScore : null;
    String convergeScore = ((eventConvergeScore != null) ? (eventConvergeScore.toString() + '%') : null) ?? "";
    String interests = ((explore is Event) ? _getInterestsLabelValue() : null) ?? "";
    interests = interests.isNotEmpty ? interests.replaceRange(0, 0, Localization().getStringEx('widget.card.label.interests', 'Because of your interest in:')) : "";

    return "$category, $title, $time, $locationText, $workTime, $convergeScore, $interests";
  }

  @override
  Widget build(BuildContext context) {
    bool isEvent = (widget.explore is Event);
    Event event = isEvent ? widget.explore as Event : null;
    bool isCompositeEvent = event?.isComposite ?? false;
    String imageUrl = AppString.getDefaultEmptyString(value: widget.explore.exploreImageURL);
    String interestsLabelValue = _getInterestsLabelValue();

    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Semantics(
          label: semanticLabel,
//          excludeSemantics: true,
          child: Stack(alignment: Alignment.bottomCenter, children: <Widget>[Padding(padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),child: Stack(
              alignment: Alignment.topCenter,
              children: [
                ExcludeSemantics(
                  child:Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        border: widget.border
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _exploreTop(),
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Visibility(
                                visible: isEvent,
                                child: _exploreName(),
                              ),
                              _exploreDetails(),
                            ],)),
                          Visibility(visible: (widget.showSmallImage &&
                              AppString.isStringNotEmpty(imageUrl)),
                              child: Padding(
                                padding: EdgeInsets.only(left: 16, right: 16, bottom: 4),
                                child: SizedBox(
                                  width: _smallImageSize,
                                  height: _smallImageSize,
                                  child: Image.network(
                                    imageUrl, fit: BoxFit.fill, headers: AppImage.getAuthImageHeaders(),),),)),
                        ],),
                        _explorePaymentTypes(),
                        _buildConvergeButton(),
                        Visibility(visible: _showInterests(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  height: 1, color: Styles().colors.surfaceAccent,),
                                Padding(padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: <Widget>[
                                        Flexible(flex: 8,
                                          child: Container(width: double.infinity, child:
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(Localization().getStringEx(
                                                  'widget.card.label.interests',
                                                  'Because of your interest in:'),
                                                style: TextStyle(
                                                    color: Styles().colors.textBackground,
                                                    fontSize: 12,
                                                    fontFamily: Styles().fontFamilies.bold),),
                                              Text(AppString.getDefaultEmptyString(
                                                  value: interestsLabelValue), style: TextStyle(
                                                  color: Styles().colors.textBackground,
                                                  fontSize: 12,
                                                  fontFamily: Styles().fontFamilies.medium),)
                                            ],)),
                                        ),
                                        Flexible(flex: 2,
                                          child: Container(width: double.infinity, alignment: Alignment.centerRight,
                                              child: ExploreConvergeDetailItem(eventConvergeScore: _getConvergeScore(), eventConvergeUrl: _getConvergeUrl(),)

                                          ),
                                        )
                                      ],
                                    ))
                              ],)),
                        Visibility(visible: isCompositeEvent, child: Container(height: _EventSmallCard._cardHeight,),)
                      ],
                    ),
                  ),
                ),
                _topBorder(),
              ]),),
            _buildCompositeEventsContent(isCompositeEvent)
          ],),
        ));
  }

  bool _showInterests() {
    String interestsLabelValue = _getInterestsLabelValue();
    return (widget.explore is Event) && AppString.isStringNotEmpty(interestsLabelValue);
  }

  bool _hasConvergeUrl() {
    return AppString.isStringNotEmpty(_getConvergeUrl());
  }

  bool _hasConvergeScore() {
    return (_getConvergeScore() != null) && (_getConvergeScore() > 0);
  }

  bool _hasConvergeContent() {
    return _hasConvergeScore() || _hasConvergeUrl();
  }

  Widget _buildConvergeButton() {
    if(_showInterests() || !_hasConvergeContent())
      return Container();

    return Container( width: double.infinity, child:Column(
      children:<Widget>[
         _divider(),
        Padding (padding: EdgeInsets.only(left: 16, top: 10), child:
          ExploreConvergeDetailButton(eventConvergeScore: _getConvergeScore(), eventConvergeUrl: _getConvergeUrl(),)
        )
      ]
    ));
  }

  int _getConvergeScore() {
    Event event = (widget.explore is Event) ? (widget.explore as Event) : null;
    int eventConvergeScore = (event != null) ? event.convergeScore : null;
    return eventConvergeScore;
  }

  String _getConvergeUrl() {
    Event event = (widget.explore is Event) ? (widget.explore as Event) : null;
    String eventConvergeUrl = (event != null) ? event.convergeUrl : null;
    return eventConvergeUrl;
  }

  Widget _exploreTop() {

    Event event = (widget.explore is Event) ? (widget.explore as Event) : null;
    bool isFavorite = User().isExploreFavorite(widget.explore);
    bool starVisible = User().favoritesStarVisible;
    String leftLabel = "";
    TextStyle leftLabelStyle;
    if (event != null) {
      leftLabel = event?.category;
      leftLabel = (leftLabel != null) ? leftLabel.toUpperCase() : "";
      leftLabelStyle = TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 14, letterSpacing: 0.86, color: Styles().colors.fillColorPrimary);
    } else {
      leftLabel = widget.explore.exploreTitle ?? "";
      leftLabelStyle = TextStyle(fontSize: 18, color: Styles().colors.fillColorPrimary);
    }

    return Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 19, bottom: 12),
              child: Text(
                leftLabel,
                style: leftLabelStyle,
              )
            ),
          ),
          Visibility(visible: starVisible, child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onTapExploreCardStar,
              child: Semantics(
                  label: isFavorite ? Localization().getStringEx(
                      'widget.card.button.favorite.off.title',
                      'Remove From Favorites') : Localization().getStringEx(
                      'widget.card.button.favorite.on.title',
                      'Add To Favorites'),
                  hint: isFavorite ? Localization().getStringEx(
                      'widget.card.button.favorite.off.hint', '') : Localization()
                      .getStringEx('widget.card.button.favorite.on.hint', ''),
                  button: true,
                  excludeSemantics: true,
                  child: Container(child: Padding(padding: EdgeInsets.only(
                      right: 16, top: 12, left: 24, bottom: 5),
                      child: Image.asset(isFavorite
                          ? 'images/icon-star-selected.png'
                          : 'images/icon-star.png')
                  ))
              )),)
        ],
    );
  }

  Widget _exploreName() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Text(
        (widget.explore.exploreTitle != null) ? widget.explore.exploreTitle : "",
        style:
        TextStyle(fontSize: 20,
            color: Styles().colors.fillColorPrimary),
      ),
    );
  }

  Widget _exploreDetails() {
    List<Widget> details = new List<Widget>();

    Widget time = _exploreTimeDetail();
    if (time != null) {
      details.add(time);
    }

    Widget location = _exploreLocationDetail();
    if (location != null) {
      details.add(location);
    }

    Widget workTime = _exploreWorkTimeDetail();
    if (workTime != null) {
      details.add(workTime);
    }

    return (0 < details.length)
        ? Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details))
        : Container();
  }

  Widget _exploreTimeDetail() {
    String displayTime = _getEventTimeDisplayString();
    if (AppString.isStringEmpty(displayTime)) {
      return null;
    }
    return Semantics(label: displayTime, child: Padding(
      padding: _detailPadding,
      child: Row(
        children: <Widget>[
          Image.asset('images/icon-calendar.png'),
          Padding(
            padding: _iconPadding,
          ),
          Flexible(child: Text(displayTime, overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                  fontFamily: Styles().fontFamilies.medium,
                  fontSize: 14,
                  color: Styles().colors.textBackground)),)
        ],
      ),
    ));
  }

  Widget _exploreLocationDetail() {
    String locationText = ExploreHelper.getShortDisplayLocation(widget.explore, widget.locationData);
    if ((locationText != null) && locationText.isNotEmpty) {
      return Semantics(label: locationText, child:Padding(
        padding: _detailPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Image.asset('images/icon-location.png'),
            Padding(
              padding: _iconPadding,
            ),
            Expanded(child: Text(locationText,
                style: TextStyle(
                    fontFamily: Styles().fontFamilies.medium,
                    fontSize: 14,
                    color: Styles().colors.textBackground))),
          ],
        ),
      ));
    } else {
      return null;
    }
  }

  Widget _exploreWorkTimeDetail() {
    Dining dining = (widget.explore is Dining) ? (widget.explore as Dining) : null;
    String displayTime = dining?.displayWorkTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Semantics(label: displayTime, child:Padding(
        padding: _detailPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Image.asset('images/icon-time.png'),
            Padding(
              padding: _iconPadding,
            ),
            Expanded(
              child: Text(displayTime,
                  style: TextStyle(
                      fontFamily: Styles().fontFamilies.medium,
                      fontSize: 14,
                      color: Styles().colors.textBackground)),
            ),
          ],
        ),
      ));
    } else {
      return Container();
    }
  }

  Widget _explorePaymentTypes() {
    List<Widget> details;
    Dining dining = (widget.explore is Dining) ? (widget.explore as Dining) : null;
    List<PaymentType> paymentTypes = dining?.paymentTypes;
    if ((paymentTypes != null) && (0 < paymentTypes.length)) {
      details = new List<Widget>();
      for (PaymentType paymentType in paymentTypes) {
        Image image = PaymentTypeHelper.paymentTypeIcon(paymentType);
        if (image != null) {
          details.add(Padding(padding: EdgeInsets.only(right: 6) ,child:image) );
        }
      }
    }
      return ((details != null) && (0 < details.length)) ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _divider(),
              Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: details))
              
            ])
        
        : Container();
  }

  String _getEventTimeDisplayString() {
    Explore explore = widget.explore;
    return (explore is Event) ? explore.timeDisplayString : '';
  }

  Widget _divider(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: Container(
        height: 1,
        color: Styles().colors.fillColorPrimaryTransparent015,
      ),
    );
  }

  Widget _topBorder() {
    return widget.showTopBorder? Container(height: 7,color: widget.explore.uiColor) : Container();
  }

  String _getInterestsLabelValue() {
    return (!widget.hideInterests && (widget.explore is Event)) ? ((widget.explore as Event).displayInterests) : "";
  }

  Widget _buildCompositeEventsContent(bool isCompositeEvent) {
    if (!isCompositeEvent) {
      return Container();
    }
    Event parentEvent = widget.explore as Event;
    List<Event> subEvents = parentEvent.recurringEvents ?? parentEvent.featuredEvents;
    bool showViewMoreCard = AppCollection.isCollectionNotEmpty(subEvents);
    if (showViewMoreCard && (subEvents != null) && (subEvents.length > 5)) {
      subEvents = subEvents.sublist(0, 5);
    }
    _EventCardType type = parentEvent.isSuperEvent ? _EventCardType.sup : _EventCardType.rec;
    int eventsCount = (subEvents != null) ? subEvents.length : 0;
    int itemsCount = eventsCount + (showViewMoreCard ? 3 : 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding), child: _divider(),),
        Container(height: _EventSmallCard._cardHeight, padding: EdgeInsets.symmetric(vertical: 16), child: ListView.separated(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          separatorBuilder: (context, index) =>
              Container(color: Colors.transparent, width: 8),
          itemCount: itemsCount,
          itemBuilder: (context, index) {
            if (index == 0 || index == itemsCount - 1) {
              return Container(width: 24);
            } else if (showViewMoreCard && (index == itemsCount - 2)) {
              return _EventSmallCard(
                type: _EventCardType.more, onTap: () => _onTapSmallExploreCard(context: context, parentEvent: parentEvent, cardType: _EventCardType.more),);
            }
            Event subEvent = subEvents[index - 1];
            return _EventSmallCard(event: subEvent,
              type: type,
              onTap: () => _onTapSmallExploreCard(context: context, parentEvent: parentEvent, subEvent: subEvent, cardType: type),);
          },
        ),),
      ],);
  }

  void _onTapExploreCardStar() {
    Analytics.instance.logSelect(target: "ExploreCard mark favorite explore: ${widget.explore.exploreId}");
    Event event = (widget.explore is Event) ? (widget.explore as Event) : null;
    if (event?.isRecurring ?? false) {
      if (User().isExploreFavorite(event)) {
        User().removeAllFavorites(event.recurringEvents);
      } else {
        User().addAllFavorites(event.recurringEvents);
      }
    } else {
      Favorite favorite = widget.explore is Favorite ? widget.explore as Favorite : null;
      User().switchFavorite(favorite);
    }
  }

  void _onTapSmallExploreCard({BuildContext context, _EventCardType cardType, Event parentEvent, Event subEvent}) {
    if (cardType == _EventCardType.more) {
      if (parentEvent.isSuperEvent == true) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => EventsSchedulePanel(superEvent: parentEvent)));
      } else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => CompositeEventsDetailPanel(parentEvent: parentEvent,)));
      }
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => ExploreEventDetailPanel(event: subEvent, superEventTitle: parentEvent.title)));
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == User.notifyFavoritesUpdated) {
      setState(() {});
    }
  }
}

class _EventSmallCard extends StatelessWidget {
  static final double _cardWidth = 212;
  static final double _cardHeight = 144;

  final Event event;
  final _EventCardType type;
  final GestureTapCallback onTap;

  _EventSmallCard({this.event, this.type, this.onTap});

  @override
  Widget build(BuildContext context) {
    bool isMoreCardType = (type == _EventCardType.more);
    Favorite favorite = event is Favorite ? event : null;
    bool isFavorite = User().isFavorite(favorite);
    bool starVisible = User().favoritesStarVisible && !isMoreCardType;
    double borderWidth = 1.0;
    double topBorderHeight = 4;
    double internalPadding = 16;
    double internalWidth = _cardWidth - (borderWidth * 2 + internalPadding * 2);
    double internalHeight = _cardHeight - (borderWidth * 2 + internalPadding * 4 + topBorderHeight);
    return GestureDetector(onTap: onTap, child: Semantics(
        label: _semanticLabel,
        excludeSemantics: true,
        child: Container(
          width: _cardWidth,
          height: _cardHeight,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)), border: Border.all(
              color: Styles().colors.surfaceAccent, width: borderWidth)),
          child: Column(children: <Widget>[
            Container(height: topBorderHeight, color: Styles().colors.fillColorSecondary),
            Padding(padding: EdgeInsets.all(internalPadding),
              child: SizedBox(height: internalHeight, width: internalWidth, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Expanded(child: Text(_title, overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(fontSize: 20, color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.extraBold),),),
                    Visibility(
                      visible: starVisible, child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          String favoriteId = favorite?.favoriteId;
                          Analytics.instance.logSelect(target: "ExploreCard mark favorite explore: $favoriteId");
                          User().switchFavorite(favorite);
                        },
                        child: Semantics(
                            label: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') : Localization()
                                .getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                            hint: isFavorite ? Localization().getStringEx('widget.card.button.favorite.off.hint', '') : Localization().getStringEx(
                                'widget.card.button.favorite.on.hint', ''),
                            button: true,
                            excludeSemantics: true,
                            child: Container(child: Padding(padding: EdgeInsets.only(left: 24, bottom: 5), child: Image.asset(
                                isFavorite ? 'images/icon-star-selected.png' : 'images/icon-star.png')
                            ))
                        )),),
                    Visibility(visible: isMoreCardType, child: Padding(
                      padding: EdgeInsets.only(left: 24, top: 4), child: Image.asset('images/chevron-right.png'),),)
                  ],),),
                Visibility(visible: !isMoreCardType, child: Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
                  Padding(padding: EdgeInsets.only(right: 10),
                    child: Image.asset('images/icon-time.png'),),
                  Expanded(child: Text(_subTitle, overflow: TextOverflow.ellipsis, maxLines: 1, style: TextStyle(
                      fontSize: 16, color: Styles().colors.textBackground, fontFamily: Styles().fontFamilies.medium),),)
                ],),)
              ],),),),
          ],),)),);
  }

  String get _semanticLabel {
    String title = _title;
    String subTitle = _subTitle;
    return "$title, $subTitle";
  }

  String get _title {
    switch (type) {
      case _EventCardType.sup:
        return event.title;
      case _EventCardType.rec:
        return event.displayDate;
      case _EventCardType.more:
        return Localization().getStringEx('widget.explore_card.small.view_all.title', 'View all events');
      default:
        return '';
    }
  }

  String get _subTitle {
    switch (type) {
      case _EventCardType.sup:
        return event.displaySuperTime;
      case _EventCardType.rec:
        return event.displayStartEndTime;
      default:
        return '';
    }
  }
}

enum _EventCardType { sup, rec, more }
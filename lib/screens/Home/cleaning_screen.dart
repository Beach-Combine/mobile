import 'dart:async';

import 'package:beach_combine/common/beach_combine.dart';
import 'package:beach_combine/controllers/map_controller.dart';
import 'package:beach_combine/controllers/time_controller.dart';
import 'package:beach_combine/data.dart';
import 'package:beach_combine/screens/Home/camera_screen.dart';
import 'package:beach_combine/screens/Home/method_select_screen.dart';
import 'package:beach_combine/utils/app_style.dart';
import 'package:beach_combine/widgets/primary_button.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../controllers/range_controller.dart';

class CleaningScreen extends StatefulWidget {
  CleaningScreen({super.key, required this.isTest});

  final bool isTest;
  @override
  CleaningScreennState createState() => CleaningScreennState();
}

class CleaningScreennState extends State<CleaningScreen> {
  GoogleMapController? mapController;
  Position? currentPosition;
  Set<Marker> markers = {};
  StreamSubscription? stream;
  final timecontroller = Get.put(TimerController());
  final rangeController = Get.put(LocationController());
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;
  Future<void> setCustomMarkerIcon() async {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), "assets/icons/current_location.png")
        .then(
      (icon) {
        setState(() {
          currentLocationIcon = icon;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    setCustomMarkerIcon();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    stream!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: currentPosition == null
            ? Center(child: Text('loading'))
            : Stack(children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.isTest
                        ? LatLng(
                            currentPosition!.latitude -
                                Get.find<MapController>().testLatDiffer,
                            currentPosition!.longitude -
                                Get.find<MapController>().testLngDiffer)
                        : LatLng(currentPosition!.latitude,
                            currentPosition!.longitude),
                    zoom: 15,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                  markers: markers,
                ),
                Align(
                    alignment: Alignment.bottomCenter,
                    child: _BottomSheetCleaning(
                      timecontroller: timecontroller,
                      isTest: widget.isTest,
                    )),
                Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => Get.offAll(BeachCombine()),
                      child: Container(
                        width: 220,
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(50)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/back_home.png',
                              width: 20,
                            ),
                            Gap(8),
                            Text(
                              'Stop and go home',
                              style: Styles.body22Text
                                  .copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ]),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      rangeController.updateLocation(position);
      currentPosition = position;
      markers.add(
        Marker(
          icon: currentLocationIcon,
          markerId: MarkerId('current_position'),
          position: widget.isTest
              ? LatLng(
                  position.latitude - Get.find<MapController>().testLatDiffer,
                  position.longitude - Get.find<MapController>().testLngDiffer)
              : LatLng(position.latitude, position.longitude),
        ),
      );
    });

    final Stream<Position> positionStream = Geolocator.getPositionStream();
    stream = positionStream.listen((Position position) {
      setState(() {
        rangeController.updateLocation(position);
        currentPosition = position;
        markers.removeWhere(
            (marker) => marker.markerId.value == 'current_position');
        markers.add(
          Marker(
            icon: currentLocationIcon,
            markerId: MarkerId('current_position'),
            position: widget.isTest
                ? LatLng(
                    position.latitude - Get.find<MapController>().testLatDiffer,
                    position.longitude -
                        Get.find<MapController>().testLngDiffer)
                : LatLng(position.latitude, position.longitude),
          ),
        );
      });
    });
  }
}

class _BottomSheetCleaning extends StatefulWidget {
  const _BottomSheetCleaning({
    Key? key,
    required this.timecontroller,
    required this.isTest,
  }) : super(key: key);
  final bool isTest;

  final TimerController timecontroller;

  @override
  State<_BottomSheetCleaning> createState() => _BottomSheetCleaningState();
}

class _BottomSheetCleaningState extends State<_BottomSheetCleaning> {
  distanceCarculate() {
    final dist = Get.find<LocationController>().distance;
    return dist >= 1000
        ? '${(dist / 1000).toStringAsFixed(2)} km'
        : '${dist.round()} m';
  }

  late DateTime _start;
  late Timer _timer;

  @override
  Widget build(BuildContext context) {
    return Wrap(children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/icons/location_black.png',
                    width: 15,
                  ),
                  Gap(5),
                  Text(
                    'Gwangalli Beach',
                    style: Styles.body12Text,
                  ),
                ],
              ),
              Gap(20),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: Styles.body21Text
                            .copyWith(color: Styles.gray1Color),
                      ),
                      Obx(() => Text(
                            '${widget.timecontroller.hoursString.value}:${widget.timecontroller.minuteString.value}:${widget.timecontroller.secondString.value}',
                            style: Styles.number1Text,
                          ))
                    ],
                  ),
                  Gap(24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Range',
                        style: Styles.body21Text
                            .copyWith(color: Styles.gray1Color),
                      ),
                      Text(
                        distanceCarculate(),
                        style: Styles.number1Text,
                      )
                    ],
                  ),
                ],
              ),
              Gap(16),
              GestureDetector(
                  onTap: () async {},
                  onTapDown: (TapDownDetails details) {
                    // 버튼을 누른 순간에 시작 시간을 저장합니다.
                    _start = DateTime.now();
                    _timer = Timer(Duration(seconds: 3), () async {
                      // 3초 이후에 동작할 코드를 작성합니다.
                      // 예를 들어, 버튼을 누르고 3초 이상 누른 경우 "Button pressed for 3 seconds"를 출력합니다.
                      Get.find<LocationController>().setCleaningDistance();
                      Get.find<TimerController>().setCleaningTime();
                      await availableCameras()
                          .then((value) => Get.to(CameraScreen(
                                isTest: widget.isTest,
                                cameras: value,
                                text: 'after',
                                imageType: AFTER_IMAGE,
                                onPressed: () => Get.to(MethodSelectScreen(
                                  isTest: widget.isTest,
                                )),
                              )));
                    });
                  },
                  onTapUp: (TapUpDetails details) {
                    // 버튼에서 손을 뗀 순간에 타이머를 취소합니다.
                    _timer?.cancel();
                  },
                  onTapCancel: () {
                    // 다른 동작으로 인해 버튼을 누르지 않은 경우 타이머를 취소합니다.
                    _timer?.cancel();
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Styles.buttonPrimaryColor),
                    child: Center(
                      child: Text(
                        'Press 3 seconds to finish cleaning',
                        style: Styles.body12Text,
                      ),
                    ),
                  )),
              // PrimaryButton(
              //     height: 60,
              //     text: 'Stop Cleaning',
              //     onTap: () async {
              //       Get.find<LocationController>().setCleaningDistance();
              //       Get.find<TimerController>().setCleaningTime();
              //       await availableCameras()
              //           .then((value) => Get.to(CameraScreen(
              //                 cameras: value,
              //                 text: 'after',
              //                 imageType: AFTER_IMAGE,
              //                 onPressed: () => Get.to(MethodSelectScreen()),
              //               )));
              //     })
            ],
          ),
        ),
      ),
    ]);
  }
}

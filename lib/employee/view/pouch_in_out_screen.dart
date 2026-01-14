import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PunchInOutScreen extends StatefulWidget {
  final String cid;
  final String uid;
  final String department;
  final String range;
  final String name;

  const PunchInOutScreen({
    super.key,
    required this.cid,
    required this.uid,
    required this.department,
    required this.range,
    required this.name,
  });

  @override
  State<PunchInOutScreen> createState() => _PunchInOutScreenState();
}

class _PunchInOutScreenState extends State<PunchInOutScreen> {
  bool isLoading = false;

  Position? currentPosition;
  double? currentDistance;

  final TextEditingController remarkCtrl = TextEditingController();
  XFile? capturedImage;

  TimeOfDay? shiftStart;
  TimeOfDay? shiftEnd;
  late double officeRange;
  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();
    loadLiveLocation();
    loadShiftTime();
    officeRange = double.tryParse(widget.range) ?? 0;
  }

  // ---------------- LOCATION ----------------
  Future<Position> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location service disabled';
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Location permission permanently denied';
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  double calculateDistance(
      double officeLat,
      double officeLng,
      double userLat,
      double userLng,
      ) {
    return Geolocator.distanceBetween(
      officeLat,
      officeLng,
      userLat,
      userLng,
    );
  }

  Future<void> loadLiveLocation() async {
    final empDoc = await FirebaseFirestore.instance
        .collection('subcompanies')
        .doc(widget.cid)
        .collection('employees')
        .doc(widget.uid)
        .get();

    final officeLat = double.parse(empDoc['latitude'].toString());
    final officeLng = double.parse(empDoc['longitude'].toString());

    final pos = await getCurrentLocation();

    final dist = calculateDistance(
      officeLat,
      officeLng,
      pos.latitude,
      pos.longitude,
    );

    setState(() {
      currentPosition = pos;
      currentDistance = dist;
    });
  }

  // ---------------- SHIFT ----------------
  Future<void> loadShiftTime() async {
    final empDoc = await FirebaseFirestore.instance
        .collection('subcompanies')
        .doc(widget.cid)
        .collection('employees')
        .doc(widget.uid)
        .get();

    shiftStart = parseTime(empDoc['shiftStart']);
    shiftEnd = parseTime(empDoc['shiftEnd']);
  }

  TimeOfDay parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  bool isWithinShift() {
    final now = TimeOfDay.now();

    int toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

    return toMinutes(now) >= toMinutes(shiftStart!) &&
        toMinutes(now) <= toMinutes(shiftEnd!);
  }

  // ---------------- IMAGE ----------------
  Future<void> captureImage() async {
    final status = await Permission.camera.request();

    if (status.isDenied) {
      throw 'Camera permission denied';
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      throw 'Enable camera permission from settings';
    }

    final picker = ImagePicker();
    final XFile? image =
    await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() {
        capturedImage = image;
      });
    }
  }


  // ---------------- DATE ----------------
  String todayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  // ---------------- PUNCH IN ----------------
  DateTime _timeToToday(String hhmm) {
    final parts = hhmm.split(':');
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }
  String getPunchStatus({
    required DateTime shiftStart,
    required DateTime shiftEnd,
  }) {
    final now = DateTime.now();

    final allowedStart = shiftStart.subtract(const Duration(minutes: 15)); // 09:45
    final presentLimit = shiftStart.add(const Duration(minutes: 15));     // 10:15

    if (now.isBefore(allowedStart)) {
      throw 'Punch allowed only after ${allowedStart.hour}:${allowedStart.minute.toString().padLeft(2,'0')}';
    }

    if (now.isAfter(shiftEnd)) {
      throw 'Shift already ended';
    }

    if (now.isAfter(presentLimit)) {
      return 'Late';
    }

    return 'Present';
  }


  Timer? locationTimer;

  Future<void> startLocationTracking() async {
    locationTimer?.cancel(); // Cancel previous timer if any

    locationTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final lat = position.latitude;
        final lng = position.longitude;

        final ref = FirebaseFirestore.instance
            .collection('subcompanies')
            .doc(widget.cid)
            .collection('attendance')
            .doc(todayKey())
            .collection('records')
            .doc(widget.uid)
            .collection('latlngHistory');

        // Store each lat/lng with timestamp
        await ref.add({
          'lat': lat,
          'lng': lng,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Optional: Update last known location in main doc
        final mainRef = FirebaseFirestore.instance
            .collection('subcompanies')
            .doc(widget.cid)
            .collection('attendance')
            .doc(todayKey())
            .collection('records')
            .doc(widget.uid);

        await mainRef.update({
          'currentLat': lat,
          'currentLng': lng,
        });
      } catch (e) {
        print("Location update failed: $e");
      }
    });
  }

  Future<void> punchIn() async {

    if (currentDistance == null || currentDistance! > officeRange) {
      throw 'You are outside office radius';
    }

    final empRef = FirebaseFirestore.instance
        .collection('subcompanies')
        .doc(widget.cid)
        .collection('employees')
        .doc(widget.uid);

    final empDoc = await empRef.get();
    if (!empDoc.exists) throw 'Employee not found';

    // ⏰ Shift time
    final shiftStart =
    _timeToToday(empDoc['shiftStart']); // "10:00"
    final shiftEnd =
    _timeToToday(empDoc['shiftEnd']);   // "19:00"

    // ✅ Decide status
    final status = getPunchStatus(
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
    );

    final ref = FirebaseFirestore.instance
        .collection('subcompanies')
        .doc(widget.cid)
        .collection('attendance')
        .doc(todayKey())
        .collection('records')
        .doc(widget.uid);

    final doc = await ref.get();
    if (doc.exists && doc.data()?['punchIn'] != null) {
      throw 'Already punched in';
    }

    await ref.set({
      'uid': widget.uid,
      'status': status, // 🔥 Present / Late
      'distance': currentDistance,
      'department': widget.department,
      'name': widget.name,
      'shiftStart': empDoc['shiftStart'],
      'shiftEnd': empDoc['shiftEnd'],
      'punchIn': {
        'time': FieldValue.serverTimestamp(),
        'lat': currentPosition!.latitude,
        'lng': currentPosition!.longitude,
        'remark': remarkCtrl.text,
      }
    }, SetOptions(merge: true));
    await startLocationTracking();
  }

  Future<void> stopLocationTracking() async {
    locationTimer?.cancel();
    locationTimer = null;
  }

  // ---------------- PUNCH OUT ----------------
  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Future<void> punchOut() async {
    if (currentDistance == null || currentDistance! > officeRange) {
      throw 'Punch out allowed only inside office';
    }

    final ref = FirebaseFirestore.instance
        .collection('subcompanies')
        .doc(widget.cid)
        .collection('attendance')
        .doc(todayKey())
        .collection('records')
        .doc(widget.uid);

    final doc = await ref.get();

    if (!doc.exists || doc.data()?['punchIn'] == null) {
      throw 'Punch In required first';
    }

    if (doc.data()?['punchOut'] != null) {
      throw 'Already punched out';
    }

    // ⏰ Punch In / Out
    final punchInTime =
    (doc['punchIn']['time'] as Timestamp).toDate();
    final punchOutTime = DateTime.now();

    // 🟡 TOTAL BREAK TIME
    final breaksSnap = await ref.collection('breaks').get();
    int totalBreakMinutes = 0;

    for (var b in breaksSnap.docs) {
      totalBreakMinutes += (b['durationMinutes'] ?? 0) as int;
    }

    // ⏱ TOTAL WORK TIME
    final totalMinutes =
        punchOutTime.difference(punchInTime).inMinutes;

    final netMinutes = totalMinutes - totalBreakMinutes;

    final netDuration = Duration(minutes: netMinutes);

    await ref.update({
      'punchOut': {
        'time': FieldValue.serverTimestamp(),
        'lat': currentPosition!.latitude,
        'lng': currentPosition!.longitude,
        'remark': remarkCtrl.text,
      },
      'totalBreakMinutes': totalBreakMinutes,
      'workingMinutes': netMinutes,
      'netWorkingHours': formatDuration(netDuration),
    });

    await stopLocationTracking();
  }

  //-----------break time-----------------
  bool onBreak = false;
  DateTime? activeBreakStart;
  Future<void> startBreak() async {
    final ref = FirebaseFirestore.instance
        .collection('subcompanies')
        .doc(widget.cid)
        .collection('attendance')
        .doc(todayKey())
        .collection('records')
        .doc(widget.uid);

    final doc = await ref.get();

    if (!doc.exists || doc.data()?['punchIn'] == null) {
      throw 'Punch In required first';
    }

    if (onBreak) {
      throw 'Already on break';
    }

    activeBreakStart = DateTime.now();
    onBreak = true;

    await ref.collection('breaks').add({
      'startTime': FieldValue.serverTimestamp(),
      'endTime': null,
      'durationMinutes': 0,
    });
  }
  Future<void> endBreak() async {
    if (!onBreak || activeBreakStart == null) {
      throw 'No active break';
    }

    final ref = FirebaseFirestore.instance
        .collection('subcompanies')
        .doc(widget.cid)
        .collection('attendance')
        .doc(todayKey())
        .collection('records')
        .doc(widget.uid);

    final snap = await ref
        .collection('breaks')
        .where('endTime', isNull: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw 'Active break not found';
    }

    final breakEnd = DateTime.now();
    final duration =
        breakEnd.difference(activeBreakStart!).inMinutes;

    await snap.docs.first.reference.update({
      'endTime': FieldValue.serverTimestamp(),
      'durationMinutes': duration,
    });

    activeBreakStart = null;
    onBreak = false;
  }


  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Punch In / Out")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current Location",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(currentPosition == null
                        ? "Fetching..."
                        : "Lat: ${currentPosition!.latitude}\nLng: ${currentPosition!.longitude}"),
                    const SizedBox(height: 6),
                    Text(
                      currentDistance == null
                          ? ""
                          : "Distance: ${currentDistance!.toStringAsFixed(0)} meters",
                      style: TextStyle(
                        color: currentDistance != null &&
                            currentDistance! <= officeRange
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: remarkCtrl,
                decoration: const InputDecoration(
                  labelText: "Remark",
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            ElevatedButton.icon(
              onPressed: captureImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text("Capture Image"),
            ),

            if (capturedImage != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Image.file(
                  File(capturedImage!.path),
                  height: 150,
                ),
              ),

            const SizedBox(height: 20),

            isLoading
                ? const CircularProgressIndicator()
                : Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    try {
                      setState(() => isLoading = true);
                      await punchIn();
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text("Punch In Done")));
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.toString())));
                    } finally {
                      setState(() => isLoading = false);
                    }
                  },
                  child: const Text("Punch In"),
                ),

                const SizedBox(height: 5),

                if (!onBreak)
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        setState(() => isLoading = true);
                        await startBreak();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text("Break Started")));
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(e.toString())));
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
                    child: const Text("Start Break"),
                  ),

                if (onBreak)
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        setState(() => isLoading = true);
                        await endBreak();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text("Break Ended")));
                      } catch (e) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(e.toString())));
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
                    child: const Text("End Break"),
                  ),

                ElevatedButton(
                  onPressed: () async {
                    try {
                      setState(() => isLoading = true);
                      await punchOut();
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text("Punch Out Done")));
                    } catch (e) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(e.toString())));
                    } finally {
                      setState(() => isLoading = false);
                    }
                  },
                  child: const Text("Punch Out"),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}

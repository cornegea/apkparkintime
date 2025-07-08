import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:parkintime/screens/reservation/review_booking_page.dart';

class BookParkingDetailsPage extends StatefulWidget {
  final int pricePerHour;
  final String kodeslot;
  final String vehiclePlate;
  final String vehicleId;
  final String id_lahan;

  const BookParkingDetailsPage({
    Key? key,
    required this.pricePerHour,
    required this.kodeslot,
    required this.vehiclePlate,
    required this.vehicleId,
    required this.id_lahan,
  }) : super(key: key);

  @override
  _BookParkingDetailsPageState createState() => _BookParkingDetailsPageState();
}

class _BookParkingDetailsPageState extends State<BookParkingDetailsPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Set default start time to the next hour from now
  TimeOfDay _startTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);
  late TimeOfDay _endTime;

  double _duration = 4.0;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final dateFormatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Initialize end time based on the initial start time and duration
    _endTime = TimeOfDay(
      hour: (_startTime.hour + _duration.toInt()) % 24,
      minute: _startTime.minute,
    );
    _validateInitialTime();
  }

  /// Validates and adjusts the start time when the page loads or date changes.
  void _validateInitialTime() {
    final now = DateTime.now();
    // Only validate if the selected day is today
    if (_selectedDay != null && isSameDay(_selectedDay, now)) {
      final nowTime = TimeOfDay.fromDateTime(now);
      // If the currently set start time is in the past, adjust it to the next hour.
      if (_startTime.hour < nowTime.hour ||
          (_startTime.hour == nowTime.hour &&
              _startTime.minute <= nowTime.minute)) {
        setState(() {
          _startTime = TimeOfDay(hour: now.hour + 1, minute: 0);
          _recalculateEndTime();
        });
      }
    }
  }

  /// Recalculates end time based on start time and duration.
  void _recalculateEndTime() {
    _endTime = TimeOfDay(
      hour: (_startTime.hour + _duration.toInt()) % 24,
      minute: _startTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalPrice = widget.pricePerHour * _duration.toInt();
    final String hours =
        '${_startTime.format(context)} - ${_endTime.format(context)}';
    final String durationText = '${_duration.toInt()} Hours';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Color(0xFF629584),
        centerTitle: true, // ✅ Tengahin judul
        title: Text(
          'Book Parking',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 28,
          ), // ✅ Icon back lebih tebal
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select Date',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TableCalendar(
                    firstDay: DateTime.now().subtract(
                      Duration(days: 1),
                    ), // Allow seeing today
                    lastDay: DateTime.utc(2030),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                        // Re-validate time if the user selects today.
                        _validateInitialTime();
                      });
                    },
                    // Disable selection of past dates
                    enabledDayPredicate: (day) {
                      return !day.isBefore(
                        DateTime.now().subtract(Duration(days: 1)),
                      );
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.green.shade200,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      disabledTextStyle: TextStyle(color: Colors.grey.shade400),
                      todayTextStyle: TextStyle(color: Colors.black),
                    ),
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Duration',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  Slider(
                    value: _duration,
                    min: 1,
                    max: 12,
                    divisions: 11,
                    label: '${_duration.toInt()} Hours',
                    activeColor: Colors.green,
                    onChanged: (v) {
                      setState(() {
                        _duration = v;
                        _recalculateEndTime();
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTimeCard('Start Hour', _startTime, _onStartTimePicked),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  const SizedBox(width: 8),
                  _buildTimeCard(
                    'End Hour',
                    _endTime,
                    null,
                  ), // End time cannot be picked
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${currencyFormatter.format(totalPrice)} / $durationText',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final String formattedDate = dateFormatter.format(
                    _selectedDay!,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ReviewBookingPage(
                            kodeslot: widget.kodeslot,
                            id_lahan: widget.id_lahan,
                            carid: widget.vehicleId,
                            date: formattedDate,
                            duration: durationText,
                            hours: hours,
                            total_price: totalPrice,
                            vehiclePlate: widget.vehiclePlate,
                            pricePerHour: widget.pricePerHour,
                          ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Extracts the time picking logic into its own method.
  Future<void> _onStartTimePicked(TimeOfDay picked) async {
    final now = DateTime.now();
    // Combine selected day and picked time into a full DateTime
    final selectedDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      picked.hour,
      picked.minute,
    );

    // Allow a small buffer of a few seconds for comparison
    if (selectedDateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You cannot select a time in the past."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _startTime = picked;
      _recalculateEndTime();
    });
  }

  Widget _buildTimeCard(
    String label,
    TimeOfDay time,
    ValueChanged<TimeOfDay>? onPicked,
  ) {
    return Expanded(
      child: InkWell(
        onTap:
            (onPicked == null)
                ? null
                : () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (picked != null) {
                    onPicked(picked);
                  }
                },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFD5F5E3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    time.format(context),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

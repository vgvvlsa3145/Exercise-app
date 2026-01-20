import 'package:flutter/material.dart';
import 'package:hyperpulsex/utils/app_theme.dart';
import 'package:hyperpulsex/data/database_helper.dart';
import 'package:hyperpulsex/data/models/workout_record.dart';
import 'package:hyperpulsex/logic/session_service.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<WorkoutRecord> _allHistory = [];
  List<WorkoutRecord> _filteredHistory = [];
  bool _isLoading = true;
  bool _isCalendarView = false;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadHistory();
  }

  List<String> _debugUsernames = [];

  Future<void> _loadHistory() async {
    final username = await SessionService.getUsername();
    
    // DEBUG: Get all users
    final allUsers = await DatabaseHelper.instance.getAllUsernames();
    
    if (username == null) return;

    final history = await DatabaseHelper.instance.getWorkouts(username);
    if (mounted) {
      setState(() {
        _allHistory = history;
        _debugUsernames = allUsers; // Store for UI
        _filterHistory();
        _isLoading = false;
      });
    }
  }

  void _filterHistory() {
    if (_isCalendarView && _selectedDay != null) {
      _filteredHistory = _allHistory.where((record) {
        return isSameDay(record.timestamp, _selectedDay);
      }).toList();
    } else {
      _filteredHistory = List.from(_allHistory);
    }
  }

  List<WorkoutRecord> _getEventsForDay(DateTime day) {
    return _allHistory.where((record) => isSameDay(record.timestamp, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Workout History"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_month),
            onPressed: () {
              setState(() {
                _isCalendarView = !_isCalendarView;
                _filterHistory();
              });
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isCalendarView)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: AppTheme.surfaceGrey, borderRadius: BorderRadius.circular(20)),
                    child: TableCalendar<WorkoutRecord>(
                      firstDay: DateTime.utc(2020, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: CalendarFormat.month,
                      eventLoader: _getEventsForDay,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: TextStyle(color: Colors.white),
                        weekendTextStyle: TextStyle(color: AppTheme.neonCyan),
                        selectedDecoration: BoxDecoration(color: AppTheme.neonCyan, shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        markerDecoration: BoxDecoration(color: AppTheme.neonPurple, shape: BoxShape.circle),
                      ),
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                          _filterHistory();
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                    ),
                  ),
                
                
                if (_filteredHistory.isNotEmpty && !_isCalendarView)
                  // _buildChart(), // REMOVED as per user request
                  const SizedBox(), 


                Expanded(
                  child: _filteredHistory.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredHistory.length,
                          itemBuilder: (context, index) {
                            final record = _filteredHistory[index];
                            return _buildHistoryCard(record);
                          },
                        ),
                ),
                // DEBUG INFO
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Debug: Found records for: $_debugUsernames",
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_busy, size: 60, color: Colors.white24),
          const SizedBox(height: 10),
          Text(
            _isCalendarView ? "No workouts on this day" : "No workouts yet!", 
            style: const TextStyle(color: Colors.white54, fontSize: 16)
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(WorkoutRecord record) {
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(record.timestamp);
    final durationStr = "${record.durationSec ~/ 60}m ${record.durationSec % 60}s";

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(record.exerciseName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.neonCyan)),
                Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat("REPS", record.reps.toString()),
                _buildStat("ACCURACY", "${(record.accuracy * 100).toInt()}%"),
                _buildStat("TIME", durationStr),
                _buildStat("KCAL", record.caloriesBurned.toInt().toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    // 1. Group Data by Date AND Exercise
    // Ensure sorted by date
    _filteredHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Get Unique Exercises and Assign Colors
    final uniqueExercises = _filteredHistory.map((e) => e.exerciseName).toSet().toList();
    final colors = [
      AppTheme.neonCyan,
      AppTheme.neonPurple,
      const Color(0xFFFF00FF), // Magenta
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFF00FF00), // Green
      const Color(0xFFFF9900), // Orange
      const Color(0xFF0099FF), // Blue
      const Color(0xFFFF0000), // Red
    ];

    List<LineChartBarData> lines = [];
    
    // For X-Axis: 0 to N (last 10 workouts total) 
    // Wait, plotting multiple exercises on same "count" axis is tricky if they weren't done together.
    // Better X-Axis: Time? Or just Index of "Workout Session"?
    // For simplicity: We plot "Reps" over "Index of Occurrence within that Exercise".
    // i.e. 1st Pushup, 2nd Pushup...
    
    for (int i = 0; i < uniqueExercises.length; i++) {
        final exercise = uniqueExercises[i];
        final color = colors[i % colors.length];
        
        final exerciseData = _filteredHistory.where((e) => e.exerciseName == exercise).toList();
        
        // Take last 10 of THIS exercise
        final recentData = exerciseData.length > 10 ? exerciseData.sublist(exerciseData.length - 10) : exerciseData;
        
        List<FlSpot> spots = [];
        for (int j = 0; j < recentData.length; j++) {
           spots.add(FlSpot(j.toDouble(), recentData[j].reps.toDouble()));
        }

        if (spots.isNotEmpty) {
           lines.add(
             LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(show: false), // No fill for multi-line to avoid clutter
             )
           );
        }
    }

    if (lines.isEmpty) return const SizedBox();

    return Container(
      height: 250,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGrey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Reps Progression (Per Exercise)", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 10),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: lines,
                minY: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: uniqueExercises.asMap().entries.map((entry) {
               return Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    Container(width: 8, height: 8, color: colors[entry.key % colors.length]),
                    const SizedBox(width: 4),
                    Text(entry.value, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                 ],
               );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white30, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}

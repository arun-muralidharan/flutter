/*
 * This file is part of wger Workout Manager <https://github.com/wger-project>.
 * Copyright (C) 2020, 2021 wger Team
 *
 * wger Workout Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * wger Workout Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wger/helpers/consts.dart';
import 'package:wger/helpers/json.dart';
import 'package:wger/helpers/misc.dart';
import 'package:wger/models/workouts/session.dart';
import 'package:wger/providers/body_weight.dart';
import 'package:wger/providers/nutrition.dart';
import 'package:wger/providers/workout_plans.dart';
import 'package:wger/theme/theme.dart';

/// Types of events
enum EventType {
  weight,
  session,
  caloriesDiary,
}

/// An event in the dashboard calendar
class Event {
  final EventType _type;
  final String _description;

  Event(this._type, this._description);

  get description {
    return _description;
  }

  get type {
    return _type;
  }
}

class DashboardCalendarWidget extends StatefulWidget {
  DashboardCalendarWidget();

  @override
  _DashboardCalendarWidgetState createState() => _DashboardCalendarWidgetState();
}

class _DashboardCalendarWidgetState extends State<DashboardCalendarWidget>
    with TickerProviderStateMixin {
  late Map<String, List<Event>> _events;
  late final ValueNotifier<List<Event>> _selectedEvents;
  RangeSelectionMode _rangeSelectionMode =
      RangeSelectionMode.toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();

    _events = <String, List<Event>>{};
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    loadEvents();
  }

  void loadEvents() async {
    // Process weight entries
    BodyWeightProvider weightProvider = Provider.of<BodyWeightProvider>(context, listen: false);
    for (var entry in weightProvider.items) {
      final date = DateFormatLists.format(entry.date);

      if (!_events.containsKey(date)) {
        _events[date] = [];
      }

      // Add events to lists
      _events[date]!.add(Event(EventType.weight, '${entry.weight} kg'));
    }

    // Process workout sessions
    WorkoutPlansProvider plans = Provider.of<WorkoutPlansProvider>(context, listen: false);
    plans.fetchSessionData().then((entries) {
      for (var entry in entries['results']) {
        final session = WorkoutSession.fromJson(entry);
        final date = DateFormatLists.format(session.date);
        if (!_events.containsKey(date)) {
          _events[date] = [];
        }
        var time = '';
        if (session.timeStart != null && session.timeEnd != null) {
          time = '(${timeToString(session.timeStart)} - ${timeToString(session.timeEnd)})';
        }

        // Add events to lists
        _events[date]!.add(Event(
          EventType.session,
          '${AppLocalizations.of(context).impression}: ${session.impressionAsString} $time',
        ));
      }
    });

    // Process nutritional plans
    NutritionPlansProvider nutritionProvider =
        Provider.of<NutritionPlansProvider>(context, listen: false);
    for (var plan in nutritionProvider.items) {
      for (var entry in plan.logEntriesValues.entries) {
        final date = DateFormatLists.format(entry.key);
        if (!_events.containsKey(date)) {
          _events[date] = [];
        }

        // Add events to lists
        _events[date]!.add(Event(
          EventType.caloriesDiary,
          '${entry.value.energy.toStringAsFixed(0)} kcal',
        ));
      }
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateFormatLists.format(day)] ?? [];
  }

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);

    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // `start` or `end` could be null
    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              AppLocalizations.of(context).calendar,
              style: Theme.of(context).textTheme.headline4,
            ),
            leading: Icon(
              Icons.calendar_today_outlined,
              color: Colors.black,
            ),
          ),
          TableCalendar<Event>(
            locale: Localizations.localeOf(context).languageCode,
            firstDay: DateTime.now().subtract(Duration(days: 1000)),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: CalendarFormat.month,
            availableGestures: AvailableGestures.horizontalSwipe,
            availableCalendarFormats: const {
              CalendarFormat.month: '',
            },
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: wgerCalendarStyle,
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            onFormatChanged: (format) {},
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          ValueListenableBuilder<List<Event>>(
            valueListenable: _selectedEvents,
            builder: (context, value, _) => Column(
              children: [
                ...value
                    .map((event) => ListTile(
                          title: Text((() {
                            switch (event.type) {
                              case EventType.caloriesDiary:
                                return AppLocalizations.of(context).nutritionalDiary;

                              case EventType.session:
                                return AppLocalizations.of(context).workoutSession;

                              case EventType.weight:
                                return AppLocalizations.of(context).weight;
                            }
                            return event.description.toString();
                          })()),
                          subtitle: Text(event.description.toString()),
                          //onTap: () => print('$event tapped!'),
                        ))
                    .toList()
              ],
            ),
          ),
        ],
      ),
    );
  }
}

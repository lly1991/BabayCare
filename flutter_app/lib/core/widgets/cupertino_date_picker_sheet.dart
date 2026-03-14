import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<DateTime?> showCupertinoDatePickerSheet({
  required BuildContext context,
  required CupertinoDatePickerMode mode,
  required DateTime initialDateTime,
  required DateTime minimumDate,
  required DateTime maximumDate,
}) {
  final clampedInitial = _clampDateTime(
    value: initialDateTime,
    minimumDate: minimumDate,
    maximumDate: maximumDate,
  );

  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (context) => _CupertinoDatePickerSheet(
      mode: mode,
      initialDateTime: clampedInitial,
      minimumDate: minimumDate,
      maximumDate: maximumDate,
    ),
  );
}

DateTime _clampDateTime({
  required DateTime value,
  required DateTime minimumDate,
  required DateTime maximumDate,
}) {
  if (value.isBefore(minimumDate)) return minimumDate;
  if (value.isAfter(maximumDate)) return maximumDate;
  return value;
}

class _CupertinoDatePickerSheet extends StatefulWidget {
  const _CupertinoDatePickerSheet({
    required this.mode,
    required this.initialDateTime,
    required this.minimumDate,
    required this.maximumDate,
  });

  final CupertinoDatePickerMode mode;
  final DateTime initialDateTime;
  final DateTime minimumDate;
  final DateTime maximumDate;

  @override
  State<_CupertinoDatePickerSheet> createState() =>
      _CupertinoDatePickerSheetState();
}

class _CupertinoDatePickerSheetState extends State<_CupertinoDatePickerSheet> {
  late DateTime _value = widget.initialDateTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        '取消',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      onPressed: () => Navigator.of(context).pop(_value),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        '完成',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: widget.mode,
                  initialDateTime: widget.initialDateTime,
                  minimumDate: widget.minimumDate,
                  maximumDate: widget.maximumDate,
                  use24hFormat: true,
                  onDateTimeChanged: (value) => setState(() => _value = value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

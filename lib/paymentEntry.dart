import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ElectricityPaymentModel.dart';
import 'databaseHelper.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class PaymentEntry extends StatefulWidget {
  final ElectricityPaymentModel payment;
  final String action;
  const PaymentEntry({super.key, required this.action, required this.payment});

  @override
  State<PaymentEntry> createState() => _PaymentEntryState();
}

class _PaymentEntryState extends State<PaymentEntry> {
  late ElectricityPaymentModel newPayment;
  late String title, buttonText;

  @override
  void initState() {
    super.initState();
    title =
        widget.action == 'add' ? 'Payment Entry (ADD)' : 'Payment Entry (EDIT)';
    buttonText = widget.action == 'add' ? 'Add' : 'Update';
    newPayment = widget.payment;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(fontSize: 18)),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: TextEditingController(text: newPayment.userId),
                decoration: InputDecoration(labelText: 'User ID'),
                onChanged: (value) {
                  newPayment.userId = value;
                },
              ),
              TextField(
                controller: TextEditingController(text: newPayment.month),
                decoration: InputDecoration(
                  labelText: 'Month',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      String pickerDate = await selectMonth();
                      setState(() {
                        newPayment.month = pickerDate;
                      });
                    },
                  ),
                ),
              ),
              TextField(
                controller: TextEditingController(
                  text: newPayment.unitsUsed.toString(),
                ),
                decoration: InputDecoration(labelText: 'Units Used'),
                onChanged: (value) {
                  newPayment.unitsUsed = int.tryParse(value) ?? 0;
                },
              ),
              TextField(
                controller: TextEditingController(
                  text: newPayment.amountPaid.toString(),
                ),
                decoration: InputDecoration(labelText: 'Amount Paid'),
                onChanged: (value) {
                  newPayment.amountPaid = double.tryParse(value) ?? 0;
                },
              ),
              TextField(
                controller: TextEditingController(text: newPayment.paymentDate),
                decoration: InputDecoration(
                  labelText: 'Payment Date',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      DateTime pickerDate = await _selectDateTime();
                      setState(() {
                        newPayment.paymentDate = DateFormat(
                          'dd MMMM yyyy',
                        ).format(pickerDate);
                      });
                    },
                  ),
                ),
              ),
              SizedBox(
                height: 55.0,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value:
                      newPayment.note.isNotEmpty ? widget.payment.note : null,
                  hint: Text('Select Payment Channel'),
                  items:
                      <String>[
                        'จ่ายผ่านแอปธนาคาร',
                        'จ่ายผ่านเคาน์เตอร์',
                        'จ่ายผ่านบัตรเครดิต',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  dropdownColor: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                  onChanged: (String? newValue) {
                    setState(() {
                      newPayment.note = newValue ?? '';
                    });
                  },
                ),
              ),

              SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red,
                      shape: BeveledRectangleBorder(),
                    ),
                    onPressed: () {
                      // Close the entry without saving
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 8.0),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: BeveledRectangleBorder(),
                    ),
                    onPressed: () async {
                      if (newPayment.userId.isEmpty ||
                          newPayment.month.isEmpty ||
                          newPayment.unitsUsed <= 0 ||
                          newPayment.amountPaid <= 0 ||
                          newPayment.paymentDate.isEmpty ||
                          newPayment.note.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.red,
                            content: Text(
                              'Please fill all fields correctly.',
                              style: TextStyle(color: Colors.white),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      await processPaymentEntry(newPayment);
                      Navigator.pop(context);
                    },
                    child: Text(buttonText),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> processPaymentEntry(dynamic payment) async {
    if (widget.action == 'add') {
      try {
        await DatabaseHelper().addPayment(payment);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment entry added successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add payment entry: $error'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else if (widget.action == 'edit') {
      try {
        await DatabaseHelper().updatePayment(
          widget.payment.referenceId!,
          payment,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment entry updated successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update payment entry: $error'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  // Date Picker
  Future<DateTime> _selectDateTime() async {
    DateTime selectedDate = DateTime.now();
    DateTime initialDate = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder:
          (context, child) => Theme(
            data: ThemeData.light().copyWith(
              primaryColor: Colors.blue,
              colorScheme: ColorScheme.light(primary: Colors.blue),
              buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          ),
    );
    if (pickedDate != null) {
      selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        initialDate.hour,
        initialDate.minute,
        initialDate.second,
        initialDate.millisecond,
        initialDate.microsecond,
      );
    }
    return selectedDate;
  }

  Future<String> selectMonth() async {
    final selected = await showMonthPicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2080),
    );
    if (selected != null) {
      return DateFormat('MMMM yyyy').format(selected);
    }
    return DateFormat('MMMM yyyy').format(DateTime.now());
  }
}

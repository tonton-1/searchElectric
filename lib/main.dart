import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'ElectricityPaymentModel.dart';
import 'package:intl/intl.dart';
import 'databaseHelper.dart';
import 'paymentEntry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Local Persistence',
      theme: ThemeData(
        useMaterial3: true,
        bottomAppBarTheme: BottomAppBarTheme(color: Colors.blue),
      ),
      home: MyHomePage(title: 'Electricity Payments'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

List<ElectricityPaymentModel> paymentItems = [];

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Row(
            children: [
              Text(widget.title, style: TextStyle(fontSize: 18)),
              Spacer(),
              IconButton(
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: MySearchDelegate(
                      hintText: 'ค้นหา วันที่,เดือน,จำนวนเงิน,หน่วยที่ใช้',
                    ),
                  );
                  print(paymentItems[0].paymentDate);
                },
                icon: Icon(Icons.search),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder(
        stream: DatabaseHelper().getStreamPayments(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No payments found.'));
          }
          return _buildListView(snapshot);
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Padding(padding: const EdgeInsets.all(24.0)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        shape: CircleBorder(),
        tooltip: 'Add Electricity Payment Entry',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PaymentEntry(
                    action: 'add',
                    payment: ElectricityPaymentModel(
                      userId: 'U001',
                      month: DateFormat('MMMM yyyy').format(DateTime.now()),
                      unitsUsed: 0,
                      amountPaid: 0.0,
                      paymentDate: DateFormat(
                        'dd MMMM yyyy',
                      ).format(DateTime.now()),
                      note: '',
                    ),
                  ),
            ),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Build the ListView for displaying payments
  Widget _buildListView(AsyncSnapshot snapshot) {
    paymentItems.clear();
    for (var doc in snapshot.data!.docs) {
      paymentItems.add(
        ElectricityPaymentModel(
          userId: doc.get('userId'),
          month: doc.get('month'),
          unitsUsed: doc.get('unitsUsed'),
          amountPaid: doc.get('amountPaid').toDouble(),
          paymentDate: doc.get('paymentDate'),
          note: doc.get('note'),
          referenceId: doc.id,
        ),
      ); // Update the snapshot data with the model
    }
    // Sort the payment items by month
    paymentItems.sort((a, b) => a.month.compareTo(b.month));
    return ListView.separated(
      itemCount: paymentItems.length,
      itemBuilder: (BuildContext context, int index) {
        String titleDate = paymentItems[index].paymentDate;
        String subtitle =
            "หน่วยที่ใช้ ${paymentItems[index].unitsUsed} หน่วย, ${paymentItems[index].amountPaid} บาท\n${paymentItems[index].note}";
        return Dismissible(
          key: Key(paymentItems[index].referenceId ?? 'item_$index'),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 16.0),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            leading: Column(
              children: <Widget>[
                Text(
                  paymentItems[index].month.substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Colors.blue,
                  ),
                ),
                Icon(Icons.electric_bolt, color: Colors.orange, size: 18.0),
              ],
            ),
            title: Text(
              titleDate,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => PaymentEntry(
                        action: 'edit',
                        payment: paymentItems[index],
                      ),
                ),
              );
            },
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return CupertinoAlertDialog(
                      title: Text('ยืนยันที่จะลบ'),
                      content: Text(
                        'คุณแน่ใจหรือว่าต้องการลบการชำระเงิน วันที่ ${paymentItems[index].paymentDate} ',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: Text(
                            'ยกเลิก',
                            style: TextStyle(color: Colors.blue),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        CupertinoDialogAction(
                          child: Text('ลบ'),
                          isDestructiveAction: true,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ],
                    );
                  },
                ) ??
                false;
          },
          onDismissed: (direction) {
            DatabaseHelper().deletePayment(paymentItems[index].referenceId!);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment deleted'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(color: Colors.grey);
      },
    );
  }
}

class MySearchDelegate extends SearchDelegate {
  final String? hintText;
  MySearchDelegate({this.hintText});
  @override
  String? get searchFieldLabel => hintText;
  TextStyle get searchFieldStyle => TextStyle(fontSize: 15.0);
  List<Widget>? buildActions(BuildContext context) {
    // TODO: implement buildActions
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    // TODO: implement buildLeading
    return IconButton(
      onPressed: () {
        close(context, null);
      },
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // TODO: implement buildResults
    List<ElectricityPaymentModel> matchQuery = [];
    for (var payment in paymentItems) {
      if (payment.month.toLowerCase().contains(query.toLowerCase()) ||
          payment.paymentDate.toLowerCase().contains(query.toLowerCase()) ||
          payment.note.toLowerCase().contains(query.toLowerCase()) ||
          payment.amountPaid.toString().contains(query) ||
          payment.unitsUsed.toString().contains(query)) {
        matchQuery.add(payment);
      }
    }
    return Container(
      color: const Color.fromARGB(255, 246, 247, 247),
      child: ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (context, index) {
          final payment = matchQuery[index];
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: ListTile(
                    title: Row(
                      children: [
                        Text(
                          '${payment.month}',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '  (${payment.unitsUsed} units)',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 152, 0),
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment Date: ${payment.paymentDate}", //,จำนวนเงิน: ${payment.amountPaid} บาท, หมายเหตุ: ${payment.note}
                          style: TextStyle(
                            color: const Color.fromARGB(230, 129, 129, 129),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Note: ${payment.note}',
                          style: TextStyle(
                            color: const Color.fromARGB(230, 129, 129, 129),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.only(right: 16.0),
                        child: Text(
                          '฿${payment.amountPaid}',
                          style: TextStyle(
                            color: Color.fromARGB(255, 33, 150, 243),
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // TODO: implement buildSuggestions
    List<ElectricityPaymentModel> matchQuery = [];
    for (var payment in paymentItems) {
      if (payment.month.toLowerCase().contains(query.toLowerCase()) ||
          payment.paymentDate.toLowerCase().contains(query.toLowerCase()) ||
          payment.note.toLowerCase().contains(query.toLowerCase()) ||
          payment.amountPaid.toString().contains(query) ||
          payment.unitsUsed.toString().contains(query)) {
        matchQuery.add(payment);
      }
    }
    return Container(
      color: const Color.fromARGB(255, 246, 247, 247),
      child: ListView.builder(
        itemCount: matchQuery.length,
        itemBuilder: (context, index) {
          final payment = matchQuery[index];
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: ListTile(
                    title: Row(
                      children: [
                        Text(
                          '${payment.month}',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '  (${payment.unitsUsed} units)',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 152, 0),
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Payment Date: ${payment.paymentDate}", //,จำนวนเงิน: ${payment.amountPaid} บาท, หมายเหตุ: ${payment.note}
                          style: TextStyle(
                            color: const Color.fromARGB(230, 129, 129, 129),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Note: ${payment.note}',
                          style: TextStyle(
                            color: const Color.fromARGB(230, 129, 129, 129),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.only(right: 16.0),
                        child: Text(
                          '฿${payment.amountPaid}',
                          style: TextStyle(
                            color: Color.fromARGB(255, 33, 150, 243),
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

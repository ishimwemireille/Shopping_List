class Bus {
  Bus({required this.route, required this.price});

  final String route;
  final int price;
  final seats = List<String?>.filled(6, null);

  void book(String name, int seat) {
    seats[seat - 1] = name;
  }

  int freeSeats() {
    return seats.where((s) => s == null).length;
  }
}

class Button {
  Button({required this.label, required this.onPressed});

  final String label;
  final void Function() onPressed;

  void tap() {
    print('[$label] was tapped');
    onPressed();
  }
}

void main() {
  // Objects made from a class
  final huye = Bus(route: 'huye', price: 3000);
  final musanze = Bus(price: 2500, route: 'musanze');
  huye.book('Keza', 3);
  print('${huye.route}: ${huye.freeSeats()} free');
  print('${musanze.route}: ${musanze.freeSeats()} free');

  // A function stored in a variable, called later
  final bookButton = Button(
    label: 'Book seat 1',
    onPressed: () {
      huye.book('Eric', 1);
      print('Eric booked. ${huye.freeSeats()} free on huye');
    },
  );
  print('Nothing happens until someone taps...');
  bookButton.tap();
}
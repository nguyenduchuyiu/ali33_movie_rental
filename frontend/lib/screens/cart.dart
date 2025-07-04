// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:ali33/bloc/cart_bloc.dart';
import 'package:ali33/constants/constant_values.dart';
import 'package:ali33/constants/route_animation.dart';
import 'package:ali33/models/cart_item_model.dart';
import 'package:ali33/models/order_model.dart';
import 'package:ali33/models/user_model.dart';
import 'package:ali33/screens/delivery_address.dart';
import 'package:ali33/screens/login.dart';
import 'package:ali33/screens/orders.dart';
import 'package:ali33/screens/payment_screen.dart';
import 'package:ali33/screens/place_order.dart';
import 'package:ali33/screens/product_details.dart';
import 'package:ali33/services/api_service.dart';
import 'package:ali33/services/authenticate_service.dart';
import 'package:ali33/widgets/basic.dart';
import 'package:ali33/widgets/build_photo.dart';
import 'package:ali33/widgets/error_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
 
class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isLoading = false;


  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(FetchCartItems());
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold( 
      body: BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state is CartInitialState || state is CartProductsLoading) {
          return Scaffold(
              appBar: AppBar(
                title: const Text("Cart Preview",selectionColor: Colors.white,),
                toolbarHeight: 80,
                flexibleSpace:
                Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                // shrinkWrap: true, 
                height: 80,
                width: size.width-16*2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
Color(0xff404258), // Start color
Color(0xff474E68),
Color(0xff50577A),
Color(0xff6B728E) // End color
                    ]
                  ),
                ),),
              ),
              body: loadingAnimation());
        } else if (state is CartProductsFetched) {
          if (state.products.cartModels.isEmpty) {
            return Scaffold(
              appBar: AppBar(
                title: const Text("Cart Preview",selectionColor: Colors.white,),
                toolbarHeight: 80,
                flexibleSpace:
                Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                // shrinkWrap: true, 
                height: 80,
                width: size.width-16*2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
Color(0xff404258), // Start color
Color(0xff474E68),
Color(0xff50577A),
Color(0xff6B728E) // End color
                    ]
                  ),
                ),),
              ),
              body: Container(decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
Color(0xff404258), // Start color
Color(0xff474E68),
Color(0xff50577A),
Color(0xff6B728E) // End color
                    ]
                  ),
                ),
                alignment: Alignment.center,
                child: Text("Look's like no Products in Cart. Add some!",
                    style: Theme.of(context).textTheme.headlineMedium,selectionColor: Colors.white,),              
              ),
            );
          }
          List<double> calculatedValues = calculateTotal(state.products.cartModels);

          return Scaffold(
            appBar: AppBar(title: const Text("Cart Preview")),
            body:Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
Color(0xff404258), // Start color
Color(0xff474E68),
Color(0xff50577A),
Color(0xff6B728E) // End color
                    ]
                  ),
                ),
            child:  ListView(
              primary: true,
              children: [
                SizedBox(height: size.height * 0.01),
                Container(
                  // height: size.height * 0.1,
                  color: Colors.amberAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.cabin),
                      const SizedBox(width: 5),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Add a coupon code",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge !
                                  .copyWith(fontSize: 22)),
                          Text("Available offer and discounts on your order",
                              style: Theme.of(context).textTheme.headlineMedium),
                        ],
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.blueGrey,
                       ),
                    ],
                  ),
                ),
                SizedBox(height: size.height * 0.01),
                ListView.builder(
                  itemCount: state.products.cartModels.length,
                  primary: false,
                  shrinkWrap: true,
                  // padding: EdgeInsets.symmetric(horizontal: 8),
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    CartModel item = state.products.cartModels[index];

                    int variationIndex = item.productDetails.variations.indexOf(
                        item.productDetails.variations.firstWhere((element) =>
                            element.quantity ==
                            item.cartItem.variationQuantity));
                    return Dismissible(
                      background: Container(
                        padding: const EdgeInsets.only(right: 20),
                        alignment: Alignment.centerRight,
                        color: Colors.red,
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      direction: DismissDirection.endToStart,
                      key: Key(index.toString()),
                      onDismissed: (DismissDirection direction) {
                        print("dismissed");
                        context
                            .read<CartBloc>()
                            .add(RemoveItemFromCart(item: item.cartItem));
                      },
                      child: Card(
                        margin: const EdgeInsets.all(5),
                        child: SizedBox(
                          height: size.height * 0.2,
                          // color: Colors.black,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  buildPhoto(
                                      item.productDetails.productPicture,
                                      size.height * 0.12,
                                      size.width * 0.32,
                                      BoxFit.contain)
                                  // Container(
                                  //   decoration: BoxDecoration(
                                  //     borderRadius: BorderRadius.circular(16),
                                  //     color: Color(0xffF0E0D8),
                                  //   ),
                                  //   height: size.height * 0.17,
                                  //   width: size.width * 0.32,
                                  //   child: Image.asset(
                                  //     "assets/images/temp/vege.png",
                                  //   ),
                                  // ),
                                  // SizedBox(height: size.height * 0.02),
                                ],
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.productDetails.productName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Text(
                                          dollarSymbol +
                                              item
                                                  .productDetails
                                                  .variations[variationIndex]
                                                  .offerPrice
                                                  .toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge),
                                      const SizedBox(width: 5),
                                      Text(
                                          dollarSymbol +
                                              item
                                                  .productDetails
                                                  .variations[variationIndex]
                                                  .sellingPrice
                                                  .toString(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge !
                                              .copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough)),
                                      const SizedBox(width: 5),
                                      Text("${calculateOffPercentage(
                                              item
                                                  .productDetails
                                                  .variations[variationIndex]
                                                  .sellingPrice,
                                              item
                                                  .productDetails
                                                  .variations[variationIndex]
                                                  .offerPrice)}% off"),
                                    ],
                                  ),
                                  SizedBox(height: size.height * 0.01),
                                  Container(
                                    width: size.width * 0.3,
                                    height: 40,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 20),
                                    decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius:
                                            BorderRadius.circular(30)),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            if (item.cartItem.noOfItems > 1) {
                                              Map<String, dynamic> citem = {
                                                "old": CartItem(
                                                    productKey: item
                                                        .cartItem.productKey,
                                                    noOfItems:
                                                        item.cartItem.noOfItems,
                                                    variationQuantity: item
                                                        .cartItem
                                                        .variationQuantity),
                                                "new": CartItem(
                                                    productKey: item
                                                        .cartItem.productKey,
                                                    noOfItems: --item
                                                        .cartItem.noOfItems,
                                                    variationQuantity: item
                                                        .cartItem
                                                        .variationQuantity)
                                              };
                                              // item.cartItem.quantity =
                                              //     item.cartItem.quantity--;

                                              context.read<CartBloc>().add(
                                                  ChangeNoOfProducts(item: citem));
                                            }
                                          },
                                          child: const Text(
                                            "-",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Text(item.cartItem.noOfItems.toString(),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 25,
                                                fontWeight: FontWeight.bold)),
                                        GestureDetector(
                                          onTap: () {
                                            if (item.cartItem.noOfItems < 100) {
                                              Map<String, dynamic> citem = {
                                                "old": CartItem(
                                                    productKey: item
                                                        .cartItem.productKey,
                                                    noOfItems:
                                                        item.cartItem.noOfItems,
                                                    variationQuantity: item
                                                        .cartItem
                                                        .variationQuantity),
                                                "new": CartItem(
                                                    productKey: item
                                                        .cartItem.productKey,
                                                    noOfItems: ++item
                                                        .cartItem.noOfItems,
                                                    variationQuantity: item
                                                        .cartItem
                                                        .variationQuantity)
                                              };
                                              // item.cartItem.quantity =
                                              //     item.cartItem.quantity++;

                                              context.read<CartBloc>().add(
                                                  ChangeNoOfProducts(item: citem));
                                            }
                                          },
                                          child: const Text("+",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 25,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: size.height * 0.02),

                SizedBox(height: size.height * 0.01),

                SizedBox(height: size.height * 0.05),
              ],
            )),
            bottomNavigationBar: Container(
              // height: size.height * 0.28,
              width: size.width,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      // spreadRadius: 3.0,
                      blurRadius: 5)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: size.width,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    color: const Color(0xffC59623),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "$dollarSymbol${calculatedValues[1].toStringAsFixed(2)} saved on this order",
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall!
                                .copyWith(color: Colors.white)),
                        const Text(
                          "Checkout now!",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.pin_drop_outlined,
                          size: 35,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                bool res = true;
                                if (res) {
                                  context
                                      .read<CartBloc>()
                                      .add(FetchCartItems());
                                  setState(() {});
                                }
                              },
                              child: Row(
                                children: [
                                  Text("Home",
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge),
                                  const Icon(Icons.arrow_drop_down_outlined,
                                      size: 35),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  nextButton("Pay  $dollarSymbol${calculatedValues[0].toStringAsFixed(2)}",
                      () async {
                    List<OrderModel> orders = generateOrderList(
                        state.products.cartModels, state.products.userDetails);
                    List<CartItem> cartItems = List<CartItem>.from(
                            state.products.cartModels.map((e) => e.cartItem)).toList();
                    Navigator.push(context, SlideLeftRoute(widget: PaymentScreen(
                                                  cartItems: cartItems,
                                                  orders: orders,
                                                )));
                  }),
                  if (isLoading) loadingAnimation()
                ],
              ),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text("Cart Preview")),
          body: buildErrorWidget(
              context, () => context.read<CartBloc>().add(FetchCartItems())),
        );
      },
    ));
  }

  List<OrderModel> generateOrderList(List<CartModel> cartList, UserModel user) {
    return List<OrderModel>.from(cartList.map((item) {
      int variationIndex = item.productDetails.variations.indexOf(
          item.productDetails.variations.firstWhere((element) =>
              element.quantity == item.cartItem.variationQuantity));

      return OrderModel(
          orderedDate: DateTime.now().toUtc(),
          userId: user.key!,
          productDetails: ProductOrderingDetails(
              productKey: item.productDetails.key,
              noOfItems: item.cartItem.noOfItems,
              variationQuantity: item.cartItem.variationQuantity),
          paidPrice: item.productDetails.variations[variationIndex].offerPrice,
          paymentStatus: 0,
          // deliveryStages: DeliveryStages(
          //     stageOne: "Order Placed",
          //     stageTwo: "",
          //     stageThree: "",
          //     stageFour: ""),
          deliveryStages: ["Order Placed"], 
          deliveryAddress: user.deliveryAddress);
    }).toList());
  }

  List<double> calculateTotal(List<CartModel> cartlist) {
    double totalAmount = 0;
    double savedAmount = 0;
    double originalAmount = 0; 
    for (var item in cartlist) {
      int variationIndex = item.productDetails.variations.indexOf(
          item.productDetails.variations.firstWhere((element) =>
              element.quantity == item.cartItem.variationQuantity));
      int noOfProds = item.cartItem.noOfItems;

      originalAmount +=
          item.productDetails.variations[variationIndex].sellingPrice *
              noOfProds;
      totalAmount +=
          item.productDetails.variations[variationIndex].offerPrice * noOfProds;
    }
    savedAmount = originalAmount - totalAmount;
    return [totalAmount, savedAmount];
  }

  Widget popularSearches() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.18,
      child: ListView.builder(
          itemCount: 6,
          // padding: EdgeInsets.symmetric(horizontal: 10),
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {},
              child: Container(
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width * 0.25,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10)),
                  color: Colors.grey[300],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("images/temp/vege.png",
                        height: MediaQuery.of(context).size.height * 0.1),
                    const SizedBox(height: 5),
                    Text(
                      "Carrot",
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium!
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    const Text("\$ 46.05 /-"),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          }),
    );
  }
}

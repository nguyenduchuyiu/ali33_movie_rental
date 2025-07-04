// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import 'dart:convert';
import 'dart:io';
import 'dart:js_util';
import 'package:ali33/models/cart_item_model.dart';
import 'package:ali33/models/order_item_model.dart';
import 'package:ali33/models/order_model.dart';
import 'package:ali33/models/place_model.dart';
import 'package:ali33/models/product_model.dart';
import 'package:ali33/models/user_model.dart';
import 'package:ali33/services/cache_storage.dart';
import 'package:ali33/widgets/basic.dart';
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();
  final productCacheStorage = ProductCacheStorage();
  
  // final String baseUrl = "https://nguyenduchuy.pythonanywhere.com/";
  // final String userBaseUrl = "https://nguyenduchuy.pythonanywhere.com/users";
  // final String productBaseUrl = "https://nguyenduchuy.pythonanywhere.com/products";
  // final String orderBaseUrl = "https://nguyenduchuy.pythonanywhere.com/orders";

  final String baseUrl = "http://127.0.0.1:5000";
  final String userBaseUrl = "http://127.0.0.1:5000/users";
  final String productBaseUrl = "http://127.0.0.1:5000/products";
  final String orderBaseUrl = "http://127.0.0.1:5000/orders";

  // final String baseUrl = "http://192.168.0.101:8080";
  // final String userBaseUrl = "http://192.168.0.101:8080/users";
  // final String productBaseUrl = "http://192.168.0.101:8080/products";
  // final String orderBaseUrl = "http://192.168.0.101:8080/orders";

  Future<Map<String, dynamic>> createPaymentIntentOnServer(Map<String, dynamic> paymentDetails) async {
    try {
      Map<String, dynamic> data = {"body": jsonEncode(paymentDetails)};
      Response<Map<String, dynamic>> response = await _dio.post('$userBaseUrl/payment', 
                                                      data:data);

      if (response.statusCode == 200) {
        return response.data!;
      } else {
        // Handle errors from your backend
        print("Error creating Payment Intent: ${response.statusCode}");
        print(response.data!);
        throw Exception('Failed to create Payment Intent');
      }
    } on SocketException {
      print('No internet connection');
      throw Exception('No internet connection');
    } on HttpException {
      print("Couldn't find the server");
      throw Exception("Couldn't find the server");
    } on FormatException {
      print("Bad response format");
      throw Exception("Bad response format");
    } catch (e) {
      print('Error creating Payment Intent: $e');
      throw Exception('Failed to create Payment Intent');
    }
  }


  Future<bool?> checkUser(Map<String, String> data) async {
    try {
      Response<Map<String, dynamic>> response =
          await _dio.post("$userBaseUrl/check_user", data: data);
      if (response.statusCode == 200) {
        // print('user exist ${response.data!['result']}');
        return response.data!['result'];
      }
    } on DioException catch (e) {
      if (e.error is SocketException) {
        internetToastMessage();
      }
    } catch (e) {
      toastMessage("Something went wrong! Try again");
    }
    return null;
  }



  // Future<bool> register(UserModel userModel) async {
  //   try {
  //     Response<Map<String, dynamic>> response =
  //         await _dio.post("$userBaseUrl/user", data: userModel.toJson());

  //     await TokenCacheStorage().setToken(response.data!["authToken"]);
  //     return true;
  //   } on DioException catch (e) {
  //     print("dio error occured: ${e.response}");
  //     if (e.error is SocketException) {
  //       internetToastMessage();
  //     } else {
  //       toastMessage("Something went wrong! Try again");
  //     }
  //   } catch (e) {
  //     print("Exception Occured : $e");

  //     toastMessage("Something went wrong! Try again");
  //   }
  //   return false;
  // }

  Future<bool> login(Map<String, String> data) async {
    try {
      Response<Map<String, dynamic>> response = await _dio.post("$userBaseUrl/login", data: data);
      print(response);
      await TokenCacheStorage().setToken(response.data!["token"]);
      return true;
    } on DioException catch (e) {
      if (e.error is SocketException) {
        internetToastMessage();
      }else{
        print('login response : ${e.response}');
      }
    }
    return false;
  }
 

  Future<bool> signup(Map<String, String> data) async {
    try {
      Response<Map<String, dynamic>> response = await _dio.post("$userBaseUrl/signup", data: data);
      // print('signup: $response');
      return true;
    } on DioException catch (e) {
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        print('signup response : ${e.response}');
      }
    }
    return false;
  }

  Future<bool> logout() async {
    await TokenCacheStorage().deleteToken();
    return true;
  }

  Future<bool> updateProfile(UserModel userModel) async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response =
          await _dio.put(userBaseUrl + "/user", data: userModel.toJson());
      print(response);
      return true;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      toastMessage("Something went wrong! Try again");
    }
    return false;
  }

  Future<String> uploadProfilePhoto(File pic) async {
    String? token = await TokenCacheStorage().getToken();
    try {
      _dio.options.headers["Authorization"] = token!;
      FormData formData = FormData.fromMap({
        "profilePic": await MultipartFile.fromFile(pic.path),
      });
      Response<Map<String, dynamic>> response = await _dio
          .post(userBaseUrl + "/upload-profile-picture", data: formData);
      print(response);
      return response.data!["result"];
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        // internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return "";
  }

  Future<UserModel?> getCurrentUser() async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response = await _dio.get("$userBaseUrl/get-current-user");
      // print(response);
      UserModel user = UserModel.fromJson(response.data!["result"]);
      return user;
    } on DioException catch (e) {
      print("get cur user dio error occured: ${e.message}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return null;
  }
 
  Future<bool> addAddress(String address) async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response =
          await _dio.post("$userBaseUrl/address", data: address);
      print(response);
      return true;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        // internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return false;
  }

  Future<bool> deleteAddress(String address) async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response =
          await _dio.delete(userBaseUrl + "/address", data: address);
      print(response);
      return true;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
      } else {}
    } catch (e) {
      print("Exception Occured : $e");
    }
    return false;
  }

  Future<List<String>> getAllAddresses() async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response = await _dio.get(userBaseUrl + "/address");
      return response.data!['result'];
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        // internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return [];
  }

  Future<List<OrderCombinedModel>> getAllOrders() async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response = await _dio.get(userBaseUrl + "/get-all-orders");

      print("list order: ${response.data!["result"][0]}");
      // print("list order below: ${response.data!["result"][0]["productDetails"]}");

      List<OrderCombinedModel> orders = orderItemsFromJson(response.data!["result"]);
      return orders;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return [];
  }

  Future<bool> setDefaultAddress(String address) async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response = await _dio
          .post(userBaseUrl + "/set-default-address", data: address);
      print(response);
      return true;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      toastMessage("Something went wrong! Try again");
    }
    return false;
  }

  /// products related api calls

  Future<List<CategoryDetail>> getAllCategories() async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response =
          await _dio.get(productBaseUrl + "/get-all-categories");
      List<CategoryDetail> categories =
          categoriesFromJson(response.data!["result"]);
      return categories;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        // internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return [];
  }

  Future<CategoryDetail?> getCategory() async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response =
          await _dio.get(productBaseUrl + "/category");
      CategoryDetail category =
          CategoryDetail.fromJson(response.data!["result"]);
      return category;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        // internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return null;
  }

  Future<ProductModel?> getProduct(String key) async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response =
          await _dio.get(productBaseUrl + "/product");
      ProductModel product = ProductModel.fromJson(response.data!["result"]);
      return product;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        // internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return null;
  }

  Future<List<ProductModel>> getAllProducts(int lastDocKey, 
                                            int limit, 
                                            int? category)
                                            async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      // 1. Get product keys from the category
      Response<Map<String, dynamic>> response = await _dio.get(
        "$productBaseUrl/get-products-from-category",
        queryParameters: {"category": category},
      );
      List<int> productKeys = [];
        for (var item in response.data!['result']) {
          if (item is int) {
            productKeys.add(item);
          } 
        }
      // 2. Filter product keys based on view history
      List<int> unviewedProductKeys = productCacheStorage.filterUnviewedProductKeys(productKeys);
      // print("unviewkey $unviewedProductKeys");
      List<int> viewedProductKeys = productCacheStorage.viewedProductKeys;
      // print("view $viewedProductKeys");
      //3. Fetch viewed products
      List<ProductModel>? viewedProducts = await productCacheStorage.getProducts(viewedProductKeys);
      // print("view ${viewedProducts!.length}");
      // 4. Fetch unviewed products
      List<ProductModel> unviewedProducts = [];
      if (unviewedProductKeys.isNotEmpty) {
        response = await _dio.get(
          "$productBaseUrl/get-product-from-keys",
          queryParameters:{"key": unviewedProductKeys.join(',')},
        );
        unviewedProducts = productsFromJson(response.data!["result"]);
      }
      List<ProductModel> allProducts = viewedProducts! + unviewedProducts;
      for(ProductModel i in unviewedProducts) {
        productCacheStorage.addProduct(i);
      }
      return allProducts;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return [];
  }

  Future<List<ProductModel>> searchProduct(String searchTerm) async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      print(searchTerm);
      Response<Map<String, dynamic>> response = await _dio.get(
          "$productBaseUrl/search-product",
          queryParameters: {"searchTerm": searchTerm});
      List<int> productKeys = [];
        for (var item in response.data!['result']) {
          if (item is int) {
            productKeys.add(item);
          } 
        }
      // 2. Filter product keys based on view history
      List<int> unviewedProductKeys = productCacheStorage.filterUnviewedProductKeys(productKeys);
      // print("unviewkey $unviewedProductKeys");
      List<int> viewedProductKeys = productCacheStorage.viewedProductKeys;
      // print("view $viewedProductKeys");
      //3. Fetch viewed products
      List<ProductModel>? viewedProducts = await productCacheStorage.getProducts(viewedProductKeys);
      // print("view ${viewedProducts!.length}");
      // 4. Fetch unviewed products
      List<ProductModel> unviewedProducts = [];
      if (unviewedProductKeys.isNotEmpty) {
        response = await _dio.get(
          "$productBaseUrl/get-product-from-keys",
          queryParameters:{"key": unviewedProductKeys.join(',')},
        );
        unviewedProducts = productsFromJson(response.data!["result"]);
      }
      List<ProductModel> allProducts = viewedProducts! + unviewedProducts;
      for(ProductModel i in unviewedProducts) {
        productCacheStorage.addProduct(i);
      }
      return allProducts;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return [];
  }

  Future<bool> addToCart(CartItem cartItems) async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Map<String, dynamic> data = {'cartItems': cartItems.toJson()};
      Response<Map<String, dynamic>> response = await _dio.post(userBaseUrl + "/add-to-cart", data: data);
      return true;
    } on DioException catch (e) {
      print("dio error occured on add to cart: ${e.response}");
      if (e.error is SocketException) {
        internetToastMessage();
      }
    } catch (e) {
      print("Exception Occured at addtocart : $e");
    }
    return false;
  }

  Future<CartCombinedModel?> getCartItems() async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response = await _dio.get(
                                                userBaseUrl + "/get-cart-items");
      CartCombinedModel prods = CartCombinedModel.fromJson(response.data!['result']);
      return prods;
    } on DioException catch (e) {
      print("dio error occured: ${e.message}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured at get cart item : $e");
      // throw Error;
      toastMessage("Something went wrong! Try again");
    }
    return null;
  }

  Future<bool> removeFromCart(List<CartItem> items) async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response = await _dio.delete(
                                                userBaseUrl + "/remove-from-cart", 
                                                data: {"cartItems": items});
      print("remove:  ${response.data!['result']}");
      return true;
    } on DioException catch (e) {
      print("dio error occured in removeFromCart: ${e.response}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured at removeFromCart : $e");
      // throw Error;
      // toastMessage("Something went wrong! Try again");
    }
    return false;
  }

  Future<bool> changeNoOfProdCart(Map<String, dynamic> item) async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response = await _dio.put(
                                                userBaseUrl + "/change-no-of-product-in-cart", 
                                                data: item);
      print("res ${response.data!['result']}");
      return true;
    } on DioException catch (e) {
      print("dio error occured at changeNoOfProd: ${e.response}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured at changeNoOfProd : $e");
      // throw Error;
      // toastMessage("Something went wrong! Try again");
    }
    return false;
  }

  Future<bool> placeOrder(List<OrderModel> orders) async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response =
          await _dio.post(orderBaseUrl + "/place-order", data: {"orders": orders});
      print("res ${response.data!['result']}");
      return true;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured at placeOrder : $e");
      toastMessage("Something went wrong! Try again");
    }
    return false;
  }

  Future<List<PlaceModel>> searchPlaceOnMap(String input) async {
    const mapApiKey = "AIzaSyC_2fIFDCfbf0xI7lTOEARgCQeH-yQV9h0";
    final requestUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$mapApiKey';
    try {
      Response<Map<String, dynamic>> response = await _dio.post(requestUrl);
      List<PlaceModel> placesSuggestions =
          placesModelFromJson(response.data!["predictions"]);
      return placesSuggestions;
    } on DioException catch (e) {
      print("dio error occured: ${e.response}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured at addtocart : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return [];
  }

  Future<List<ProductModel>> getRelatedProducts(int productKey) async {
    String? token = await TokenCacheStorage().getToken();
    _dio.options.headers["Authorization"] = token!;
    try {
      Response<Map<String, dynamic>> response = await _dio.get(
          "$productBaseUrl/get-related-products",
          queryParameters: {"productKey": productKey});
      List<int> productKeys = [];
        for (var item in response.data!['result']) {
          if (item is int) {
            productKeys.add(item);
          } 
        }
      // 2. Filter product keys based on view history
      List<int> unviewedProductKeys = productCacheStorage.filterUnviewedProductKeys(productKeys);
      // print("unviewkey $unviewedProductKeys");
      List<int> viewedProductKeys = productCacheStorage.viewedProductKeys;
      // print("view $viewedProductKeys");
      //3. Fetch viewed products
      List<ProductModel>? viewedProducts = await productCacheStorage.getProducts(viewedProductKeys);
      print("view ${viewedProducts!.length}");
      // 4. Fetch unviewed products
      List<ProductModel> unviewedProducts = [];
      if (unviewedProductKeys.isNotEmpty) {
        response = await _dio.get(
          "$productBaseUrl/get-product-from-keys",
          queryParameters:{"key": unviewedProductKeys.join(',')},
        );
        unviewedProducts = productsFromJson(response.data!["result"]);
      }
      List<ProductModel> allProducts = viewedProducts + unviewedProducts;
      print(allProducts.length);
      for(ProductModel i in unviewedProducts) {
        productCacheStorage.addProduct(i);
      }
      print("len view ${viewedProducts.length}");
      print("len unview ${unviewedProducts.length}");
      return allProducts;
    } on DioException catch (e) {
      print("dio error occured on get rcm: ${e.response}");
      if (e.error is SocketException) {
        internetToastMessage();
      } else {
        // toastMessage("Something went wrong! Try again");
      }
    } catch (e) {
      print("Exception Occured at rcm : $e");
      // toastMessage("Something went wrong! Try again");
    }
    return [];
  }
}

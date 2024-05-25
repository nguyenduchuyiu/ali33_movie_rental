import unittest
from unittest.mock import patch
from flask import json
from server import app
import security as sc
import database_module as dm
import rcm_model as rcm
import stripe


class ServerTest(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()

    @patch('database_module.is_registered')
    def test_check_register(self, mock_is_registered):
        mock_is_registered.return_value = True
        response = self.app.post('/users/check_user', json={'userId': 'test@example.com'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result'], True)

    @patch('database_module.get_user_for_login')
    @patch('security.check_password')
    @patch('security.create_jwt_token')
    def test_login_success(self, mock_create_jwt_token, mock_check_password, mock_get_user_for_login):
        mock_get_user_for_login.return_value = {'_key': 'test_user_key'}
        mock_check_password.return_value = True
        mock_create_jwt_token.return_value = 'test_token'
        response = self.app.post('/users/login', json={'userId': 'test@example.com', 'password': 'test'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['token'], 'test_token')

    @patch('database_module.get_user_for_login')
    @patch('security.check_password')
    def test_login_invalid_credentials(self, mock_check_password, mock_get_user_for_login):
        mock_get_user_for_login.return_value = {'_key': 'test_user_key'}
        mock_check_password.return_value = False
        response = self.app.post('/users/login', json={'userId': 'test@example.com', 'password': 'test'})
        self.assertEqual(response.status_code, 401)
        self.assertEqual(json.loads(response.data)['error'], 'Invalid credentials')

    @patch('database_module.create_user')
    def test_sign_up_success(self, mock_create_user):
        mock_create_user.return_value = True
        response = self.app.post('/users/signup', json={'username': 'testuser', 'userId': 'test@example.com', 'password': 'test'})
        self.assertEqual(response.status_code, 201)
        self.assertEqual(json.loads(response.data)['message'], 'User created successfully')

    @patch('database_module.create_user')
    def test_sign_up_failure(self, mock_create_user):
        mock_create_user.return_value = False
        response = self.app.post('/users/signup', json={'username': 'testuser', 'userId': 'test@example.com', 'password': 'test'})
        self.assertEqual(response.status_code, 400)
        self.assertEqual(json.loads(response.data)['error'], 'Failed to create user')

    @patch('security.decode_jwt_token')
    @patch('database_module.get_user_by_key')
    def test_get_current_user_success(self, mock_get_user_by_key, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_get_user_by_key.return_value = {'_key': 'test_user_key', 'username': 'testuser'}
        response = self.app.get('/users/get-current-user', headers={'Authorization': 'Bearer test_token'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result']['username'], 'testuser')

    @patch('security.decode_jwt_token')
    def test_get_current_user_session_expired(self, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = None
        response = self.app.get('/users/get-current-user', headers={'Authorization': 'Bearer test_token'})
        self.assertEqual(response.status_code, 404)
        self.assertEqual(json.loads(response.data)['error'], 'Session expired')

    @patch('security.decode_jwt_token')
    @patch('database_module.get_user_by_key')
    def test_get_current_user_not_found(self, mock_get_user_by_key, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_get_user_by_key.return_value = None
        response = self.app.get('/users/get-current-user', headers={'Authorization': 'Bearer test_token'})
        self.assertEqual(response.status_code, 404)
        self.assertEqual(json.loads(response.data)['error'], 'User not found')

    @patch('database_module.get_product_from_key')
    def test_get_product_by_keys_success(self, mock_get_product_from_key):
        mock_get_product_from_key.return_value = [{'productDetails': {'name': 'Test Product'}}]
        response = self.app.get('/products/get-product-from-keys?key=1,2')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result'][0]['productDetails']['name'], 'Test Product')

    @patch('database_module.get_product_of_category')
    def test_get_products_by_category_success(self, mock_get_product_of_category):
        mock_get_product_of_category.return_value = [1, 2]
        response = self.app.get('/products/get-products-from-category?category=test_category')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result'], [1, 2])

    @patch('database_module.get_product_of_category')
    def test_get_products_by_category_not_found(self, mock_get_product_of_category):
        mock_get_product_of_category.return_value = None
        response = self.app.get('/products/get-products-from-category?category=test_category')
        self.assertEqual(response.status_code, 404)
        self.assertEqual(json.loads(response.data)['error'], 'Products not found for the given category')

    @patch('database_module.get_categories')
    def test_get_all_categories_success(self, mock_get_categories):
        mock_get_categories.return_value = [{'category': 'test_category'}]
        response = self.app.get('/products/get-all-categories')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result'][0]['category'], 'test_category')

    @patch('database_module.get_categories')
    def test_get_all_categories_not_found(self, mock_get_categories):
        mock_get_categories.return_value = None
        response = self.app.get('/products/get-all-categories')
        self.assertEqual(response.status_code, 404)
        self.assertEqual(json.loads(response.data)['error'], 'Categories not found')

    @patch('database_module.search_products_by_name')
    def test_search_product_success(self, mock_search_products_by_name):
        mock_search_products_by_name.return_value = [{'productDetails': {'name': 'Test Product'}}]
        response = self.app.get('/products/search-product?searchTerm=test')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result'][0]['productDetails']['name'], 'Test Product')

    @patch('database_module.search_products_by_name')
    def test_search_product_not_found(self, mock_search_products_by_name):
        mock_search_products_by_name.return_value = []
        response = self.app.get('/products/search-product?searchTerm=test')
        self.assertEqual(response.status_code, 404)
        self.assertEqual(json.loads(response.data)['error'], 'Product not found')

    @patch('security.decode_jwt_token')
    @patch('database_module.add_to_cart')
    def test_add_to_cart_success(self, mock_add_to_cart, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_add_to_cart.return_value = True
        response = self.app.post('/users/add-to-cart', headers={'Authorization': 'Bearer test_token'},
                                 json={'cartItems': [{'productKey': 1, 'noOfItems': 2}]})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result'], 'Successfully add to your cart')

    @patch('security.decode_jwt_token')
    @patch('database_module.add_to_cart')
    def test_add_to_cart_failure(self, mock_add_to_cart, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_add_to_cart.return_value = False
        response = self.app.post('/users/add-to-cart', headers={'Authorization': 'Bearer test_token'},
                                 json={'cartItems': [{'productKey': 1, 'noOfItems': 2}]})
        self.assertEqual(response.status_code, 400)
        self.assertEqual(json.loads(response.data)['error'], 'Failure adding to your cart')

    @patch('security.decode_jwt_token')
    @patch('database_module.remove_from_cart')
    def test_remove_from_cart_success(self, mock_remove_from_cart, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_remove_from_cart.return_value = True
        response = self.app.delete('/users/remove-from-cart', headers={'Authorization': 'Bearer test_token'},
                                   json={'cartItems': [{'productKey': 1, 'noOfItems': 2}]})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result'], 'Successfully remove from your cart')

    @patch('security.decode_jwt_token')
    @patch('database_module.remove_from_cart')
    def test_remove_from_cart_failure(self, mock_remove_from_cart, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_remove_from_cart.return_value = False
        response = self.app.delete('/users/remove-from-cart', headers={'Authorization': 'Bearer test_token'},
                                   json={'cartItems': [{'productKey': 1, 'noOfItems': 2}]})
        self.assertEqual(response.status_code, 400)
        self.assertEqual(json.loads(response.data)['error'], 'Failure removing from your cart')

    @patch('security.decode_jwt_token')
    @patch('database_module.change_no_of_product_in_cart')
    def test_change_no_of_product_in_cart_success(self, mock_change_no_of_product_in_cart, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_change_no_of_product_in_cart.return_value = True
        response = self.app.put('/users/change-no-of-product-in-cart', headers={'Authorization': 'Bearer test_token'},
                                  json={'productKey': 1, 'noOfItems': 3})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result'], 'Successfully change number of product in your cart')

    @patch('security.decode_jwt_token')
    @patch('database_module.change_no_of_product_in_cart')
    def test_change_no_of_product_in_cart_failure(self, mock_change_no_of_product_in_cart, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_change_no_of_product_in_cart.return_value = False
        response = self.app.put('/users/change-no-of-product-in-cart', headers={'Authorization': 'Bearer test_token'},
                                  json={'productKey': 1, 'noOfItems': 3})
        self.assertEqual(response.status_code, 400)
        self.assertEqual(json.loads(response.data)['error'], 'Failure changing number of product in your cart')

    @patch('security.decode_jwt_token')
    @patch('database_module.get_user_by_key')
    @patch('database_module.get_product_from_key')
    def test_get_cart_items_success(self, mock_get_product_from_key, mock_get_user_by_key, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_get_user_by_key.return_value = {'_key': 'test_user_key', 'cartItems': [{'productKey': 1, 'noOfItems': 2}]}
        mock_get_product_from_key.return_value = [{'productDetails': {'name': 'Test Product'}}]
        response = self.app.get('/users/get-cart-items', headers={'Authorization': 'Bearer test_token'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result']['cartModels'][0]['productDetails']['name'], 'Test Product')

    @patch('security.decode_jwt_token')
    @patch('database_module.get_user_by_key')
    def test_get_cart_items_not_found(self, mock_get_user_by_key, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_get_user_by_key.return_value = None
        response = self.app.get('/users/get-cart-items', headers={'Authorization': 'Bearer test_token'})
        self.assertEqual(response.status_code, 404)
        self.assertEqual(json.loads(response.data)['error'], 'Cart items not found')

    @patch('security.decode_jwt_token')
    @patch('database_module.place_order')
    def test_place_order_success(self, mock_place_order, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_place_order.return_value = {'result': True}
        response = self.app.post('/orders/place-order', headers={'Authorization': 'Bearer test_token'},
                                  json=[{'productKey': 1, 'noOfItems': 2}])
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result'], 'Successfully place order')

    @patch('security.decode_jwt_token')
    @patch('database_module.place_order')
    def test_place_order_failure(self, mock_place_order, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_place_order.return_value = {'result': False, 'message': 'Order failed'}
        response = self.app.post('/orders/place-order', headers={'Authorization': 'Bearer test_token'},
                                  json=[{'productKey': 1, 'noOfItems': 2}])
        self.assertEqual(response.status_code, 400)
        self.assertEqual(json.loads(response.data)['result'], 'Order failed')

    @patch('security.decode_jwt_token')
    @patch('database_module.get_orders_of_user')
    @patch('database_module.get_product_from_key')
    def test_get_all_orders_success(self, mock_get_product_from_key, mock_get_orders_of_user, mock_decode_jwt_token):
        mock_decode_jwt_token.return_value = 'test_user_key'
        mock_get_orders_of_user.return_value = [{'_key': 'test_order_key', 'productKey': 1, 'noOfItems': 2,
                                                 'orderedDate': '2023-12-12', 'paidPrice': 100, 'paymentStatus': 'paid',
                                                 'deliveryStages': ['shipped'], 'deliveryAddress': 'test address'}]
        mock_get_product_from_key.return_value = [{'productDetails': {'name': 'Test Product'}}]
        response = self.app.get('/users/get-all-orders', headers={'Authorization': 'Bearer test_token'})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result'][0]['orderModel']['productDetails']['name'], 'Test Product')

    @patch('rcm_model.get_recommendations')
    def test_get_related_products_success(self, mock_get_recommendations):
        mock_get_recommendations.return_value = [1, 2]
        response = self.app.get('/products/get-related-products?productKey=1')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['result'], [1, 2])

    @patch('stripe.PaymentIntent.create')
    def test_create_payment_intent_success(self, mock_payment_intent_create):
        mock_payment_intent_create.return_value = {'status': 'succeeded'}
        response = self.app.post('/users/payment', json={'body': json.dumps({'amount': 100, 'currency': 'usd'})})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['message'], 'Payment Completed Successfully')

    @patch('stripe.PaymentIntent.create')
    def test_create_payment_intent_pending(self, mock_payment_intent_create):
        mock_payment_intent_create.return_value = {'status': 'processing', 'client_secret': 'test_client_secret'}
        response = self.app.post('/users/payment', json={'body': json.dumps({'amount': 100, 'currency': 'usd'})})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(json.loads(response.data)['message'], 'Confirm payment please')
        self.assertEqual(json.loads(response.data)['client_secret'], 'test_client_secret')

    @patch('stripe.PaymentIntent.create')
    def test_create_payment_intent_error(self, mock_payment_intent_create):
        mock_payment_intent_create.side_effect = Exception('Payment error')
        response = self.app.post('/users/payment', json={'body': json.dumps({'amount': 100, 'currency': 'usd'})})
        self.assertEqual(response.status_code, 500)
        self.assertEqual(json.loads(response.data)['error'], 'Payment error')

    def tearDown(self):
        pass

if __name__ == '__main__':
    unittest.main()
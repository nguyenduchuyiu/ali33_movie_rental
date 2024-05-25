import unittest
import sqlite3
import datetime
import database_module as dm
import security as sc

class DatabaseModuleTests(unittest.TestCase):


    def test_is_registered(self):
        # Test with existing email
        self.assertTrue(dm.is_registered('test@example.com'))
        # Test with non-existing email
        self.assertFalse(dm.is_registered('nonexistent@example.com'))

    def test_get_user_for_login(self):
        # Test with existing email
        user = dm.get_user_for_login('test@example.com')
        self.assertIsNotNone(user)
        self.assertEqual(user['_key'], 1)
        self.assertEqual(user['hashed_password'], b'$2b$12$v6Qz/5lH4C3M0xR9q9r.we2xW2aW6Oq6.V1zXg5V23G')

        # Test with non-existing email
        user = dm.get_user_for_login('nonexistent@example.com')
        self.assertIsNone(user)

    def test_create_user(self):
        # Test successful user creation
        self.assertTrue(dm.create_user('testuser', 'newtest@example.com', 'password123'))
        # Check if the new user exists
        self.cursor.execute("SELECT _key FROM users WHERE emailId = 'newtest@example.com'")
        user_key = self.cursor.fetchone()
        self.assertIsNotNone(user_key)
        # Test duplicate user creation
        self.assertFalse(dm.create_user('testuser', 'newtest@example.com', 'password123'))

    def test_get_user_by_key(self):
        # Test with existing user key
        user = dm.get_user_by_key(1)
        self.assertIsNotNone(user)
        self.assertEqual(user['_key'], 1)
        self.assertEqual(user['emailId'], 'test@example.com')
        self.assertEqual(user['phoneNo'], '1234567890')
        self.assertEqual(user['proprietorName'], 'Test User')
        self.assertEqual(user['gst'], 'GST1234567890')
        self.assertEqual(len(user['orders']), 2)
        self.assertEqual(len(user['cartItems']), 1)

        # Test with non-existing user key
        user = dm.get_user_by_key(999)
        self.assertIsNone(user)

    def test_get_categories(self):
        categories = dm.get_categories()
        self.assertIsNotNone(categories)
        self.assertEqual(len(categories), 3)
        # Assert specific category data
        self.assertEqual(categories[0]['_key'], 1)
        self.assertEqual(categories[0]['categoryName'], 'Fruits')
        self.assertEqual(categories[0]['categoryPicture'], 'fruits.jpg')

    def test_search_products_by_name(self):
        # Test with exact match
        products = dm.search_products_by_name('Apple')
        self.assertIsNotNone(products)
        self.assertEqual(len(products), 1)
        self.assertEqual(products[0]['productDetails']['_key'], 1)
        self.assertEqual(products[0]['productDetails']['productName'], 'Apple')
        # Test with partial match
        products = dm.search_products_by_name('app')
        self.assertIsNotNone(products)
        self.assertEqual(len(products), 1)
        # Test with no match
        products = dm.search_products_by_name('NonexistentProduct')
        self.assertIsNotNone(products)
        self.assertEqual(len(products), 0)

    def test_get_product_from_key(self):
        # Test getting product by key
        products = dm.get_product_from_key({'type': 'product', 'key': 1})
        self.assertIsNotNone(products)
        self.assertEqual(len(products), 1)
        self.assertEqual(products[0]['productDetails']['_key'], 1)
        self.assertEqual(products[0]['productDetails']['productName'], 'Apple')
        # Test getting products by category
        products = dm.get_product_from_key({'type': 'category', 'key': 1})
        self.assertIsNotNone(products)
        self.assertGreaterEqual(len(products), 1) # Expect at least one product in the category

    def test_add_to_cart(self):
        # Test adding a new item to cart
        self.assertTrue(dm.add_to_cart({'productKey': 1, 'noOfItems': 2, 'variationQuantity': 5}, 1))
        # Test adding an existing item to cart
        self.assertTrue(dm.add_to_cart({'productKey': 1, 'noOfItems': 1, 'variationQuantity': 5}, 1))
        # Check if the quantity has been updated in the database
        self.cursor.execute("SELECT noOfItems FROM cart_items WHERE userKey = 1 AND productKey = 1 AND variationQuantity = 5")
        no_of_items = self.cursor.fetchone()
        self.assertEqual(no_of_items[0], 3)

    def test_remove_from_cart(self):
        # Test removing an item from cart
        self.assertTrue(dm.remove_from_cart([{'productKey': 1, 'noOfItems': 1, 'variationQuantity': 5}], 1))
        # Check if the item has been removed from the database
        self.cursor.execute("SELECT * FROM cart_items WHERE userKey = 1 AND productKey = 1 AND variationQuantity = 5")
        result = self.cursor.fetchone()
        self.assertIsNone(result)

    def test_change_no_of_product_in_cart(self):
        # Test updating quantity of existing item
        self.assertTrue(dm.change_no_of_product_in_cart({'old': {'productKey': 1, 'variationQuantity': 5, 'noOfItems': 1}, 'new': {'productKey': 1, 'variationQuantity': 5, 'noOfItems': 3}}, 1))
        # Check if the quantity has been updated in the database
        self.cursor.execute("SELECT noOfItems FROM cart_items WHERE userKey = 1 AND productKey = 1 AND variationQuantity = 5")
        no_of_items = self.cursor.fetchone()
        self.assertEqual(no_of_items[0], 3)

    def test_place_order(self):
        # Test placing an order
        orders = [
            {'deliveryAddress': 'Test Address', 'deliveryStages': ['Order Placed', 'Payment Confirmed', 'Order Processed', 'Ready to Pickup'], 'orderedDate': int(datetime.datetime.now().timestamp()), 'paidPrice': 100, 'paymentStatus': 1, 'productDetails': {'productKey': 1, 'noOfItems': 1, 'variationQuantity': 5}}
        ]
        self.assertTrue(dm.place_order({'orders': orders}, 1))
        # Check if the order has been placed in the database
        self.cursor.execute("SELECT * FROM orders WHERE userKey = 1 AND productKey = 1 AND variationQuantity = 5")
        result = self.cursor.fetchone()
        self.assertIsNotNone(result)

    def test_get_orders_of_user(self):
        orders = dm.get_orders_of_user(1)
        self.assertIsNotNone(orders)
        self.assertEqual(len(orders), 2)
        # Assert specific order data
        self.assertEqual(orders[0]['_key'], 1)
        self.assertEqual(orders[0]['productKey'], 1)
        self.assertEqual(orders[0]['orderedDate'], 1677721600) # Sample timestamp
        self.assertEqual(orders[0]['paidPrice'], 10.0)
        self.assertEqual(orders[0]['paymentStatus'], 1)
        self.assertEqual(orders[0]['deliveryStages'], ['Order Placed', 'Payment Confirmed', 'Order Processed', 'Ready to Pickup'])
        self.assertEqual(orders[0]['deliveryAddress'], 'Test Address')
        self.assertEqual(orders[0]['noOfItems'], 1)
        self.assertEqual(orders[0]['variationQuantity'], 5)
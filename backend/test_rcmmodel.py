import unittest
import rcm_model as rcm

class RecommendationModelTests(unittest.TestCase):

    def test_get_recommendations(self):
        # Test with valid movie ID
        recommendations = rcm.get_recommendations(0) # Assuming 0 is a valid movie ID in your dataset
        self.assertIsNotNone(recommendations)
        self.assertGreaterEqual(len(recommendations), 1) 

        # Test with invalid movie ID (out of bounds)
        recommendations = rcm.get_recommendations(10000) 
        self.assertEqual(len(recommendations), 0) # Expect an empty list for invalid ID

    def test_get_related_products(self):
        # Test with existing product name
        recommendations = rcm.get_related_products('The Shawshank Redemption')
        self.assertIsNotNone(recommendations)
        self.assertGreaterEqual(len(recommendations), 1) # Expect at least one recommendation

        # Test with non-existing product name
        recommendations = rcm.get_related_products('NonexistentProduct')
        self.assertEqual(len(recommendations), 0) # Expect an empty list for non-existing product
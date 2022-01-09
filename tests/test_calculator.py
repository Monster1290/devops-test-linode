"""
Unit tests for the calculator library
"""

import calc.calculator


class TestCalculator:

    def test_addition(self):
        assert 4 == calc.calculator.add(2, 2)

    def test_subtraction(self):
        assert 2 == calc.calculator.subtract(4, 2)

    def test_multiplication(self):
        assert 100 == calc.calculator.multiply(10, 10)

    def test_division(self):
        assert 5 == calc.calculator.division(10, 2)

    def test_power(self):
        assert 1000 == calc.calculator.power(10, 3)
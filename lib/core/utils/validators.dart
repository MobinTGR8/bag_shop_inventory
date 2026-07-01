class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    final price = double.tryParse(value);
    if (price == null || price <= 0) return 'Enter a valid price';
    return null;
  }

  static String? validateQuantity(String? value) {
    if (value == null || value.isEmpty) return 'Quantity is required';
    final quantity = int.tryParse(value);
    if (quantity == null || quantity <= 0) return 'Enter a valid quantity';
    return null;
  }

  static String? validateSKU(String? value) {
    if (value == null || value.isEmpty) return 'SKU is required';
    if (value.length < 3) return 'SKU must be at least 3 characters';
    return null;
  }

  static String? validateBarcode(String? value) {
    if (value == null || value.isEmpty) return null; // Barcode is optional
    if (value.length < 8) return 'Barcode must be at least 8 characters';
    return null;
  }
}

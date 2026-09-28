/// Mandi weight conversion and pricing math utility.
///
/// In Pakistani agricultural mandi trading:
/// - Base unit: 1 Mann / Maund = 40 Kilograms (KG).
/// - Pricing convention: All prices are quoted per 40 KG (Maund).
/// - Calculation formula:
///     Manns = Total Weight (KG) / 40.0
///     Total Price = Manns * Price per 40 KG
class MandiCalculator {
  static const double kgPerMann = 40.0;

  /// Converts Kilograms into Manns (Maunds).
  static double kgToMann(double weightKg) => weightKg / kgPerMann;

  /// Converts Manns (Maunds) into Kilograms.
  static double mannToKg(double manns) => manns * kgPerMann;

  /// Calculates total price for a given weight (in KG) based on price per 40 KG.
  ///
  /// Example:
  ///   weightKg = 120.0 KG
  ///   pricePer40kg = 5,000 PKR
  ///   Manns = 120 / 40 = 3.0 Manns
  ///   Total = 3.0 * 5,000 = 15,000 PKR
  static double calculateTotalAmount({
    required double weightKg,
    required double pricePer40kg,
  }) {
    final manns = kgToMann(weightKg);
    return manns * pricePer40kg;
  }

  /// Formats weight in both KG and Manns for UI display.
  /// e.g. "120 KG (3.00 Mann)" or "50 KG (1.25 Mann)"
  static String formatWeightDisplay(double weightKg) {
    final manns = kgToMann(weightKg);
    final formattedKg = weightKg.toStringAsFixed(
        weightKg.truncateToDouble() == weightKg ? 0 : 1);
    final formattedManns =
        manns.toStringAsFixed(manns.truncateToDouble() == manns ? 0 : 2);
    return '$formattedKg KG ($formattedManns Mann)';
  }

  /// Detailed calculation breakdown string for UI preview and receipts.
  static String formatCalculationBreakdown({
    required double weightKg,
    required double pricePer40kg,
  }) {
    final manns = kgToMann(weightKg);
    final total = calculateTotalAmount(
        weightKg: weightKg, pricePer40kg: pricePer40kg);
    final formattedManns = manns.toStringAsFixed(2);
    final formattedPrice = pricePer40kg.toStringAsFixed(0);
    final formattedTotal = total.toStringAsFixed(0);

    return '${weightKg.toStringAsFixed(0)} KG = $formattedManns Mann @ Rs. $formattedPrice = Rs. $formattedTotal';
  }
}

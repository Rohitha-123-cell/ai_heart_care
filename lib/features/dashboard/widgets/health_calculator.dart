class HealthCalculator {

  static double calculateBMI(double weight, double height) {
    return weight / ((height / 100) * (height / 100));
  }

  static int calculateScore(double bmi) {

    if (bmi < 18.5) return 60;
    if (bmi < 25) return 90;
    if (bmi < 30) return 70;
    return 50;
  }
}
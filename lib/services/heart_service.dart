class HeartService {

  double predictRisk({
    required int age,
    required double bmi,
    required bool smoker,
    required bool diabetic,
  }) {

    double risk = 0;

    if (age > 45) risk += 20;
    if (bmi > 25) risk += 20;
    if (smoker) risk += 30;
    if (diabetic) risk += 30;

    return risk.clamp(0, 100);
  }
}
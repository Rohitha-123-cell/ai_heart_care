import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

/// Heart Rate Service - Signal Processing for Camera PPG
/// Handles finger detection, signal capture, and BPM calculation
class HeartRateService {
  // Signal processing constants
  static const int sampleRateMs = 40; // 25 fps
  static const int measurementDurationSec = 15;
  static const int minSamples = 150; // Lowered from 360 for faster detection (~6 seconds)
  
  // Finger detection thresholds - Lowered for better compatibility
  static const int minRedIntensity = 30; // Lowered from 80 for better detection
  static const int maxRedIntensity = 255; // Allow full range
  
  // Peak detection
  static const double peakThreshold = 0.6; // Threshold as fraction of signal range
  static const double minPeakDistanceMs = 300; // Minimum ms between peaks (max 200 BPM)
  static const int maxPeakDistanceMs = 1500; // Maximum ms between peaks (min 40 BPM)

  /// Analyze a single frame and return average red intensity
  /// Returns null if frame is invalid
  int? analyzeFrame(Uint8List bytes, int width, int height) {
    if (bytes.isEmpty) return null;
    
    try {
      // For RGBA format (4 bytes per pixel)
      // Sample from center region (more accurate for finger)
      int sum = 0;
      int count = 0;
      
      // Sample from center 50% of the image
      final startX = (width * 0.25).round();
      final endX = (width * 0.75).round();
      final startY = (height * 0.25).round();
      final endY = (height * 0.75).round();
      
      // Skip every other pixel for performance
      for (int y = startY; y < endY; y += 2) {
        for (int x = startX; x < endX; x += 2) {
          final index = (y * width + x) * 4;
          if (index + 2 < bytes.length) {
            // Red channel is at index 0 in RGBA
            sum += bytes[index];
            count++;
          }
        }
      }
      
      return count > 0 ? (sum ~/ count) : null;
    } catch (e) {
      return null;
    }
  }

  /// Check if finger is detected based on red intensity
  /// Finger should cover camera with good blood flow
  bool isFingerDetected(int redIntensity) {
    return redIntensity >= minRedIntensity && redIntensity <= maxRedIntensity;
  }

  /// Get finger detection message
  String getFingerStatus(int? redIntensity) {
    if (redIntensity == null) return "No signal detected";
    if (redIntensity < minRedIntensity) return "Place finger on camera";
    if (redIntensity > maxRedIntensity) return "Too much light - move finger";
    return "Finger detected";
  }

  /// Apply moving average filter to smooth signal
  List<double> applyMovingAverage(List<int> values, int windowSize) {
    if (values.length < windowSize) return values.map((e) => e.toDouble()).toList();
    
    List<double> smoothed = [];
    for (int i = 0; i < values.length; i++) {
      int start = max(0, i - windowSize ~/ 2);
      int end = min(values.length, i + windowSize ~/ 2 + 1);
      
      double sum = 0;
      for (int j = start; j < end; j++) {
        sum += values[j];
      }
      smoothed.add(sum / (end - start));
    }
    return smoothed;
  }

  /// Apply bandpass filter to remove noise
  /// Removes very low frequency (baseline drift) and high frequency noise
  List<double> applyBandpassFilter(List<double> values) {
    if (values.length < 5) return values;
    
    List<double> filtered = [];
    for (int i = 0; i < values.length; i++) {
      if (i < 2 || i >= values.length - 2) {
        filtered.add(values[i]);
        continue;
      }
      
      // Simple bandpass approximation
      double prev = values[i - 2];
      double curr = values[i];
      double next = values[i + 2];
      
      // Remove baseline drift, keep pulse
      filtered.add(curr - (prev + next) / 2);
    }
    return filtered;
  }

  /// Find peaks in the filtered signal using threshold-based detection
  List<int> findPeaks(List<double> values) {
    if (values.length < 5) return [];
    
    // Calculate dynamic threshold
    double maxVal = values.reduce(max);
    double minVal = values.reduce(min);
    double range = maxVal - minVal;
    
    if (range < 5) return []; // Signal too flat
    
    double threshold = minVal + (range * peakThreshold);
    
    List<int> peaks = [];
    for (int i = 2; i < values.length - 2; i++) {
      // Peak: local maximum above threshold
      if (values[i] > values[i - 1] &&
          values[i] > values[i + 1] &&
          values[i] > values[i - 2] &&
          values[i] > values[i + 2] &&
          values[i] > threshold) {
        
        // Check minimum distance from last peak
        if (peaks.isEmpty || (i - peaks.last) * sampleRateMs >= minPeakDistanceMs) {
          peaks.add(i);
        }
      }
    }
    
    return peaks;
  }

  /// Calculate BPM from peak list and timestamps
  /// Returns null if not enough valid peaks
  int? calculateBPM(List<int> peaks, List<DateTime> timestamps) {
    if (peaks.length < 3) return null;
    
    // Calculate intervals between consecutive peaks
    List<double> intervals = [];
    for (int i = 1; i < peaks.length; i++) {
      int intervalMs = timestamps[peaks[i]].difference(timestamps[peaks[i - 1]]).inMilliseconds;
      
      // Filter out unrealistic intervals
      if (intervalMs >= minPeakDistanceMs && intervalMs <= maxPeakDistanceMs) {
        intervals.add(intervalMs.toDouble());
      }
    }
    
    if (intervals.isEmpty) return null;
    
    // Calculate average interval
    double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    
    // Convert to BPM
    int bpm = (60000 / avgInterval).round();
    
    // Validate BPM is in reasonable range
    if (bpm < 40 || bpm > 180) return null;
    
    return bpm;
  }

  /// Process collected samples and calculate heart rate
  /// Returns null if processing fails
  int? processSamples(List<int> samples, List<DateTime> timestamps) {
    if (samples.length < minSamples) return null;
    
    // Step 1: Apply moving average filter
    List<double> smoothed = applyMovingAverage(samples, 5);
    
    // Step 2: Apply bandpass filter
    List<double> filtered = applyBandpassFilter(smoothed);
    
    // Step 3: Find peaks
    List<int> peaks = findPeaks(filtered);
    
    // Step 4: Calculate BPM
    return calculateBPM(peaks, timestamps);
  }

  /// Get signal quality indicator (0-100)
  int getSignalQuality(List<int> samples) {
    if (samples.length < 10) return 0;
    
    // Calculate signal range
    int maxVal = samples.reduce(max);
    int minVal = samples.reduce(min);
    int range = maxVal - minVal;
    
    // Good PPG signal should have range of at least 20
    if (range < 10) return 10; // Very poor
    if (range < 20) return 30; // Poor
    if (range < 40) return 50; // Fair
    if (range < 60) return 70; // Good
    return 90; // Excellent
  }

  /// Analyze heart rate and return health status
  String analyzeHeartRate(int bpm) {
    if (bpm < 60) {
      return "Bradycardia (Low HR) - May be normal for athletes";
    } else if (bpm < 70) {
      return "Excellent - Very good cardiovascular fitness";
    } else if (bpm < 80) {
      return "Normal - Healthy resting heart rate";
    } else if (bpm < 100) {
      return "Elevated - May indicate stress or activity";
    } else {
      return "Tachycardia (High HR) - Consider relaxation techniques";
    }
  }

  /// Get heart rate category
  String getHeartRateCategory(int bpm) {
    if (bpm < 60) return "Low";
    if (bpm < 80) return "Normal";
    if (bpm < 100) return "Elevated";
    return "High";
  }

  /// Get heart rate color value (for UI)
  int getHeartRateColor(int bpm) {
    if (bpm < 60) return 0xFF2196F3; // Blue
    if (bpm < 80) return 0xFF4CAF50; // Green
    if (bpm < 100) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  /// Get recommendation based on heart rate
  String getRecommendation(int bpm) {
    if (bpm < 60) {
      return "Your resting heart rate is low. This is usually good for cardiovascular fitness, but if you feel dizzy or fatigued, please consult a doctor.";
    } else if (bpm < 80) {
      return "Your heart rate is in the ideal range! Keep up with regular exercise to maintain your cardiovascular health.";
    } else if (bpm < 100) {
      return "Your heart rate is slightly elevated. Try deep breathing exercises, stay hydrated, and ensure you're well-rested.";
    } else {
      return "Your heart rate is high. If this persists at rest, please consult a healthcare professional. Try relaxation techniques.";
    }
  }

  /// Get risk assessment based on heart rate
  double getRiskScore(int bpm) {
    if (bpm < 50 || bpm > 120) return 0.8;
    if (bpm < 60 || bpm > 100) return 0.4;
    return 0.1;
  }

  /// Validate if BPM is in acceptable range
  bool isValidBPM(int bpm) {
    return bpm >= 30 && bpm <= 220;
  }

  /// Get ideal resting heart rate range
  String getIdealRange() {
    return "60-80 BPM for adults at rest";
  }

  /// Generate simulated heart rate data for demo purposes
  List<int> generateSimulatedData(int count, {int baseHR = 72}) {
    final random = Random();
    List<int> data = [];
    int currentBase = baseHR;
    
    for (int i = 0; i < count; i++) {
      int variation = random.nextInt(10) - 5;
      int simulatedBPM = (currentBase + variation).clamp(55, 95);
      
      if (random.nextDouble() < 0.08) {
        simulatedBPM += random.nextInt(12);
      }
      
      currentBase = (currentBase + random.nextInt(3) - 1).clamp(65, 82);
      data.add(simulatedBPM);
    }
    
    return data;
  }

  /// Get heart rate data from fingerprint sensor simulation
  /// In a real implementation, this would read from actual biometric hardware
  /// Returns a map with heart rate and signal quality
  Map<String, dynamic>? getHeartRateFromFingerprint() {
    final random = Random();
    
    // Generate realistic heart rate based on time and random factors
    // This simulates what a real PPG (photoplethysmography) sensor would return
    final baseHR = 65 + random.nextInt(25); // Base heart rate between 65-90 BPM
    final variation = random.nextInt(15) - 7; // Random variation of -7 to +7
    final heartRate = (baseHR + variation).clamp(55, 105);
    
    // Signal quality based on random factors (simulating sensor contact quality)
    final signalQuality = 60 + random.nextInt(40); // 60-100% quality
    
    return {
      'heartRate': heartRate,
      'signalQuality': signalQuality,
      'timestamp': DateTime.now(),
      'isValid': signalQuality > 50,
    };
  }

  /// Calculate stress level from heart rate variability (HRV)
  /// Higher HRV = lower stress, Lower HRV = higher stress
  double calculateStressFromHRV(double hrvScore) {
    // HRV score is typically 0-100
    // Lower HRV = higher stress (0 = very stressed, 100 = very relaxed)
    if (hrvScore < 20) return 80; // Very high stress
    if (hrvScore < 40) return 60; // High stress
    if (hrvScore < 60) return 40; // Moderate stress
    if (hrvScore < 80) return 20; // Low stress
    return 10; // Very low stress (relaxed)
  }

  /// Get breathing rate estimate from heart rate patterns
  /// At rest, breathing is typically 12-20 breaths per minute
  double estimateBreathingRate(int heartRate) {
    // Higher heart rate often correlates with faster breathing
    if (heartRate < 60) return 12.0;
    if (heartRate < 70) return 14.0;
    if (heartRate < 80) return 16.0;
    if (heartRate < 90) return 18.0;
    return 20.0;
  }
}

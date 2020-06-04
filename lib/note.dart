class Note {
  String Sensor_value;
  String Measure_time;

  Note(this.Sensor_value, this.Measure_time);

  Note.fromJson(Map<String, dynamic> json) {
    Sensor_value = json['value1'];
    Measure_time = json['reading_time'];
  }
}
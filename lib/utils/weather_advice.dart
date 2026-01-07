class WeatherAdvice {
  // Hàm 1: Gợi ý trang phục dựa trên nhiệt độ
  static String getOutfitAdvice(double temp) {
    if (temp < 15) {
      return "Trời lạnh buốt! Hãy mặc áo phao dày, khăn quàng cổ và giữ ấm kỹ nhé.";
    } else if (temp < 23) {
      return "Se lạnh dễ chịu. Một chiếc áo khoác gió hoặc Hoodie là lựa chọn hoàn hảo.";
    } else if (temp < 30) {
      return "Thời tiết mát mẻ, quần Jean và áo thun là set đồ năng động nhất.";
    } else {
      return "Nắng nóng! Ưu tiên quần áo mỏng nhẹ, thoáng mát và màu sáng.";
    }
  }

  // Hàm 2: Gợi ý hoạt động dựa trên mô tả thời tiết
  static String getActivityAdvice(String condition) {
    String state = condition.toLowerCase();
    if (state.contains("rain") || state.contains("mưa") || state.contains("drizzle")) {
      return "Trời có mưa. Tốt nhất là cafe trong nhà hoặc nhớ mang dù nếu ra ngoài.";
    } else if (state.contains("clear") || state.contains("sunny") || state.contains("nắng")) {
      return "Trời đẹp tuyệt vời! Rất thích hợp để chụp ảnh, dã ngoại hoặc chạy bộ.";
    } else if (state.contains("cloud") || state.contains("mây")) {
      return "Trời nhiều mây, thời tiết dịu nhẹ, thích hợp cho các hoạt động ngoài trời.";
    } else if (state.contains("thunder") || state.contains("bão")) {
      return "Cảnh báo dông bão! Hạn chế ra đường để đảm bảo an toàn.";
    } else {
      return "Tận hưởng ngày mới với năng lượng tích cực nhé!";
    }
  }
}
# Vườn Dâu Thông Minh

Hệ thống chăm sóc 4 cây dâu tây trồng trên giá thể xơ dừa trong nhà, dùng mạch **Yolo UNO (OhStem)**, giao tiếp qua **MQTT**, lưu dữ liệu trên **Supabase** và có webapp giám sát, điều khiển, nhận diện bệnh qua ảnh.

**Mở webapp:** https://phat0188.github.io/vuon-dau-thong-minh/

## Chức năng

- Theo dõi nhiệt độ, độ ẩm không khí (DHT20), độ ẩm xơ dừa, ánh sáng; biểu đồ 1 giờ, 24 giờ, 7 ngày; xuất CSV.
- Hồ sơ 4 cây: ngày trồng, giai đoạn hiện tại và sắp tới, bệnh cần chú ý theo giai đoạn, nhật ký ảnh.
- Chăm sóc tự động theo 6 giai đoạn: số giờ chiếu sáng, màu đèn theo khung giờ, EC dinh dưỡng, số lần tưới.
- Pha và tưới tự động: bơm dinh dưỡng và nước vào bình pha theo đúng tỉ lệ EC, chờ trộn, rồi bơm tưới lên cây.
- Chụp ảnh bằng camera, nhận mã cây qua tem QR, nhận diện bệnh bằng mô hình Teachable Machine.
- Điều khiển tay, chế độ tự động theo ngưỡng, lịch hẹn giờ chạy trên Yolo UNO theo giờ module RTC.

## Phần cứng

| Linh kiện | Kết nối |
|---|---|
| Yolo UNO (ESP32-S3) | |
| DHT20, PCF8563 (RTC), Relay 4 kênh I2C | Cổng I2C |
| Relay 1 / 2 / 3 / 4 | Quạt / bơm nước vào bình pha / bơm dinh dưỡng / bơm tưới |
| Cảm biến ánh sáng | A0 |
| Cảm biến độ ẩm đất | A1 |
| LED Neopixel (đèn chiếu sáng) | D8 |

## Thư mục

| Đường dẫn | Nội dung |
|---|---|
| `index.html` | Webapp (một file, không cần cài đặt) |
| `yolo-uno/vuon_dau_thong_minh.json` | Chương trình kéo thả cho app.ohstem.vn (Nhập project). Cần thư viện PCF8563, Relay 4 kênh, NEOPIXEL |
| `supabase/supabase_vuon_dau.sql` | Tạo bảng cơ sở dữ liệu trên Supabase (dán vào SQL Editor) |

## Cài đặt nhanh

1. **Yolo UNO:** vào app.ohstem.vn, chọn Yolo UNO, Lập trình, Nhập project từ `yolo-uno/vuon_dau_thong_minh.json`. Sửa `TEN_WIFI`, `MAT_KHAU_WIFI` trong khối kết nối, rồi lưu dự án vào thiết bị.
2. **Supabase:** chạy file SQL trong SQL Editor; nhập Project URL và khoá anon ở tab Kết nối MQTT của webapp.
3. **Webapp:** mở đường link ở trên, vào tab Chăm sóc tự động và bấm “Tạo lịch và gửi xuống Yolo UNO”.

## Lưu ý

- Máy chủ MQTT đang dùng là `broker.hivemq.com` (công cộng). Mã vườn `dautay_a7k29` là phần đầu của mọi topic.
- Khoá Supabase trong webapp là khoá **anon** (công khai được, đã bật Row Level Security). Không đưa khoá `service_role` vào kho này.
- Không đưa tên và mật khẩu WiFi lên kho.

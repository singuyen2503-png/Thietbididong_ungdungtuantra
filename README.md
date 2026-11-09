# Tactical Patrol Ops

Ứng dụng Flutter quản lý tuần tra bảo vệ, gồm 2 vai trò **Bảo vệ** và **Chỉ huy**.
Đồ án cuối kỳ học phần *Lập trình trên thiết bị di động (ECMP177)*.

## Chức năng chính

**Bảo vệ**
- Đăng nhập bằng mã PIN riêng hoặc vân tay / khuôn mặt
- Xem ca trực, bản đồ lộ trình, thiết bị được cấp
- Tuần tra theo GPS, chỉ được quét khi ở trong bán kính 15 m của điểm (Geofencing)
- Quét mã QR tại từng điểm, theo dõi tiến độ ca
- Báo cáo sự cố 4 mức độ kèm ảnh và ghi âm hiện trường, nhận lệnh chi viện
- Báo cháy: chọn vị trí, phát còi và cảnh báo tới Chỉ huy
- Chấm công vào / ra ca (tính đi trễ), xem công cá nhân, lịch trực tuần của mình
- Xin nghỉ phép và theo dõi trạng thái đơn

**Chỉ huy**
- Thanh điều hướng 4 tab: Trực ban (ca hôm nay, sự cố, giám sát), Lịch trực, Nhân sự, Thiết lập
- Giám sát các ca đang đi tuần: tiến độ, đường đã đi, điểm kế tiếp
- Xử lý sự cố: điều động chi viện, đóng sự cố kèm ghi chú
- Vẽ lộ trình, chấm điểm tuần tra, in mã QR cho từng điểm
- Phân ca trực Sáng / Chiều / Tối, lên lịch trực theo tuần, sao chép tuần trước
- Bảng chấm công tổng và theo nhân viên; duyệt nghỉ phép
- Quét bản đồ khu vực lần đầu (đi một vòng) làm bản đồ nền
- Thêm địa điểm tuần tra mới (chọn trên bản đồ hoặc GPS), tạo mã QR mới, chia sẻ / in ảnh mã QR
- Phân ca trực kèm lộ trình và thiết bị; bảo vệ vào ca thì tự tạo ca tuần tra, cấp và thu hồi thiết bị
- Quản lý nhân sự (kèm PIN đăng nhập), đánh dấu và xóa nhân viên đã nghỉ việc; quản lý thiết bị

Dữ liệu được lưu cục bộ trên thiết bị (vẫn dùng được khi mất mạng) và đồng bộ thời gian thực giữa các máy qua Cloud Firestore khi đã cấu hình Firebase.

## Công nghệ

| Thành phần | Thư viện |
|---|---|
| Framework | Flutter 3 / Dart 3 |
| State management | flutter_riverpod |
| Lưu trữ cục bộ | shared_preferences |
| Đồng bộ dữ liệu | firebase_core, cloud_firestore |
| Chia sẻ ảnh mã QR | share_plus |
| Định vị | geolocator |
| Quét QR / sinh QR | mobile_scanner, qr_flutter |
| Camera / ảnh | image_picker, permission_handler |
| Ghi âm / phát âm thanh | record, audioplayers, path_provider |
| Sinh trắc học | local_auth |
| Bản đồ | flutter_map, latlong2 (vẽ điểm, lộ trình, đường đã quét; không dùng bản đồ nền trực tuyến) |

## Cấu trúc thư mục

```
lib/
├── core/utils/            # LatLng, Haversine, ngày giờ, so khớp mã QR
├── domain/entities/       # Incident, RouteConfig, Schedule, Checkpoint, Personnel, Equipment
├── data/
│   ├── datasources/       # LocalStore (SharedPreferences)
│   └── models/            # Chuyển đổi Entity <-> JSON
└── presentation/
    ├── features/          # auth, dashboard, attendance, leave, incident, management, patrol
    ├── state/             # Riverpod providers & notifiers
    └── widgets/           # Bản đồ (flutter_map), radar, cảnh báo cháy, slide-to-act
```

## Sơ đồ dữ liệu (ERD)

Sơ đồ thực thể nằm trong `docs/ERD.drawio` (mở bằng [diagrams.net](https://app.diagrams.net)). Mỗi bảng trong ERD là một collection trên Firestore và một khóa trong bộ nhớ cục bộ.

## Cấu hình Firebase

File cấu hình Firebase không được đưa lên Git. Để bật đồng bộ:

1. Tạo project trên [Firebase Console](https://console.firebase.google.com), thêm ứng dụng Android với package name trong `android/app/build.gradle.kts`.
2. Tải `google-services.json` đặt vào `android/app/`.
3. Bật Cloud Firestore và đặt Security Rules phù hợp.

Nếu chưa cấu hình Firebase, ứng dụng vẫn chạy và chỉ lưu dữ liệu cục bộ (bản Android cần có file `google-services.json` mới build được).

## Chạy ứng dụng

```bash
flutter pub get
flutter run
```

Tài khoản mẫu:

| Vai trò | PIN |
|---|---|
| Bảo vệ Nguyễn Văn A | 1234 |
| Bảo vệ Trần Thị B | 2345 |
| Bảo vệ Lê Văn C | 3456 |
| Chỉ huy | 5678 |

## Mã QR điểm tuần tra

Dữ liệu mẫu có lộ trình "Tuyến tuần tra mẫu" gồm 3 điểm. Mã in sẵn nằm trong `docs/qr/` (`in_A4_3_ma_QR.pdf` để in cả 3 mã trên một trang A4):

| Điểm | Nội dung mã QR |
|---|---|
| Nhà kho | `nhà kho` |
| Nhà xe | `nhà xe` |
| Hành lang | `hành lang` |

Mặc định ứng dụng dùng GPS giả lập (tự di chuyển đến điểm kế tiếp) để demo. Dùng GPS thật:

```bash
flutter run --dart-define=USE_REAL_GPS=true
```

Trên Web không có camera nên màn hình quét QR được giả lập. Chỉ huy có nút ↺ để khôi phục dữ liệu mẫu.

## Kiểm thử

```bash
flutter analyze
flutter test
```

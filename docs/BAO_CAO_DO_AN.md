# BÁO CÁO ĐỒ ÁN CUỐI KỲ

---

## 1. TRANG BÌA

| | |
|---|---|
| **Trường / Khoa** | `[Điền tên Trường / Khoa]` |
| **Học phần** | Lập trình trên thiết bị di động (ECMP177) |
| **Tên đề tài** | Ứng dụng Quản lý Tuần tra Bảo vệ – *Tactical Patrol Ops* |
| **Thành viên** | `[Họ tên – MSSV]`<br>`[Họ tên – MSSV]` |
| **Lớp / Nhóm** | `[Lớp] / [Nhóm]` |
| **Giảng viên phụ trách** | ThS. Bùi Phú Khuyên |
| **Học kỳ – Năm học** | `[Học kỳ] – [Năm học]` |

---

## 2. KẾT QUẢ THỰC NGHIỆM

### 2.1. Tổng hợp chức năng, công nghệ sử dụng & Link Git dự án

**Link Git dự án (public):** `[Dán link GitHub/GitLab ở chế độ công khai]`

#### a. Tổng quan công nghệ sử dụng

| Thành phần | Công nghệ / Thư viện | Mục đích sử dụng |
|---|---|---|
| Mobile App | Flutter 3.47 / Dart 3.13 | Xây dựng ứng dụng di động (chạy được Android, iOS, Web) |
| Kiến trúc | Clean Architecture (domain / data / presentation) | Tách lớp nghiệp vụ, dữ liệu và giao diện |
| State Management | flutter_riverpod 2.x (`StateNotifierProvider`, `StreamProvider`) | Quản lý trạng thái lịch tuần tra, sự cố, nhân sự, thiết bị, vị trí GPS |
| Định vị | geolocator | Lấy vị trí GPS thời gian thực, tính khoảng cách đến điểm tuần tra (Geofencing) |
| Quét mã QR | mobile_scanner | Dùng camera quét mã QR tại điểm kiểm tra, bật đèn flash, đổi camera |
| Phân quyền thiết bị | permission_handler | Xin quyền Camera trước khi quét QR / chụp ảnh |
| Xác thực sinh trắc học | local_auth | Đăng nhập bằng vân tay / khuôn mặt |
| Local Storage | shared_preferences | Lưu sự cố, lịch, lộ trình, nhân sự, thiết bị dạng JSON – dữ liệu còn nguyên khi mở lại app |
| Camera / Ảnh | image_picker | Chụp ảnh hoặc chọn ảnh hiện trường đính kèm báo cáo sự cố |
| Ghi âm / Phát âm thanh | record, audioplayers, path_provider | Ghi âm hiện trường và phát lại; phát còi báo cháy lặp liên tục |
| Mã QR | qr_flutter, share_plus | Sinh mã QR cho từng địa điểm tuần tra; xuất ảnh mã QR để gửi qua Zalo, Drive, email hoặc máy in |
| Bản đồ | flutter_map, latlong2 | Vẽ điểm tuần tra, lộ trình, đường đã đi và đường đã quét theo tọa độ GPS; không dùng bản đồ trực tuyến, không cần Internet hay API key |
| Giao diện | Material 3, bộ màu dùng chung (`AppTheme`), NavigationBar | Giao diện tối thống nhất; Chỉ huy dùng thanh điều hướng 4 tab gom chức năng theo nhóm |
| Radar | CustomPainter | Radar quét vị trí và tiến độ khi tuần tra |
| Cơ sở dữ liệu / Backend | *Chưa có máy chủ* – lưu cục bộ trên thiết bị (SharedPreferences) | Dữ liệu chỉ nằm trên một máy, chưa đồng bộ giữa nhiều thiết bị |
| Kiểm thử | flutter_test | 63 Unit / Widget test, `flutter analyze` không còn lỗi |

#### b. Tổng hợp các chức năng (theo phân quyền)

| STT | Phân quyền / Module | Chức năng | Trạng thái |
|:-:|---|---|---|
| 1 | Chung – Tài khoản | Đăng nhập bằng mã PIN, phân quyền Bảo vệ / Chỉ huy; mỗi bảo vệ có PIN riêng | Hoàn thành |
| 2 | Chung – Tài khoản | Báo lỗi khi nhập sai PIN, hiệu ứng chờ, rung phản hồi | Hoàn thành |
| 3 | Chung – Tài khoản | Đăng nhập sinh trắc học (vân tay / khuôn mặt) cho bảo vệ đã đăng nhập PIN trên máy | Hoàn thành (chỉ trên thiết bị thật có cảm biến) |
| 4 | Chung – Tài khoản | Đăng xuất | Hoàn thành |
| 5 | Chung – Tài khoản | Mật khẩu / tài khoản xác thực trên máy chủ | Chưa xây dựng – PIN lưu cục bộ, chưa mã hóa |
| 6 | Bảo vệ – Ca trực | Thẻ "Ca trực hôm nay" gom chấm công và tuần tra: vào ca, bắt đầu / tiếp tục tuần tra, kết thúc ca, tuyến, tiến độ, trạng thái | Hoàn thành |
| 7 | Bảo vệ – Ca trực | Xem chi tiết ca: bản đồ lộ trình, đường đã đi, danh sách điểm, thiết bị được cấp | Hoàn thành |
| 8 | Bảo vệ – Tuần tra | Theo dõi vị trí GPS & radar tiến độ | Hoàn thành (mặc định dùng GPS giả lập để demo) |
| 9 | Bảo vệ – Tuần tra | Geofencing: chỉ cho quét khi ở trong bán kính điểm (15 m) | Hoàn thành |
| 10 | Bảo vệ – Tuần tra | Quét mã QR bằng camera tại 3 điểm Nhà kho / Nhà xe / Hành lang, đối chiếu mã đúng / sai (không phân biệt hoa thường) | Hoàn thành (trên điện thoại); bản Web dùng màn hình quét giả lập |
| 11 | Bảo vệ – Tuần tra | Cập nhật tiến độ & trạng thái ca (Đang đi tuần → Hoàn thành), ghi lại vị trí mỗi lần quét | Hoàn thành |
| 12 | Bảo vệ – Tuần tra | Đồng bộ ngoại tuyến (Offline Sync) | Chưa hoàn thiện – mới mô phỏng trạng thái "Đang chờ mạng → Đã đồng bộ" |
| 13 | Bảo vệ – Sự cố | Báo cáo sự cố (tiêu đề, mô tả, 4 mức độ) bằng thao tác vuốt | Hoàn thành |
| 14 | Bảo vệ – Sự cố | Chụp / chọn ảnh hiện trường (bắt buộc với mức KHẨN CẤP), xem ảnh phóng to | Hoàn thành |
| 15 | Bảo vệ – Sự cố | Ghi âm hiện trường kèm báo cáo, nghe lại / xóa / ghi lại | Hoàn thành (trên điện thoại; bản Web ẩn chức năng) |
| 16 | Bảo vệ – Sự cố | Theo dõi sự cố của mình / được điều động chi viện, báo cáo xử lý | Hoàn thành |
| 17 | Bảo vệ – Báo cháy | Nút BÁO CHÁY: chọn vị trí, xác nhận, phát còi và cảnh báo nhấp nháy tới Chỉ huy và các bảo vệ | Hoàn thành |
| 18 | Bảo vệ – Chấm công | Vào ca / kết thúc ca theo lịch trực; vào ca tự tạo ca tuần tra và cấp thiết bị; tự tính đi trễ (quá 10 phút) và số giờ làm | Hoàn thành |
| 19 | Bảo vệ – Chấm công | Xem công cá nhân theo tháng (số ca, giờ, đi trễ, ngày phép, ca vắng) và lịch trực tuần của mình | Hoàn thành |
| 20 | Bảo vệ – Nghỉ phép | Gửi đơn xin nghỉ (từ ngày – đến ngày, lý do), theo dõi trạng thái Chờ duyệt / Đã duyệt / Từ chối | Hoàn thành |
| 21 | Chỉ huy – Tổng quan | Thanh điều hướng 4 tab (Trực ban / Lịch trực / Nhân sự / Thiết lập); trang Trực ban: số ca hôm nay, số người đang trực, sự cố mở, trạng thái từng ca trong ngày | Hoàn thành |
| 22 | Chỉ huy – Giám sát | Giám sát các ca đang đi tuần: bản đồ đường đã đi, tiến độ, lần quét cuối, điểm kế tiếp | Hoàn thành (dữ liệu trên cùng thiết bị, chưa theo dõi thời gian thực từ máy khác) |
| 23 | Chỉ huy – Sự cố | Danh sách & chi tiết sự cố (ảnh, ghi âm), điều động chi viện, đóng sự cố kèm ghi chú | Hoàn thành |
| 24 | Chỉ huy – Lộ trình | Vẽ lộ trình, chấm điểm, hoàn tác, đổi tên điểm; danh sách & xóa lộ trình | Hoàn thành |
| 25 | Chỉ huy – Lộ trình | Sinh mã QR cho từng điểm tuần tra để in và dán | Hoàn thành |
| 26 | Chỉ huy – Địa điểm | Thêm địa điểm tuần tra mới vào lộ trình: chọn trên bản đồ hoặc lấy vị trí GPS hiện tại, đặt tên, bán kính quét | Hoàn thành |
| 27 | Chỉ huy – Mã QR | Tạo mã QR mới cho địa điểm (tự sinh từ tên hoặc tự nhập, chặn trùng mã), xem mã lớn, chia sẻ / in ảnh mã, sửa và xóa địa điểm | Hoàn thành |
| 28 | Chỉ huy – Bản đồ | Quét bản đồ khu vực lần đầu bằng cách đi một vòng (giả lập bước đi hoặc GPS thật); đường đã quét làm bản đồ nền cho mọi màn hình bản đồ | Hoàn thành |
| 29 | Chỉ huy – Lịch trực | Gộp lịch tuần tra vào lịch trực: khi phân ca chọn luôn lộ trình và thiết bị; bảo vệ vào ca thì ca tuần tra được tạo tự động | Hoàn thành |
| 30 | Chỉ huy – Lịch trực | Trạng thái từng ca (Chưa vào ca / Đã vào ca / Đang tuần tra / Hoàn thành / Vắng), xem chi tiết ca, gỡ ca (thu hồi thiết bị, không gỡ ca đang tuần tra) | Hoàn thành |
| 31 | Chỉ huy – Lịch trực | Phân ca trực (Sáng / Chiều / Tối), lên lịch trực theo tuần, sao chép lịch tuần trước; chặn trùng ca và người đang nghỉ phép | Hoàn thành |
| 32 | Chỉ huy – Chấm công | Bảng công tổng theo tháng và chi tiết công từng nhân viên | Hoàn thành |
| 33 | Chỉ huy – Nghỉ phép | Duyệt / từ chối đơn nghỉ kèm ghi chú; tự gỡ ca trực trong những ngày được nghỉ | Hoàn thành |
| 34 | Chỉ huy – Nhân sự | Xem danh sách & hồ sơ chi tiết | Hoàn thành |
| 35 | Chỉ huy – Nhân sự | Thêm / sửa (ràng buộc SĐT, tuổi, mã NV và PIN không trùng) / vuốt để xóa | Hoàn thành |
| 36 | Chỉ huy – Nhân sự | Đánh dấu nhân viên đã nghỉ việc (không đăng nhập được), xóa hàng loạt nhân viên đã nghỉ cùng lịch trực | Hoàn thành |
| 37 | Chỉ huy – Thiết bị | Thêm / sửa / xóa thiết bị; tự chuyển Đang cấp khi bảo vệ vào ca và thu hồi khi hết ca | Hoàn thành |
| 38 | Hệ thống | Lưu dữ liệu cục bộ, còn nguyên khi tắt / mở lại app; khôi phục dữ liệu mẫu; tự nâng cấp dữ liệu khi cập nhật phiên bản | Hoàn thành |
| 39 | Hệ thống | CSDL / Backend đồng bộ nhiều thiết bị | Chưa xây dựng |
| 40 | Hệ thống | Thông báo đẩy cho Chỉ huy khi có sự cố | Chưa xây dựng – cần tài khoản dịch vụ (Firebase / OneSignal) |

---

### 2.2. Minh họa chi tiết các chức năng

> Ảnh bên dưới được chụp trên điện thoại thật Samsung SM-M307F (Android 11) chạy bản APK release; mã QR được quét thật bằng camera.

#### Chức năng 1: Đăng nhập bằng mã PIN

![Đăng nhập](screenshots/01_dang_nhap.jpg)

**Mô tả:** Người dùng nhập mã PIN 4 số trên bàn phím số. Mỗi lần chạm, ô vuông tương ứng được tô sáng và điện thoại rung nhẹ. Khi đủ 4 số, ứng dụng hiển thị vòng xoay chờ xác thực rồi điều hướng theo vai trò: mỗi bảo vệ có PIN riêng (dữ liệu mẫu: Nguyễn Văn A `1234`, Trần Thị B `2345`, Lê Văn C `3456`) và chỉ thấy ca trực, sự cố của chính mình; PIN `5678` vào Trung tâm Chỉ huy. Nhập sai, ứng dụng rung mạnh, xóa mã đã nhập và báo "TỪ CHỐI TRUY CẬP". Nút xóa (⌫) xóa từng chữ số. Nút vân tay đăng nhập lại tài khoản bảo vệ đã dùng PIN gần nhất trên máy; nếu chưa từng đăng nhập PIN, ứng dụng báo "HÃY ĐĂNG NHẬP BẰNG PIN LẦN ĐẦU", nếu thiết bị không có cảm biến thì báo "THIẾT BỊ KHÔNG HỖ TRỢ SINH TRẮC HỌC".

#### Chức năng 2: Dashboard Bảo vệ – Ca trực hiện tại

![Dashboard bảo vệ](screenshots/02_dashboard_bao_ve.jpg)

**Mô tả:** Sau khi đăng nhập, đầu trang là thẻ "CA TRỰC HÔM NAY" gom cả chấm công và tuần tra vào một chỗ: ca được phân trong lịch trực (VD: Ca Sáng • 06:00 – 14:00), trạng thái chấm công, tuyến tuần tra, thanh tiến độ quét điểm và nhãn trạng thái (Chưa bắt đầu / Đang đi tuần / Hoàn thành). Nút trên thẻ đổi theo từng bước: "VÀO CA" → "BẮT ĐẦU TUẦN TRA" / "TIẾP TỤC TUẦN TRA" → "KẾT THÚC CA" (xem Chức năng 15). Bên dưới là mục "LỊCH & CÔNG CỦA TÔI" (lịch trực tuần, nút xem công và xin nghỉ phép) và "SỰ CỐ CỦA TÔI" gồm các sự cố do chính bảo vệ báo cáo hoặc được Chỉ huy điều động chi viện. Nếu hôm nay không có ca, thẻ hiển thị "Hôm nay bạn không có ca trực". Thanh "VUỐT ĐỂ BÁO CÁO" phải kéo hết hành trình mới mở form báo sự cố, tránh bấm nhầm khi đang di chuyển.

#### Chức năng 3: Chi tiết ca trực

![Chi tiết ca trực](screenshots/03_chi_tiet_ca_truc.jpg)

**Mô tả:** Chạm vào thẻ ca trực để xem lộ trình trên bản đồ (đường đi dự kiến là nét đứt xanh đậm, điểm chưa quét màu cam, điểm đã quét màu xanh lá kèm vòng tròn bán kính 15 m), thời gian ca, thứ tự các điểm (Nhà Kho → Nhà Xe → Hành Lang), đường đã đi thực tế (nối các vị trí đã quét) và thiết bị được cấp phát. Nút "BẮT ĐẦU TUẦN TRA NGAY" chuyển trạng thái ca sang "Đang đi tuần" và mở màn hình tuần tra. Nếu ca đang dở, nút đổi thành "TIẾP TỤC TUẦN TRA"; ca đã hoàn thành thì nút bị khóa.

#### Chức năng 4: Tuần tra theo GPS & Geofencing

| Ở xa điểm tuần tra | Đã vào bán kính 15 m |
|:-:|:-:|
| ![Quá xa](screenshots/04_tuan_tra_qua_xa.jpg) | ![Trong bán kính](screenshots/05_tuan_tra_trong_ban_kinh.jpg) |

**Mô tả:** Màn hình hiển thị radar quét vị trí và phần trăm hoàn thành. Mỗi điểm tuần tra có tọa độ và khoảng cách từ bảo vệ đến điểm (tính bằng công thức Haversine). Khi khoảng cách lớn hơn bán kính cho phép (15 m), nút bị khóa với chữ "QUÁ XA ĐỂ QUÉT" (màu xám); bấm vào sẽ báo "BẠN ĐANG Ở QUÁ XA MỤC TIÊU! KHÔNG THỂ QUÉT". Khi bảo vệ đi vào trong bán kính, thẻ điểm chuyển viền xanh và nút đổi thành "MỞ CAMERA QUÉT QR". Cơ chế này ngăn việc check-in khống từ xa. Ở chế độ demo, vị trí được giả lập tự di chuyển dần đến điểm kế tiếp; chạy với `--dart-define=USE_REAL_GPS=true` để dùng GPS thật.

#### Chức năng 5: Quét mã QR tại điểm kiểm tra

| Màn hình quét | Sau khi quét điểm đầu tiên |
|:-:|:-:|
| ![Quét QR](screenshots/06_quet_qr.jpg) | ![Đã quét 1 điểm](screenshots/07_da_quet_1_diem.jpg) |

**Mô tả:** Trên điện thoại, ứng dụng xin quyền Camera rồi mở trình quét có khung ngắm và tia laser. Mã quét được đối chiếu với mã QR quy định của điểm: đúng thì rung, báo "XÁC NHẬN MỤC TIÊU THÀNH CÔNG" và quay lại; sai thì báo đỏ "Sai mã QR" kèm mã cần quét và tạm khóa 2 giây. Việc so khớp bỏ qua chữ hoa / thường và khoảng trắng thừa. Có nút bật đèn flash khi tuần tra ban đêm và nút đổi camera. Sau khi quét, điểm chuyển sang "ĐANG CHỜ MẠNG..." rồi "ĐÃ ĐỒNG BỘ MÁY CHỦ", tiến độ tăng lên 33%, vị trí quét được ghi vào đường đã đi của ca. (Bản chạy trên Web dùng màn hình quét giả lập vì không có camera.)

Dữ liệu mẫu có lộ trình "Tuyến tuần tra mẫu" gồm 3 điểm tuần tra cách nhau 40 – 80 m; mỗi điểm dán một mã QR với nội dung tương ứng: **Nhà kho** (`nhà kho`), **Nhà xe** (`nhà xe`), **Hành lang** (`hành lang`). Bộ mã in sẵn nằm trong thư mục `docs/qr/` (3 ảnh riêng và 1 trang A4 gồm cả 3 mã).

| Mã QR điểm Nhà kho | Mã QR điểm Nhà xe | Mã QR điểm Hành lang |
|:-:|:-:|:-:|
| ![Nhà kho](qr/01_nha_kho.png) | ![Nhà xe](qr/02_nha_xe.png) | ![Hành lang](qr/03_hanh_lang.png) |

#### Chức năng 6: Hoàn thành ca tuần tra

| Quét đủ 3 điểm | Ca trực chuyển Hoàn thành |
|:-:|:-:|
| ![Hoàn thành tuần tra](screenshots/08_hoan_thanh_tuan_tra.jpg) | ![Ca hoàn thành](screenshots/08b_ca_hoan_thanh.jpg) |

**Mô tả:** Khi quét đủ các điểm, radar báo "ĐÃ HOÀN TẤT 100%" và hiện dải thông báo "HOÀN THÀNH TUẦN TRA: 3/3 ĐIỂM". Trạng thái ca tự chuyển sang "HOÀN THÀNH", Chỉ huy nhìn thấy ngay trên Lịch trực và trang Trực ban.

#### Chức năng 7: Báo cáo sự cố

| Đang ghi âm hiện trường | Đã ghi âm, nghe lại / xóa |
|:-:|:-:|
| ![Đang ghi âm](screenshots/09a_dang_ghi_am.jpg) | ![Báo cáo sự cố](screenshots/09_bao_cao_su_co.jpg) |

**Mô tả:** Bảo vệ vuốt thanh "VUỐT ĐỂ BÁO CÁO" để mở form, nhập tiêu đề, mô tả và chọn một trong 4 mức độ: Thấp, Vừa, Cao, Khẩn cấp. Ứng dụng kiểm tra: thiếu tiêu đề hoặc mô tả thì báo "Vui lòng nhập Tiêu đề và Mô tả"; chọn mức KHẨN CẤP mà chưa có ảnh hiện trường thì báo lỗi bắt buộc đính kèm ảnh. Nút "CHỤP ẢNH" mở camera (xin quyền Camera nếu chưa có), nút "THƯ VIỆN" chọn ảnh có sẵn; ảnh được thu nhỏ, hiển thị xem trước và có thể bỏ hoặc chụp lại. Nút "GHI ÂM HIỆN TRƯỜNG" xin quyền Micro rồi ghi âm (hiển thị thời gian đang ghi); bấm lần nữa để dừng, sau đó có thể nghe lại, xóa hoặc ghi lại. File ghi âm lưu trong bộ nhớ ứng dụng và phát lại được trong chi tiết sự cố. Bấm "TRUYỀN TIN CẢNH BÁO", sự cố mang tên bảo vệ đang đăng nhập được gửi về Trung tâm Chỉ huy, xuất hiện trong bảng theo dõi của bảo vệ và làm tăng số "Sự cố mở" trên trang Trực ban của Chỉ huy.

#### Chức năng 8: Trung tâm Chỉ huy – 4 tab chức năng

| Tab Trực ban | Tab Nhân sự | Tab Thiết lập |
|:-:|:-:|:-:|
| ![Trực ban](screenshots/10_dashboard_chi_huy.jpg) | ![Nhân sự](screenshots/10b_dashboard_chi_huy.jpg) | ![Thiết lập](screenshots/10c_thiet_lap.jpg) |

**Mô tả:** Chỉ huy đăng nhập bằng PIN `5678`. Các chức năng được gom theo nhóm vào thanh điều hướng 4 tab ở đáy màn hình; biểu tượng tab hiện số đếm khi có sự cố mở hoặc đơn nghỉ phép chờ duyệt.
- **Trực ban:** 3 chỉ số tính trực tiếp từ dữ liệu (số ca hôm nay, số người đang trực, số sự cố mở); mục "ĐIỀU HÀNH" dẫn tới Sự cố (kèm số sự cố cần xử lý) và Giám sát tuần tra (tên các bảo vệ đang đi tuần); mục "CA TRỰC HÔM NAY" liệt kê ca Sáng / Chiều / Tối với người trực và trạng thái (Chưa vào ca, Đang tuần tra...). Khi khu vực chưa có bản đồ, đầu trang hiện thẻ "QUÉT BẢN ĐỒ LẦN ĐẦU".
- **Lịch trực:** lịch trực tuần kèm phân ca, lộ trình và thiết bị (Chức năng 11, 17).
- **Nhân sự:** Nhân viên (số người đang làm / đã nghỉ), Chấm công (số ca và giờ công trong tháng), Nghỉ phép (số đơn chờ duyệt).
- **Thiết lập:** Bản đồ khu vực, Lộ trình & mã QR, Địa điểm & mã QR, Thiết bị, Khôi phục dữ liệu mẫu (có hộp thoại xác nhận) và Đăng xuất.

#### Chức năng 9: Quản lý & xử lý sự cố

| Danh sách sự cố | Chi tiết sự cố |
|:-:|:-:|
| ![Danh sách sự cố](screenshots/17_danh_sach_su_co.jpg) | ![Chi tiết sự cố](screenshots/18_chi_tiet_su_co.jpg) |

**Mô tả:** Danh sách hiển thị các sự cố với viền đỏ (chưa xử lý) hoặc xanh (đã đóng); khi không có sự cố, màn hình báo "Tuyệt vời! Không có sự cố nào.". Mở chi tiết, Chỉ huy xem tiêu đề, mô tả, thời gian, người báo cáo, ảnh hiện trường (chạm để phóng to) và nút nghe bản ghi âm nếu có. Nút "CHI VIỆN" mở danh sách bảo vệ đang đi tuần để chọn và điều động; bảo vệ được chọn sẽ thấy sự cố trong mục "Yêu cầu tôi chi viện". Chỉ huy nhập "Ghi chú chỉ đạo" và bấm "ĐÓNG SỰ CỐ": sự cố chuyển màu xanh, ghi "ĐÃ ĐÓNG BỞI: CHỈ HUY" và số sự cố khẩn trên dashboard giảm đi.

#### Chức năng 10: Lộ trình, vẽ lộ trình & mã QR điểm tuần tra

| Danh sách lộ trình | Mã QR các điểm | Vẽ lộ trình |
|:-:|:-:|:-:|
| ![Danh sách lộ trình](screenshots/20_lo_trinh.jpg) | ![Mã QR các điểm](screenshots/21_ma_qr_lo_trinh.jpg) | ![Vẽ lộ trình](screenshots/22_ve_lo_trinh.jpg) |

**Mô tả:** Chỉ huy nhập tên lộ trình, chọn chế độ "VẼ ĐƯỜNG ĐI" rồi chạm lên bản đồ để tạo các đỉnh của đường đi; chuyển sang "CHẤM ĐIỂM" để đặt các điểm tuần tra (mỗi điểm tự sinh tên và mã QR, bán kính 15 m). Lộ trình được vẽ trực tiếp trên bản đồ theo tọa độ GPS, nền là các đường đã quét của khu vực: kéo để di chuyển, chụm hai ngón để phóng to, mỗi lần chạm lấy đúng tọa độ GPS của vị trí đó; vòng tròn quanh mỗi điểm thể hiện bán kính 15 m thật theo tỷ lệ bản đồ. Nút "HOÀN TÁC" bỏ nét / điểm vừa thêm, chạm vào tên điểm để đổi tên (VD: "Cổng sau"). Nếu thiếu tên, đường đi dưới 2 nét hoặc chưa có điểm nào, ứng dụng báo lỗi; lưu thành công thì lộ trình xuất hiện trong danh sách và khi phân ca. Mở một lộ trình để xem bản đồ và mã QR của từng điểm (kèm tên, mã, tọa độ, bán kính) – đây chính là mã bảo vệ phải quét khi đi tuần; chạm vào một mã để phóng to và in, nút "THÊM ĐỊA ĐIỂM" thêm điểm mới vào lộ trình (Chức năng 21). Vuốt để xóa lộ trình; lộ trình đang được dùng trong ca tuần tra chưa hoàn thành sẽ không cho xóa.

#### Chức năng 11: Phân ca kèm lộ trình & thiết bị

| Phân ca: chọn lộ trình, thiết bị, bảo vệ | Chi tiết một ca trực |
|:-:|:-:|
| ![Phân ca](screenshots/11_phan_ca.jpg) | ![Chi tiết ca](screenshots/12_chi_tiet_ca.jpg) |

**Mô tả:** Lịch tuần tra được gộp vào lịch trực nên Chỉ huy chỉ phải lên lịch một lần. Trong tab Lịch trực, bấm "+" ở một ca để mở bảng phân ca: chọn lộ trình tuần tra (mặc định lộ trình đầu tiên), chọn thiết bị sẽ cấp khi vào ca (Bộ đàm, Đèn pin...), rồi chạm vào tên bảo vệ. Khi bảo vệ bấm "VÀO CA", ứng dụng tự tạo ca tuần tra đúng giờ ca theo lộ trình đã chọn, chuyển thiết bị sang "ĐANG CẤP" và thu hồi về kho khi hoàn thành tuần tra hoặc kết thúc ca. Chạm vào tên một người trong lịch để xem chi tiết ca: trạng thái, lộ trình, tiến độ quét điểm và thiết bị; ca đang tuần tra có nút "GIÁM SÁT", ca chưa diễn ra có nút "GỠ KHỎI CA" (gỡ luôn ca tuần tra và thu hồi thiết bị). Ca đang tuần tra thì không gỡ được.

#### Chức năng 12: Quản lý nhân sự

| Danh sách | Thêm nhân sự | Hồ sơ chi tiết |
|:-:|:-:|:-:|
| ![Nhân sự](screenshots/13_nhan_su.jpg) | ![Thêm nhân sự](screenshots/14_them_nhan_su.jpg) | ![Hồ sơ](screenshots/15_ho_so_nhan_su.jpg) |

**Mô tả:** Danh sách hiển thị họ tên, vai trò, mã nhân viên và số điện thoại. Nút "+" mở form thêm mới; biểu tượng bút chì mở form sửa. Ràng buộc dữ liệu: bắt buộc họ tên và mã NV, mã NV không được trùng, số điện thoại gồm 10 chữ số bắt đầu bằng 0, tuổi từ 18 đến 65, mã PIN đăng nhập gồm 4 chữ số và không trùng với bảo vệ khác hay PIN Chỉ huy; dữ liệu sai sẽ báo lỗi màu đỏ và không lưu. Vuốt một dòng sang trái, xác nhận "XÓA" để xóa nhân sự. Chạm vào dòng để xem hồ sơ chi tiết (tài khoản, SĐT, giới tính, tuổi, ghi chú kinh nghiệm).

#### Chức năng 13: Quản lý thiết bị

![Quản lý thiết bị](screenshots/19_thiet_bi.jpg)

**Mô tả:** Danh sách thiết bị (Bộ đàm, Đèn pin...) kèm mã và nhãn trạng thái màu xanh "SẴN SÀNG" hoặc màu cam "ĐANG CẤP". Chỉ huy có thể thêm, sửa tên / mã / trạng thái và vuốt để xóa thiết bị. Trạng thái thiết bị liên kết với lịch trực: thiết bị được chọn khi phân ca chuyển sang "ĐANG CẤP" khi bảo vệ vào ca và tự thu hồi khi hoàn thành tuần tra hoặc kết thúc ca.

#### Chức năng 14: Giám sát tuần tra

![Giám sát tuần tra](screenshots/16_giam_sat.jpg)

**Mô tả:** Từ mục "Giám sát tuần tra" trên tab Trực ban (hoặc nút "GIÁM SÁT" trong chi tiết ca đang tuần tra), Chỉ huy xem bản đồ của ca đang đi tuần: đường dự kiến, các điểm tuần tra (điểm đã quét đổi màu) và đường đã đi thực tế nối các vị trí quét. Bản đồ có thể kéo và phóng to. Bên dưới là danh sách các ca đang đi tuần với tên bảo vệ, giờ ca, thanh tiến độ, số điểm đã quét, giờ quét gần nhất và điểm kế tiếp; chạm vào ca nào thì bản đồ hiển thị ca đó. Khi không có ca nào đang diễn ra, màn hình báo "Hiện không có ca tuần tra nào đang diễn ra.". Vì chưa có Backend, màn hình hiển thị dữ liệu trên cùng thiết bị.

#### Chức năng 15: Chấm công của bảo vệ

| Sau khi vào ca | Công cá nhân theo tháng |
|:-:|:-:|
| ![Chấm công](screenshots/23_cham_cong_bao_ve.jpg) | ![Công cá nhân](screenshots/24_cong_ca_nhan.jpg) |

**Mô tả:** Chấm công nằm ngay trong thẻ "CA TRỰC HÔM NAY", lấy ca trực trong ngày từ lịch trực tuần. Nút "VÀO CA" chỉ bấm được từ 30 phút trước giờ bắt đầu đến khi hết ca; vào trễ quá 10 phút sẽ ghi nhận số phút trễ (VD: "Đang trong ca từ 12:31 (trễ 391 phút)"). Vào ca xong, thẻ hiện ngay nút "BẮT ĐẦU TUẦN TRA" để mở lộ trình và nút "KẾT THÚC CA" để chấm công ra; ứng dụng tính số giờ làm. Bên dưới là mục "LỊCH & CÔNG CỦA TÔI": dải lịch trực tuần này (S: sáng, C: chiều, T: tối, P: nghỉ phép) và hai nút "CÔNG CỦA TÔI", "XIN NGHỈ PHÉP". Màn hình công cá nhân cho chọn tháng, hiển thị số ca đã làm, tổng giờ, số lần và số phút đi trễ, ngày nghỉ phép, ca vắng (có lịch nhưng không chấm công) và danh sách từng lần chấm công.

#### Chức năng 16: Xin nghỉ phép & duyệt nghỉ phép

| Bảo vệ gửi đơn | Chỉ huy duyệt đơn |
|:-:|:-:|
| ![Xin nghỉ phép](screenshots/25_xin_nghi_phep.jpg) | ![Duyệt nghỉ phép](screenshots/28_duyet_nghi_phep.jpg) |

**Mô tả:** Bảo vệ chọn ngày bắt đầu, ngày kết thúc (bằng lịch chọn ngày), nhập lý do và bấm "GỬI ĐƠN". Ứng dụng kiểm tra: phải có lý do, không xin cho ngày đã qua, ngày kết thúc không trước ngày bắt đầu và không trùng với đơn khác. Đơn hiện ở mục "ĐƠN CỦA TÔI" với nhãn Chờ duyệt / Đã duyệt / Từ chối. Phía Chỉ huy, biểu tượng tab Nhân sự hiện số đơn đang chờ và mục Nghỉ phép ghi "n đơn đang chờ duyệt". Chỉ huy bấm "DUYỆT" hoặc "TỪ CHỐI" và có thể ghi chú; khi duyệt, các ca trực của nhân viên trong những ngày nghỉ được tự động gỡ khỏi lịch, và từ đó không thể phân ca cho người này vào ngày nghỉ.

#### Chức năng 17: Phân ca trực & lịch trực tuần

![Lịch trực tuần](screenshots/26_lich_truc_tuan.jpg)

**Mô tả:** Màn hình "LỊCH TRỰC TUẦN" hiển thị 7 ngày của tuần, mỗi ngày có 3 ca: Sáng (06:00 – 14:00), Chiều (14:00 – 22:00), Tối (22:00 – 06:00). Nút mũi tên chuyển tuần trước / tuần sau, ngày hôm nay được viền xanh kèm nhãn "HÔM NAY" và dòng "Nghỉ phép: …" cho biết ai đang nghỉ. Chấm màu trước mỗi tên cho biết trạng thái ca (xám: chưa vào ca, cam: đã vào ca, xanh lá: đang tuần tra, xanh dương: hoàn thành, đỏ: vắng), có chú thích ở đầu trang. Bấm "+" ở một ca để phân ca kèm lộ trình và thiết bị (Chức năng 11); danh sách bảo vệ chỉ gồm người đang làm việc, chưa có ca trong ngày đó và không nghỉ phép. Chạm vào tên để xem chi tiết ca, bấm "x" để gỡ khỏi ca. Nút sao chép trên thanh tiêu đề chép toàn bộ lịch của tuần trước sang tuần đang xem (bỏ qua các ca bị trùng hoặc người đang nghỉ).

#### Chức năng 18: Bảng chấm công tổng & nhân viên đã nghỉ việc

| Bảng chấm công tổng | Nhân viên đã nghỉ việc |
|:-:|:-:|
| ![Bảng chấm công](screenshots/27_bang_cham_cong.jpg) | ![Nhân viên đã nghỉ](screenshots/29_nhan_vien_da_nghi.jpg) |

**Mô tả:** Chỉ huy chọn tháng để xem tổng số ca, tổng giờ công và số lượt đi trễ của toàn đội, kèm từng nhân viên (số ca, giờ, đi trễ, ngày phép, ca vắng); chạm vào một người để mở màn hình công cá nhân. Trong form sửa nhân sự có công tắc "Đang làm việc": tắt đi thì nhân viên được đánh dấu "ĐÃ NGHỈ", không đăng nhập được nữa và các ca trực từ hôm nay trở đi bị gỡ. Nút "XÓA ĐÃ NGHỈ (n)" trên thanh tiêu đề xóa hẳn hồ sơ những nhân viên đã nghỉ cùng lịch trực của họ (có hộp thoại xác nhận).

#### Chức năng 19: Quét bản đồ khu vực lần đầu

| Đang quét (giả lập bước đi) | Bản đồ nền đã lưu |
|:-:|:-:|
| ![Đang quét bản đồ](screenshots/30_quet_ban_do.jpg) | ![Bản đồ đã lưu](screenshots/30b_quet_ban_do.jpg) |

**Mô tả:** Khi khu vực chưa có bản đồ, tab Trực ban hiện thẻ "QUÉT BẢN ĐỒ LẦN ĐẦU" (sau này mở lại từ tab Thiết lập → Bản đồ khu vực). Các điểm tuần tra của mọi lộ trình hiện sẵn trên bản đồ để người quét đi đúng các lối đi qua từng điểm. Chỉ huy bấm "BẮT ĐẦU QUÉT" rồi đi một vòng các lối đi nội bộ: ở chế độ giả lập, chạm vào một vị trí trên bản đồ để người quét đi bộ tới điểm đó và ứng dụng ghi lại đường đi; khi chạy bản GPS thật (`USE_REAL_GPS=true`) đường đi lấy từ vị trí thực. Màn hình hiển thị số điểm đã ghi và số mét đã đi. Bấm "DỪNG & LƯU ĐƯỜNG ĐI" để lưu thành một đoạn đường; có thể quét thêm nhiều đoạn hoặc xóa để quét lại. Các đoạn đường đã quét được vẽ làm nền (lối đi nội bộ) ở mọi bản đồ: chi tiết ca, vẽ lộ trình, mã QR lộ trình và giám sát tuần tra.

#### Chức năng 20: Báo cháy

| Bảo vệ chọn vị trí cháy | Cảnh báo trên dashboard bảo vệ | Cảnh báo trên dashboard Chỉ huy |
|:-:|:-:|:-:|
| ![Báo cháy](screenshots/31_bao_chay_bao_ve.jpg) | ![Cảnh báo bảo vệ](screenshots/31b_bao_chay_bao_ve.jpg) | ![Cảnh báo cháy](screenshots/32_bao_chay_chi_huy.jpg) |

**Mô tả:** Trên dashboard bảo vệ có nút "BÁO CHÁY" màu cam đỏ. Bấm vào để chọn vị trí cháy (các điểm tuần tra hoặc "Khu vực khác"), xác nhận lần nữa để tránh bấm nhầm. Ứng dụng tạo sự cố mức KHẨN CẤP "BÁO CHÁY: <vị trí>", rung máy và phát còi báo động lặp liên tục. Trên trang Trực ban của Chỉ huy và trang chủ của bảo vệ hiện dải cảnh báo nhấp nháy đỏ – cam với vị trí, người báo và giờ báo; nút "TẮT CÒI" tắt âm thanh, nút "XỬ LÝ" mở chi tiết sự cố để điều động chi viện và đóng sự cố. Khi sự cố được đóng, cảnh báo tự biến mất.

#### Chức năng 21: Thêm địa điểm tuần tra & tạo mã QR mới

| Danh sách địa điểm & mã QR | Thêm địa điểm mới | Mã QR để in / chia sẻ |
|:-:|:-:|:-:|
| ![Địa điểm & mã QR](screenshots/33_dia_diem_qr.jpg) | ![Thêm địa điểm](screenshots/34_them_dia_diem.jpg) | ![Mã QR địa điểm](screenshots/35_ma_qr_dia_diem.jpg) |

**Mô tả:** Từ tab Thiết lập → "Địa điểm & mã QR", Chỉ huy xem toàn bộ địa điểm tuần tra theo từng lộ trình, mỗi dòng có mã QR thu nhỏ, nội dung mã và bán kính quét. Bấm "THÊM ĐỊA ĐIỂM" (hoặc "Thêm" ở một lộ trình, hoặc nút cùng tên trong chi tiết lộ trình) để mở màn hình thêm địa điểm: chạm vào bản đồ để đặt vị trí (các điểm sẵn có hiện màu xanh để tham chiếu) hoặc bấm "VỊ TRÍ GPS" để lấy đúng vị trí đang đứng; nhập tên địa điểm, nội dung mã QR tự sinh theo tên (VD: "Kho B" → `kho b`) và có thể sửa lại; kéo thanh trượt để chọn bán kính quét 5 – 50 m. Mã QR xem trước thay đổi ngay khi gõ. Khi lưu, ứng dụng kiểm tra: phải có vị trí, tên và nội dung mã; không trùng mã QR với bất kỳ địa điểm nào (không phân biệt hoa thường, khoảng trắng) và không trùng tên trong cùng lộ trình. Địa điểm mới được thêm vào lộ trình, các ca tuần tra chưa bắt đầu của lộ trình cũng nhận thêm điểm này; ca đang tuần tra giữ nguyên. Chạm vào một địa điểm để mở mã QR khổ lớn (tên lộ trình, số thứ tự điểm, tên và nội dung mã), bấm "CHIA SẺ / IN MÃ QR" để xuất ảnh mã QR gửi qua Zalo, Drive, email hoặc máy in rồi dán đúng tại địa điểm. Nút bút chì sửa địa điểm, nút thùng rác xóa địa điểm (có xác nhận, lộ trình phải còn ít nhất 1 điểm).

---

## 3. KẾT LUẬN

**Kết quả đạt được**
- Hoàn thành ứng dụng Flutter cho 2 vai trò Bảo vệ và Chỉ huy với luồng nghiệp vụ khép kín: Chỉ huy quét bản đồ và vẽ lộ trình → phân ca trực kèm lộ trình và thiết bị → Bảo vệ vào ca (tự tạo ca tuần tra), đi tuần theo GPS, quét QR từng điểm → tiến độ và trạng thái ca cập nhật lại cho Chỉ huy.
- Có cơ chế chống gian lận check-in bằng Geofencing (Haversine) kết hợp quét mã QR đúng điểm.
- Luồng báo cáo, điều động chi viện và đóng sự cố hoạt động giữa hai vai trò.
- Quản lý nhân sự và thiết bị đầy đủ thêm / sửa / xóa, có ràng buộc dữ liệu; mỗi bảo vệ đăng nhập bằng PIN riêng.
- Báo cáo sự cố kèm ảnh và ghi âm hiện trường; sinh mã QR cho từng điểm tuần tra, có bộ mã in sẵn cho 3 điểm Nhà kho / Nhà xe / Hành lang.
- Chỉ huy giám sát tiến độ và đường đã đi của các ca đang tuần tra.
- Quản lý ca trực theo tuần, chấm công vào / ra ca có tính đi trễ, bảng công tổng và công cá nhân, xin nghỉ phép và duyệt nghỉ phép; quản lý nhân viên đã nghỉ việc.
- Thêm địa điểm tuần tra mới ngay trên bản đồ hoặc theo GPS, tự tạo mã QR không trùng và xuất ảnh mã QR để in.
- Báo cháy có còi và cảnh báo nhấp nháy; quét bản đồ khu vực lần đầu để làm bản đồ nền.
- Giao diện thống nhất một bộ màu; Chỉ huy dùng thanh điều hướng 4 tab (Trực ban, Lịch trực, Nhân sự, Thiết lập), bảo vệ có một thẻ ca trực gom chấm công và tuần tra.
- Dữ liệu được lưu cục bộ, còn nguyên khi tắt / mở lại ứng dụng.
- Mã nguồn tổ chức theo Clean Architecture, quản lý trạng thái bằng Riverpod; `flutter analyze` không còn lỗi, 63/63 test tự động đạt; đã build APK và chạy trên điện thoại Samsung (Android 11).

**Hạn chế**
- Chưa có Backend: dữ liệu chỉ lưu trên từng thiết bị nên Bảo vệ và Chỉ huy phải dùng chung một máy để thấy dữ liệu của nhau.
- Mã PIN lưu cục bộ, chưa mã hóa và chưa có xác thực trên máy chủ.
- Đồng bộ ngoại tuyến mới ở mức mô phỏng trạng thái.
- Bản đồ chỉ vẽ các đường đã quét, chưa có nền đường phố, tòa nhà.
- Chưa có thông báo đẩy khi có sự cố mới.

**Hướng phát triển**
- Xây dựng Backend (Spring Boot hoặc Firebase / Supabase) để lưu trữ và đồng bộ dữ liệu giữa nhiều thiết bị; dùng Hive / SQLite làm hàng đợi ngoại tuyến thật.
- Xác thực theo tài khoản (Firebase Authentication) kết hợp sinh trắc học.
- Tải ảnh / ghi âm hiện trường lên máy chủ lưu trữ.
- Lưu bản đồ ngoại tuyến cho khu vực tuần tra; theo dõi vị trí bảo vệ thời gian thực cho Chỉ huy.
- Thông báo đẩy (FCM / OneSignal) khi có sự cố khẩn hoặc được điều động chi viện; xuất báo cáo ca trực ra PDF.

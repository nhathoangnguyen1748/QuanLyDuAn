# BẢNG PHÂN CÔNG NHIỆM VỤ DỰ ÁN SMARTSTOCK ADMIN
**Hệ thống Quản lý Kho hàng Tổng hợp & Phân tích Dữ liệu Thông minh**

---

## 1. TỔNG QUAN PHÂN CHIA NHÂN SỰ & NHÁNH PHÁT TRIỂN (GIT FLOW)

| Thành Viên | Vai Trò Chính | Nhánh Git Phụ Trách | Trọng Tâm Nghiệp Vụ |
| :--- | :--- | :--- | :--- |
| **Hoàng Nhật** | Team Lead & Software Architect | `HoangNhat` | Kiến trúc lõi, Riverpod State, CSDL Hive, Dashboard Analytics & Biểu đồ `fl_chart` |
| **Trọng Lương (Trung Lương)** | Operations & Hardware Integration Specialist | `TrungLuong` | Quản lý Nhập kho (MAC), Xuất kho, Điều chuyển chi nhánh, Quét mã vạch Camera `mobile_scanner` |
| **Quang Minh** | QA Engineer, Audit & Reporting Specialist | `QuangMinh` | Kiểm kê định kỳ (Cycle Count), Cảnh báo tồn kho an toàn & FEFO, Xuất file Excel & In ấn PDF, Unit Tests |

---

## 2. QUY TRÌNH PHỐI HỢP NHÁNH (GIT BRANCHING STRATEGY)

```mermaid
gitGraph
   commit id: "Init Project"
   branch production
   branch test
   branch HoangNhat
   branch TrungLuong
   branch QuangMinh

   checkout HoangNhat
   commit id: "feat: Analytics & Dashboard"
   checkout test
   merge HoangNhat

   checkout TrungLuong
   commit id: "feat: Stock In/Out & Scanner"
   checkout test
   merge TrungLuong

   checkout QuangMinh
   commit id: "feat: Cycle Count & Reports"
   checkout test
   merge QuangMinh

   checkout main
   merge test id: "Release Staging"

   checkout production
   merge main id: "v1.0.0 Production"
```

### Quy định Git Workflow:
1. **Nhánh cá nhân (`HoangNhat`, `TrungLuong`, `QuangMinh`):**
   - Mỗi thành viên code trên nhánh mang tên mình.
   - Không được push trực tiếp lên `main` hoặc `production`.
2. **Nhánh Kiểm thử (`test`):**
   - Khi hoàn thành tính năng, tạo Pull Request (PR) hoặc merge vào nhánh `test`.
   - Chạy toàn bộ bộ kiểm thử tự động: `flutter analyze` và `flutter test`.
3. **Nhánh `main` (Staging):**
   - Nơi tích hợp code đã vượt qua kiểm thử trên nhánh `test` (100% PASS, 0 warning).
4. **Nhánh `production` (Release):**
   - Nhánh ổn định cao nhất, dùng để build release APK/AAB cho khách hàng hoặc trường chấm điểm đồ án.

---

## 3. PHÂN CÔNG CHI TIẾT THEO TỪNG THÀNH VIÊN

### 👤 Thành viên 1: HOÀNG NHẬT (Lead Architect & Core Systems)
- **Nhánh Git:** `HoangNhat`
- **Trách nhiệm chính:**
  1. Thiết kế cấu trúc thư mục Feature-First Clean Architecture.
  2. Thiết lập State Management với Riverpod 3.x (`Notifier`, `NotifierProvider`).
  3. Cấu hình CSDL nhúng NoSQL `hive_flutter` phục vụ Offline-first khi kho mất sóng 4G/WiFi.
  4. Xây dựng bộ Seed Data thực tế (15+ SKU, danh mục, lịch sử nhập xuất mẫu).
  5. Xây dựng Trung tâm Phân tích Dashboard (`fl_chart`):
     - Thẻ KPI điều hành: Tổng giá trị tồn, Tỷ lệ lấp đầy kho %, Số SKU thiếu tồn, Dead stock.
     - Biểu đồ Pareto ABC 80/20 (Bar Chart cột doanh thu + Line tích lũy).
     - Biểu đồ Vòng quay tồn kho ITR Line Chart qua 6 tháng ($ITR = COGS / \text{Tồn bình quân}$).
     - Biểu đồ Chi phí Tồn trữ Holding Cost (Stacked Bar: Lưu kho, Hao hụt, Doanh thu).
     - Biểu đồ Donut Chart cơ cấu ngành hàng cảm ứng chạm.
- **Danh sách File phụ trách:**
  - `lib/core/models/analytics_models.dart`
  - `lib/core/models/product_sku.dart`
  - `lib/core/storage/hive_storage_service.dart`
  - `lib/core/storage/seed_data.dart`
  - `lib/core/providers/warehouse_providers.dart`
  - `lib/features/dashboard_analytics/**`
  - `lib/features/home/**`

---

### 👤 Thành viên 2: TRUNG LƯƠNG (Operations & Hardware Specialist)
- **Nhánh Git:** `TrungLuong`
- **Trách nhiệm chính:**
  1. Xây dựng Phân hệ Nhập kho (Stock In):
     - Tạo phiếu nhập từ Nhà cung cấp (NCC).
     - Phân bổ vị trí kệ hàng cụ thể (`locationTag`: Aisle/Rack/Bin, VD: `KHO-A-KAY-03`).
     - Thuật toán tự động tính Giá vốn bình quân gia quyền (Moving Average Cost - MAC):
       $$\text{MAC}_{\text{new}} = \frac{(\text{Current Stock} \times \text{Current Cost}) + (\text{New Qty} \times \text{New Unit Cost})}{\text{Current Stock} + \text{New Qty}}$$
     - Preview biến động giá vốn theo thời gian thực trên giao diện.
  2. Xây dựng Phân hệ Xuất kho & Điều chuyển (Stock Out):
     - 3 hình thức xuất: Bán lẻ (Retail), Bán sỉ (Wholesale), Điều chuyển chi nhánh nội bộ (Transfer).
     - Chặn xuất âm kho (kiểm tra tồn khả dụng tức thì), tính COGS và lợi nhuận gộp.
  3. Tích hợp Quét mã vạch phần cứng (`mobile_scanner`):
     - Quản lý camera quét tốc độ cao, điều khiển bật/tắt đèn Flash, chuyển đổi camera trước/sau.
     - Cung cấp phương thức nhập mã vạch thủ công và các chip barcode demo khi test không có camera.
- **Danh sách File phụ trách:**
  - `lib/core/models/stock_in_order.dart`
  - `lib/core/models/stock_out_order.dart`
  - `lib/features/operations_stock_in/**`
  - `lib/features/operations_stock_out/**`
  - `lib/features/scanner/**`

---

### 👤 Thành viên 3: QUANG MINH (QA, Audit & Reporting Specialist)
- **Nhánh Git:** `QuangMinh`
- **Trách nhiệm chính:**
  1. Xây dựng Phân hệ Kiểm kê định kỳ (Cycle Counting):
     - Tạo đợt kiểm kê theo toàn kho hoặc phân khu kệ.
     - Quét barcode đối soát thực tế với sổ sách, tính chênh lệch thừa/thiếu.
     - Nút "Phê duyệt & Điều chỉnh tồn kho": Tự động cân bằng số tồn kho hệ thống về số thực tế.
  2. Trung tâm Cảnh báo Tồn kho & Quản lý Hạn dùng (FEFO):
     - Lọc danh sách SKU dưới định mức an toàn (`currentStock <= minSafetyStock`).
     - Phát hiện và cảnh báo hàng chậm luân chuyển (**Dead Stock**: > 60 ngày không xuất hàng).
     - Quản lý Hạn dùng FEFO (First Expired First Out): Cảnh báo cận date < 30 ngày và quá hạn.
  3. Hệ thống Báo cáo & In ấn:
     - `PdfReportService`: Phiếu Nhập kho, Phiếu Xuất kho, Biên bản Kiểm kê, Tem nhãn Barcode nhiệt 80x50mm.
     - `ExcelExportService`: Xuất toàn bộ Danh mục Tồn kho và Bảng kê Đối soát sang `.xlsx`.
  4. Đảm bảo chất lượng (QA & Testing):
     - Viết và duy trì bộ Unit Tests: `test/mac_calculation_test.dart`, `test/analytics_calculation_test.dart`, `test/widget_test.dart`.
     - Phụ trách kiểm duyệt chất lượng code trước khi merge vào nhánh `test` và `production`.
- **Danh sách File phụ trách:**
  - `lib/core/models/cycle_count_session.dart`
  - `lib/core/services/pdf_report_service.dart`
  - `lib/core/services/excel_export_service.dart`
  - `lib/features/cycle_counting/**`
  - `lib/features/inventory_catalog/presentation/screens/safety_stock_alerts_screen.dart`
  - `lib/features/reports_export/**`
  - `test/**`

---

## 4. CHECKLIST TIÊU CHÍ HOÀN THÀNH (DEFINITION OF DONE - DoD)
- [x] Kiến trúc dự án chuẩn Feature-First Clean Architecture.
- [x] Không còn warning hoặc error khi chạy `flutter analyze`.
- [x] 100% Unit Tests vượt qua (`flutter test` PASS).
- [x] Build thành công trên nền tảng Web/Mobile không phát sinh lỗi liên kết thư viện.
- [x] Code được commit theo định dạng chuẩn Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`).
- [x] Đã push đầy đủ lên nhánh cá nhân và merge đồng bộ vào `test`, `main`, `production`.

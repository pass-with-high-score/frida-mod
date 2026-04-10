Để sử dụng Dobby hook vào một ứng dụng hoặc game trên iOS, bạn cần hiểu cơ chế **Inline Hooking**. Bản chất của việc này là tráo đổi mã lệnh tại một địa chỉ bộ nhớ cụ thể để điều hướng luồng thực thi sang hàm (function) tự viết của bạn.

Dưới đây là hướng dẫn cách dùng Dobby phổ biến nhất: can thiệp vào một game iOS bằng offset tìm được từ IDA Pro, viết bằng C/C++ (thường được dùng trong môi trường Theos để build file Tweak `.dylib`).

### Bước 1: Chuẩn bị thư viện (Đã được tự động hóa)
* **Nếu bạn đã cài Dobby qua Installer App**: Bạn **KHÔNG CẦN** phải copy thủ công bất kỳ file nào nữa! Installer đã tự động chép `dobby.h` vào hệ thống (`/var/jb/opt/theos/include`) và `libdobby.a` vào (`/var/jb/opt/theos/lib`).
* **Bạn chỉ việc**: Mở file `Makefile` trong project Theos của bạn và khai báo liên kết Dobby bằng cách thêm dòng sau:
  ```makefile
  TWEAK_NAME_LDFLAGS += -ldobby
  ```
*(Ghi chú: Nếu bạn không dùng Installer App, bạn sẽ phải tự chép `dobby.h` vào thư mục `include` và `libdobby.a` vào thư mục `lib` của project/Theos).*

### Bước 2: Hiểu cấu trúc của DobbyHook
Hàm cốt lõi bạn sẽ dùng là:
```cpp
DobbyHook(void *address, void *replace_call, void **original_call);
```
* **`address`**: Địa chỉ thực tế trên bộ nhớ RAM của hàm bạn muốn can thiệp.
* **`replace_call`**: Con trỏ trỏ đến hàm giả mạo do bạn tự viết.
* **`original_call`**: Nơi lưu lại con trỏ của hàm gốc (để bạn có thể gọi lại logic nguyên bản nếu cần).

### Bước 3: Vượt ASLR và thực hiện Hook (Code mẫu)
Trên iOS, Apple có cơ chế bảo mật **ASLR** (Address Space Layout Randomization). Mỗi lần bật app, hệ điều hành sẽ nạp app vào một địa chỉ ngẫu nhiên trên RAM. Do đó, địa chỉ tĩnh (offset) bạn nhìn thấy trong IDA Pro (ví dụ: `0x100A4B20`) **không phải** là địa chỉ thực tế lúc chạy.

Bạn phải cộng offset đó với địa chỉ trượt (Slide Address) của bộ nhớ.

```cpp
#include <dobby.h>
#include <mach-o/dyld.h> // Thư viện hệ thống để lấy Slide Address

// 1. Khai báo con trỏ hàm để lưu lại hàm gốc
// Giả sử hàm gốc trả về int (ví dụ: số lượng vàng) và nhận vào 1 tham số (instance)
int (*old_get_coins)(void *instance);

// 2. Viết hàm thay thế của bạn (phải có cùng cấu trúc tham số và kiểu trả về với hàm gốc)
int new_get_coins(void *instance) {
    // Bạn có thể gọi lại hàm gốc để lấy giá trị thật nếu muốn:
    // int real_coins = old_get_coins(instance);
    
    // Ở đây ta ép nó luôn trả về 999,999 vàng
    return 999999; 
}

// 3. Viết hàm khởi tạo để chạy DobbyHook ngay khi Tweak được nạp vào game
__attribute__((constructor))
void init_hook() {
    // Lấy Slide Address (độ dời ASLR) của file thực thi chính (index 0)
    intptr_t aslr_slide = _dyld_get_image_vmaddr_slide(0);

    // Offset của hàm get_coins bạn tìm được trong IDA Pro
    intptr_t offset = 0x100A4B20;

    // Tính địa chỉ thực tế trên RAM
    void *target_address = (void *)(aslr_slide + offset);

    // Thực hiện Hook
    DobbyHook(target_address, (void *)new_get_coins, (void **)&old_get_coins);
}
```

### Bước 4: Các trường hợp sử dụng nâng cao
* **Đọc/Ghi dữ liệu mà không thay đổi luồng:** Nếu bạn chỉ muốn "nghe lén" tham số truyền vào mà không muốn sửa logic, trong hàm `new_get_coins` của bạn, hãy in các tham số ra console (bằng `NSLog` hoặc `printf`), sau đó `return old_get_coins(instance);`.
* **Hook vào hàm hệ thống hoặc hàm có tên (Symbol):** Nếu ứng dụng không bị tước tên hàm (stripping), hoặc bạn muốn hook vào hàm của iOS (như `ptrace`), bạn không cần dùng `offset`. Bạn có thể tìm trực tiếp địa chỉ bằng hàm `DobbySymbolResolver`:
  ```cpp
  void *ptrace_addr = DobbySymbolResolver(NULL, "ptrace");
  DobbyHook(ptrace_addr, (void *)new_ptrace, (void **)&old_ptrace);
  ```
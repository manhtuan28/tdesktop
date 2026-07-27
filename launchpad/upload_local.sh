#!/bin/bash
#
# Ký và đẩy gói nguồn TuanGram lên Launchpad PPA.
#
#   ./launchpad/upload_local.sh                       # tự dò, hoặc hỏi đường dẫn
#   ./launchpad/upload_local.sh ~/Downloads/Launchpad-source
#   ./launchpad/upload_local.sh ~/Downloads/.../foo_source.changes
#   ./launchpad/upload_local.sh out/Release/Telegram   # build gói nguồn rồi đẩy
#   ./launchpad/upload_local.sh -y <đường dẫn>         # không hỏi xác nhận
#
# Nhận vào:
#   - thư mục chứa sẵn *_source.changes (artifact Launchpad-source tải từ CI)
#   - một file *_source.changes cụ thể
#   - file binary Telegram (hoặc thư mục chứa nó) -> tự build gói nguồn trước
#
set -euo pipefail

# Giữ đồng bộ với PPA_URL trong ppa_upload_ci.sh.
PPA_URL="ppa:tuancute28/tuangram"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSUME_YES=false
TARGET=""

for arg in "$@"; do
    case "$arg" in
        -y|--yes) ASSUME_YES=true ;;
        -h|--help)
            awk 'NR>1 { if (!/^#/) exit; sub(/^# ?/, ""); print }' "${BASH_SOURCE[0]}"
            exit 0 ;;
        *) TARGET="$arg" ;;
    esac
done

die() { echo "Lỗi: $*" >&2; exit 1; }

# ---------------------------------------------------------------- công cụ ---

MISSING=()
command -v dput    >/dev/null || MISSING+=("dput")
command -v debsign >/dev/null || MISSING+=("devscripts")
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Thiếu công cụ: ${MISSING[*]}"
    read -r -p "Cài bằng apt bây giờ? [Y/n] " reply
    case "${reply:-Y}" in
        [Nn]*) die "Cần: sudo apt install ${MISSING[*]}" ;;
        *) sudo apt-get update && sudo apt-get install -y "${MISSING[@]}" ;;
    esac
fi

# ------------------------------------------------------------------ GPG ----

GPG_KEY="$(gpg --list-secret-keys --with-colons 2>/dev/null \
    | awk -F: '/^sec:/ { print $5 }' | head -n 1)"
[ -n "$GPG_KEY" ] || die "Không tìm thấy GPG key bí mật nào trên máy."

GPG_UID="$(gpg --list-secret-keys --with-colons 2>/dev/null \
    | awk -F: '/^uid:/ { print $10; exit }')"
echo "GPG key : $GPG_KEY"
echo "Danh tính: $GPG_UID"

# ------------------------------------------------------- xác định đầu vào ---

if [ -z "$TARGET" ]; then
    # Không truyền gì: thử vài chỗ quen thuộc trước khi hỏi.
    for guess in \
        "$HOME/Downloads/Launchpad-source" \
        "$REPO_DIR/launchpad_build" \
        "$REPO_DIR/../out/Release/Telegram" \
        "$REPO_DIR/out/Release/Telegram"
    do
        if [ -e "$guess" ]; then TARGET="$guess"; break; fi
    done
    if [ -n "$TARGET" ]; then
        echo "Tự dò được: $TARGET"
    else
        read -r -p "Nhập đường dẫn (thư mục Launchpad-source, .changes, hoặc file Telegram): " TARGET
    fi
fi

TARGET="${TARGET/#\~/$HOME}"
[ -e "$TARGET" ] || die "Không tồn tại: $TARGET"

CHANGES_FILES=()

collect_changes() {
    local dir="$1"
    local found
    mapfile -t found < <(find "$dir" -maxdepth 1 -name '*_source.changes' | sort)
    CHANGES_FILES=("${found[@]}")
}

if [ -f "$TARGET" ] && [[ "$TARGET" == *_source.changes ]]; then
    CHANGES_FILES=("$TARGET")
elif [ -d "$TARGET" ]; then
    collect_changes "$TARGET"
    if [ ${#CHANGES_FILES[@]} -eq 0 ] && [ -f "$TARGET/Telegram" ]; then
        BINARY="$TARGET/Telegram"
    fi
elif [ -f "$TARGET" ]; then
    BINARY="$TARGET"
fi

# ------------------------------------------- build gói nguồn nếu cần thiết ---

if [ ${#CHANGES_FILES[@]} -eq 0 ]; then
    [ -n "${BINARY:-}" ] || die "Không thấy *_source.changes lẫn binary Telegram trong: $TARGET"
    [ -x "$BINARY" ] || [ -f "$BINARY" ] || die "Không đọc được binary: $BINARY"

    cd "$REPO_DIR"
    VERSION="$(awk '/^AppVersionStr /{print $2}' Telegram/build/version)"
    [ -n "$VERSION" ] || VERSION="0.0.0"

    echo
    echo "Chưa có gói nguồn. Đang build từ: $BINARY (version $VERSION)"
    rm -rf launchpad_build
    # Một số build chung cho mọi series của lần chạy này.
    export TUANGRAM_PPA_BUILD="$(date -u +%Y%m%d%H%M)"
    for series in noble jammy; do
        # Ký luôn ở bước này, nên không cần debsign lại phía dưới.
        ./launchpad/ppa_upload_ci.sh "$VERSION" "$BINARY" "$GPG_KEY" "$series"
    done
    collect_changes "$REPO_DIR/launchpad_build"
    [ ${#CHANGES_FILES[@]} -gt 0 ] || die "Build xong nhưng không thấy *_source.changes."
fi

# ------------------------------------------------------------------- ký ----

echo
for changes in "${CHANGES_FILES[@]}"; do
    if head -n 1 "$changes" | grep -q "BEGIN PGP SIGNED MESSAGE"; then
        echo "Đã ký sẵn : $(basename "$changes")"
    else
        echo "Đang ký   : $(basename "$changes")"
        # debsign ký cả .dsc lẫn .changes; Launchpad cần cả hai.
        debsign -k "$GPG_KEY" "$changes"
    fi
done

# -------------------------------------------------------------- xác nhận ---

echo
echo "Sẽ upload lên $PPA_URL:"
for changes in "${CHANGES_FILES[@]}"; do
    printf '  - %-46s (%s)\n' \
        "$(basename "$changes")" \
        "$(awk '/^Distribution:/{print $2}' "$changes")"
done

if [ "$ASSUME_YES" != true ]; then
    read -r -p "Tiếp tục? [Y/n] " reply
    case "${reply:-Y}" in [Nn]*) echo "Đã huỷ."; exit 0 ;; esac
fi

# ---------------------------------------------------------------- upload ---

# Không ghi ~/.dput.cf: dput đã có sẵn profile "ppa" trong /etc/dput.cf và tự
# suy ra đích từ cú pháp "ppa:user/name". Khối "[ppa_telegram]" mà các phiên bản
# script cũ ghi ra là thừa (trùng cấu hình mặc định) — xoá đi cũng được.
FAILED=()
for changes in "${CHANGES_FILES[@]}"; do
    echo
    echo ">>> dput $(basename "$changes")"
    # Lần upload đầu mang theo orig.tar.gz (~130 MB); các series sau dùng lại
    # đúng file đó nên Launchpad nhận diện trùng và bỏ qua.
    if ! dput "$PPA_URL" "$changes"; then
        FAILED+=("$(basename "$changes")")
    fi
done

echo
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "Upload lỗi: ${FAILED[*]}"
    echo "Kiểm tra: key $GPG_KEY đã import vào tài khoản Launchpad chưa?"
    exit 1
fi

echo "Upload hoàn tất."
echo "Theo dõi build: https://launchpad.net/~tuancute28/+archive/ubuntu/telegram/+packages"
echo "Launchpad sẽ gửi email nếu gói bị từ chối."

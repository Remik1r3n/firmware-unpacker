#!/bin/bash

# 自动找到 firmware.bin.extracted 下的唯一文件夹
FIRMWARE_DIR="./extractions/firmware.bin.extracted"
BASE_FOLDER=$(find "$FIRMWARE_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

if [ -z "$BASE_FOLDER" ]; then
    echo "错误：在 $FIRMWARE_DIR 中未找到文件夹"
    exit 1
fi

BASE_PATH="$BASE_FOLDER/ubifs-root/ubi_$(basename "$BASE_FOLDER").img"
EXTRACTED_DIR=$(find "$BASE_PATH" -type d -name "*rootfs.ubifs.extracted" | head -n 1)

if [ -z "$EXTRACTED_DIR" ]; then
    echo "错误：未找到以rootfs.ubifs.extracted结尾的目录"
    exit 1
fi

ROOT_DIR="$EXTRACTED_DIR/0/squashfs-root"
TARGET_DIR="$ROOT_DIR/usr/lib/lua"
OUTPUT_DIR="./lua"

if [ ! -d "$TARGET_DIR" ]; then
    echo "错误：目录 $TARGET_DIR 不存在"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

echo "正在处理目录：$TARGET_DIR"

# 遍历所有文件
find "$TARGET_DIR" -type f | while read -r file; do
    # 获取相对路径
    rel_path=${file#$TARGET_DIR/}
    # 获取目标目录
    target_dir="$OUTPUT_DIR/$(dirname "$rel_path")"
    # 创建目标目录
    mkdir -p "$target_dir"
    
    # 获取文件名和扩展名
    filename=$(basename "$file")
    extension="${filename##*.}"
    
    if [ "$extension" = "lua" ]; then
        # 处理 .lua 文件
        echo "反编译: $rel_path"
        output_file="$target_dir/$(basename "$rel_path")"
        if ! java -jar ./unluac_miwifi/build/unluac.jar "$file" > "$output_file" 2>/dev/null; then
            echo "警告: $rel_path 反编译失败，执行复制操作"
            cp "$file" "$target_dir/"
        fi
    else
        # 复制非 .lua 文件
        echo "复制: $rel_path"
        cp "$file" "$target_dir/"
    fi
done

echo "处理完成！文件已保存到 $OUTPUT_DIR 目录"

mv "$ROOT_DIR" "./root"
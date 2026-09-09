"""Monthly cleaning: preserve all behavior, deduplicate after normalization."""
import argparse
import pandas as pd
from pathlib import Path

# =========================
# 路径
# =========================

ROOT = Path(__file__).resolve().parents[1]

files = [
    '2019-Oct.csv',
    '2019-Nov.csv',
    '2019-Dec.csv',
    '2020-Jan.csv',
    '2020-Feb.csv'
]


# =========================
# 清洗函数
# =========================

def clean_file(filename, raw_dir, clean_dir):
    output_path = clean_dir / filename.replace(".csv", "-cleaned.csv")
    if output_path.exists():
        raise FileExistsError(f"Refusing to overwrite {output_path}")

    input_path = raw_dir / filename

    print('\n==============================')
    print('正在处理：', filename)
    print('==============================')

    # 1. 读取
    df = pd.read_csv(
        input_path,
        dtype={
            'category_id': 'string',
            'category_code': 'string',
            'brand': 'string',
            'user_session': 'string'
        }
    )

    original_rows = len(df)

    print('原始数据量：', original_rows)

    # 2. event_type
    df['event_type'] = (
        df['event_type']
        .str.strip()
        .str.lower()
    )

    # 3. 时间
    df['event_time'] = pd.to_datetime(
        df['event_time'],
        utc=True,
        errors='coerce'
    )

    df['event_time'] = (
        df['event_time']
        .dt.tz_localize(None)
    )

    # 4. price
    df['price'] = pd.to_numeric(
        df['price'],
        errors='coerce'
    )

    # 5. 完全重复记录
    duplicate_count = df.duplicated().sum()

    print('完全重复记录：', duplicate_count)

    df = df.drop_duplicates().copy()

    # 6. 缺失字段
    df['brand'] = (
        df['brand']
        .fillna('Unknown')
    )

    df['category_code'] = (
        df['category_code']
        .fillna('Unknown')
    )

    # 7. 派生时间字段
    df['event_date'] = (
        df['event_time']
        .dt.date
    )

    df['event_month'] = (
        df['event_time']
        .dt.to_period('M')
        .astype(str)
    )

    df['event_hour'] = (
        df['event_time']
        .dt.hour
    )

    df['event_weekday'] = (
        df['event_time']
        .dt.dayofweek
    )

    df['is_weekend'] = (
        df['event_weekday'] >= 5
    )

    # 8. 数据质量检查
    negative_price = (df['price'] < 0).sum()
    zero_price = (df['price'] == 0).sum()

    print('清洗后数据量：', len(df))

    print(
        '去重比例：',
        round(
            duplicate_count / original_rows * 100,
            2
        ),
        '%'
    )

    print(
        '用户数量：',
        df['user_id'].nunique()
    )

    print(
        '商品数量：',
        df['product_id'].nunique()
    )

    print(
        'Session缺失：',
        df['user_session'].isna().sum()
    )

    print(
        '负价格：',
        negative_price
    )

    print(
        '0价格：',
        zero_price
    )

    print(
        '时间范围：',
        df['event_time'].min(),
        '~',
        df['event_time'].max()
    )

    print('\n事件类型：')

    print(
        df['event_type']
        .value_counts()
    )

    # 9. 保存
    output_name = filename.replace(
        '.csv',
        '-cleaned.csv'
    )

    output_path = clean_dir / output_name

    df.to_csv(
        output_path,
        mode='x',
        lineterminator='\r\n',
        index=False
    )

    print('\n保存完成：')
    print(output_path)

    # 返回汇总信息
    return {
        'month': filename.replace('.csv', ''),
        'original_rows': original_rows,
        'duplicate_rows': duplicate_count,
        'clean_rows': len(df),
        'users': df['user_id'].nunique(),
        'products': df['product_id'].nunique(),
        'negative_price': negative_price,
        'zero_price': zero_price,
        'missing_session':
            df['user_session'].isna().sum()
    }


# =========================
# 批量执行
# =========================

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--raw-dir', type=Path, default=ROOT / 'data/raw')
    parser.add_argument('--output-dir', type=Path, default=ROOT / 'data/cleaned')
    args = parser.parse_args()
    raw_dir, clean_dir = args.raw_dir, args.output_dir
    # Validate all targets before writing; never overwrite existing data.
    for filename in files:
        if not (raw_dir / filename).is_file():
            parser.error(f'Missing input: {raw_dir / filename}')
    targets = [clean_dir / name.replace('.csv', '-cleaned.csv') for name in files]
    targets.append(clean_dir / 'cleaning_summary.csv')
    for target in targets:
        if target.exists():
            parser.error(f'Refusing to overwrite {target}; choose a new --output-dir')
    clean_dir.mkdir(parents=True, exist_ok=True)
    summary = [clean_file(name, raw_dir, clean_dir) for name in files]
    pd.DataFrame(summary).to_csv(targets[-1], index=False, mode='x', lineterminator='\r\n')


if __name__ == '__main__':
    main()

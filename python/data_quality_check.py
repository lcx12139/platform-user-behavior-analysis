"""Read-only quality checks; behavior rows are never filtered or rewritten."""
import argparse
import json
from collections import Counter
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
STRING_DTYPES = {name: "string" for name in (
    "category_id", "category_code", "brand", "user_session"
)}


def check_file(path: Path, chunksize: int = 250_000) -> dict:
    """Bound memory while retaining the original February zero-price breakdowns."""
    totals = Counter()
    breakdowns = {key: Counter() for key in (
        "event_type", "brand", "product_id", "event_date"
    )}
    for frame in pd.read_csv(path, dtype=STRING_DTYPES, chunksize=chunksize):
        price = pd.to_numeric(frame["price"], errors="coerce")
        totals.update({
            "rows": len(frame),
            "negative_price": int(price.lt(0).sum()),
            "zero_price": int(price.eq(0).sum()),
            "missing_or_invalid_price": int(price.isna().sum()),
            "missing_session": int(frame["user_session"].isna().sum()),
            "missing_or_invalid_time": int(pd.to_datetime(
                frame["event_time"], utc=True, errors="coerce").isna().sum()),
            "nonpositive_purchase": int((frame["event_type"].eq("purchase")
                                         & price.le(0)).sum()),
        })
        zero = frame.loc[price.eq(0)]
        for key, counter in breakdowns.items():
            counter.update({str(k): int(v) for k, v in
                            zero[key].value_counts().items()})
    return {"file": path.name, **totals,
            "zero_price_breakdowns": {
                key: dict(counter.most_common(None if key == "event_type" else 20))
                for key, counter in breakdowns.items()}}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="*", type=Path)
    parser.add_argument("--chunksize", type=int, default=250_000)
    args = parser.parse_args()
    if args.chunksize < 1:
        parser.error("--chunksize must be positive")
    files = args.files or sorted((ROOT / "data/cleaned").glob("*-cleaned.csv"))
    if not files:
        parser.error("No cleaned CSV files found")
    for path in files:
        print(json.dumps(check_file(path, args.chunksize), ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()

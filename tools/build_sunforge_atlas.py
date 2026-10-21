"""Measure cutout bounds and ground anchors without changing the source art.

The illustrated sheets use uneven cell spacing. Detect their disconnected
silhouettes instead of slicing through hands, pincers or the drill tip.
Requires Pillow, NumPy and SciPy; runtime uses only the generated JSON.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from scipy.ndimage import label, find_objects

FOLDER = Path(__file__).resolve().parents[1] / 'assets/sunforge'
result = {}
for name, rows in [('sunstone_folk', 2), ('items', 2), ('scorpion', 3)]:
    alpha = np.asarray(Image.open(FOLDER / (name + '.png')).convert('RGBA'))[:, :, 3]
    labels, _ = label(alpha > 150)
    silhouettes = []
    for index, bounds in enumerate(find_objects(labels), 1):
        if bounds is None or np.count_nonzero(labels[bounds] == index) < 1000:
            continue
        y, x = bounds
        silhouettes.append((x.start, y.start, x.stop, y.stop))
    assert len(silhouettes) == rows * 4, (name, len(silhouettes))
    silhouettes.sort(key=lambda box: (box[1] + box[3]) / 2)
    sheet = []
    for row in range(rows):
        entries = []
        for left, top, right, bottom in sorted(silhouettes[row*4:row*4+4]):
            left, top = max(0, left-2), max(0, top-2)
            right, bottom = min(alpha.shape[1], right+2), min(alpha.shape[0], bottom+2)
            strip = alpha[bottom-max(1, int((bottom-top)*.12)):bottom, left:right]
            _, feet = np.nonzero(strip > 150)
            entries.append({'region': [left, top, right-left, bottom-top],
                            'anchor': [float((feet.min()+feet.max())/2), bottom-top]})
        sheet.append(entries)
    result[name] = sheet
(FOLDER / 'atlas.json').write_text(json.dumps(result, indent=2) + '\n')
print('Analyzed 28 cutout poses/items')

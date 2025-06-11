find lib \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i 's/import mmcv/import mmcv_depr as mmcv/g'

find lib \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i 's/from mmcv/from mmcv_depr/g'

find lib \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i 's/import mmdet/import mmdet_depr as mmdet/g'

find lib \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i 's/from mmdet/from mmdet_depr/g'

rename 's/mmcv/mmcv_depr/' *
rename 's/mmdet/mmdet_depr/' *



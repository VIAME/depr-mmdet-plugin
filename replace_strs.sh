find lib \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s/import mmcv/import mmcv_depr as mmcv/g"

find lib \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s/from mmcv/from mmcv_depr/g"

find lib \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s/import mmdet/import mmdet_depr as mmdet/g"

find lib \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s/from mmdet/from mmdet_depr/g"

find lib \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s/mmcv_maximum_version = '1.3'/mmcv_maximum_version = '1.3.19'/g"

find lib \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s/mmcv./mmcv_depr./g"

rename 's/mmcv/mmcv_depr/' lib/python3.10/site-packages/*
rename 's/mmdet/mmdet_depr/' lib/python3.10/site-packages/*



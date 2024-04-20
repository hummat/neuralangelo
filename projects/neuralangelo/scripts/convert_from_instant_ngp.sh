# -----------------------------------------------------------------------------
# Copyright (c) 2023, NVIDIA CORPORATION. All rights reserved.
#
# NVIDIA CORPORATION and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto. Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from NVIDIA CORPORATION is strictly prohibited.
# -----------------------------------------------------------------------------

# usage: run_colmap.sh <project_path>

cp -r ${1}/colmap_sparse ${1}/sparse
mv ${1}/images ${1}/images_raw

cp ${1}/sparse/0/*.bin ${1}/sparse/
for path in ${1}/sparse/*/; do
    m=$(basename ${path})
    if [ ${m} != "0" ]; then
        colmap model_merger \
            --input_path1=${1}/sparse \
            --input_path2=${1}/sparse/${m} \
            --output_path=${1}/sparse
        colmap bundle_adjuster \
            --input_path=${1}/sparse \
            --output_path=${1}/sparse
    fi
done

colmap image_undistorter \
    --image_path=${1}/images_raw \
    --input_path=${1}/sparse \
    --output_path=${1} \
    --output_type=COLMAP

python projects/neuralangelo/scripts/convert_data_to_json.py --data_dir ${1} --scene_type object
python projects/neuralangelo/scripts/generate_config.py --sequence_name $(basename ${1}) --data_dir ${1} --scene_type object

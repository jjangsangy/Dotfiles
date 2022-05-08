#!/usr/bin/env python3

import zipfile
import collections
import argparse
import pathlib
import operator
import functools
import warnings
import json

import numpy as np

from typing import List, Tuple, Union, Sequence
from PIL import ImageFile
from sklearn.cluster import KMeans
from sklearn.exceptions import ConvergenceWarning

warnings.filterwarnings("ignore", category=ConvergenceWarning)


Res = Tuple[int, int]
ResProb = Tuple[Res, float]
ZipInput = Union[zipfile.ZipInfo, str]


def compute_count(sizes: Sequence[Res]) -> ResProb:
    common = collections.Counter(sizes).most_common(1)[0]
    res = common[0]
    prob = common[1] / len(sizes)
    return res, prob


def compute_average(sizes: Sequence[Res]) -> ResProb:
    arr = np.array(sizes)
    res = int(np.mean(arr[:,0])), int(np.mean(arr[:,1]))
    return res, 1.0


def compute_min_max(sizes: Sequence[Res], operation=max) -> ResProb:
    count = collections.Counter(sizes)
    common = operation(
        [(np.prod(i[0]), i) for i in count.items()],
        key=operator.itemgetter(0)
    )[1]
    res = common[0]
    prob = common[1] / len(sizes)
    return res, prob


def compute_kmeans(sizes: List[Res], n_clust: int = 3) -> ResProb:
    clust = KMeans(n_clusters=n_clust).fit(sizes)

    count_ind = collections.Counter(clust.labels_)
    common = count_ind.most_common(1)[0][0]

    res = tuple(clust.cluster_centers_[common].astype(int))
    prob = count_ind[common] / len(sizes)
    return res, prob


def img_sizes_from_header(zf: zipfile.ZipFile, filelist: Sequence[ZipInput]) -> List[Res]:
    chunk_size = 2048
    res = []
    for file in filelist:
        with zf.open(file, mode='r') as zext:
            parser = ImageFile.Parser()
            chunk = zext.read(chunk_size)
            count = 2048
            while chunk != "":
                parser.feed(chunk)
                if parser.image:
                    break
                chunk = zext.read(chunk_size)
                count += chunk_size
            res.append(parser.image.size) #type: ignore
    return res


def get_image_sizes(zip_file: pathlib.Path, samples: int = 20) -> dict:
    assert zip_file.exists(), f"file {zip_file} does not exist"
    with zipfile.ZipFile(zip_file) as zf:
        namelist = [
            i for i in zf.namelist()
            if any(map(i.endswith, [".jpg", ".jpeg", ".png", ".tiff", ".webp", ".bmp"]))
        ]

        if samples <= 0:
            total_samples = len(namelist)
            choices = namelist
        else:
            total_samples = len(namelist) if samples > len(namelist) else samples
            choices = list(np.random.choice(namelist, size=total_samples, replace=False))

        return {
            'sizes': img_sizes_from_header(zf, choices),
            'n': len(namelist)
        }


def cli(metrics: dict) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Get the resolution of images inside cbz files"
    )
    parser.add_argument(
        "-s",
        "--samples",
        default=10,
        type=int,
        help="number of images to sample"
    )
    parser.add_argument(
        "-m",
        "--metric",
        default="count",
        choices=list(metrics),
        type=str,
        help="aggregation metric to use",
    )
    parser.add_argument(
        "-c",
        "--n-clust",
        default=3,
        type=int,
        help="number of clusters when using kmeans",
    )
    parser.add_argument(
        "-j",
        "--json",
        action='store_true',
        help="output in json format"
    )
    parser.add_argument(
        "files",
        nargs="+",
        type=pathlib.Path,
        help="cbz files"
    )
    return parser.parse_args()


def main():
    metrics = {
        'count': compute_count,
        'average': compute_average,
        'min': functools.partial(compute_min_max, operation=min),
        'max': functools.partial(compute_min_max, operation=max),
        'kmeans': compute_kmeans
    }
    args = cli(metrics)
    metrics['kmeans'] = functools.partial(compute_kmeans, n_clust=args.n_clust)
    metric_func = metrics[args.metric]

    for file in args.files:
        img_sizes = get_image_sizes(file, samples=args.samples)
        samples = len(img_sizes['sizes'])
        res, prob = metric_func(img_sizes['sizes'])

        if args.json:
            print(json.dumps(
                {
                    'file': str(file),
                    'metric': args.metric,
                    'resolution': f"{res[0]}x{res[1]}",
                    'n': samples,
                    'prob': f'{prob:.2%}',
                }, indent=4
            ))
        else:
            print(f'File: {file}')
            print(f"Metric:{args.metric}, Resolution:{res[0]}x{res[1]}, n:{samples}, p:{prob:.2%}\n")


if __name__ == '__main__':
    main()


